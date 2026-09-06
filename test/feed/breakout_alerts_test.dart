import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/notifications/notification_service.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:info_flow/features/feed/data/breakout_alerts.dart';
import 'package:info_flow/features/feed/data/newsnow_repository.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:shared_preferences/shared_preferences.dart';

Article _hit(String platform, String title) {
  return Article(
    id: 'newsnow-test-$title',
    feedId: 'newsnow-test',
    feedName: platform,
    title: title,
    url: 'https://example.com/$title',
    content: title,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('breakoutFingerprints', () {
    test('指纹 = bo|平台|标题，与热榜条目一一对应', () {
      final prints = breakoutFingerprints([
        BreakoutHit(
          article: _hit('微博', '比特币突破历史新高'),
          keyword: 'BTC',
          platform: '微博',
        ),
        BreakoutHit(
          article: _hit('知乎', '如何看待稳定币立法'),
          keyword: '稳定币',
          platform: '知乎',
        ),
      ]);
      expect(prints, ['bo|微博|比特币突破历史新高', 'bo|知乎|如何看待稳定币立法']);
    });
  });

  group('SignalNotifyPref.markSeen（破圈指纹共用）', () {
    test('首轮全部为新增，重复扫描无新增', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);
      final pref = container.read(signalNotifyPrefProvider.notifier);

      const prints = ['bo|微博|标题A', 'bo|知乎|标题B'];
      expect(pref.markSeen(prints), prints);
      expect(pref.markSeen(prints), isEmpty);
    });

    test('已见指纹上限 300 条，保留最新', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);
      final pref = container.read(signalNotifyPrefProvider.notifier);

      final first =
          List.generate(300, (i) => 'bo|微博|标题$i'.replaceFirst('标题', '早期标题$i'));
      pref.markSeen(first);

      // 再灌 50 条新指纹：总 350，超限后只保留最新 300 条
      final second = List.generate(50, (i) => 'bo|知乎|新标题$i');
      pref.markSeen(second);

      final seen = prefs.getStringList('signal_notify_seen')!;
      expect(seen.length, 300);
      expect(seen.contains('bo|微博|早期标题0'), isFalse, reason: '最旧的被挤出');
      expect(seen.contains('bo|知乎|新标题49'), isTrue, reason: '最新的一定保留');

      // 重复推送旧指纹不再打扰；被挤出的旧指纹重新出现视为「新」
      expect(pref.markSeen(['bo|知乎|新标题49']), isEmpty);
      expect(pref.markSeen(['bo|微博|早期标题0']), ['bo|微博|早期标题0']);
    });
  });
}
