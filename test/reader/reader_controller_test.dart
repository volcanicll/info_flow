import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:info_flow/features/reader/presentation/controllers/reader_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderController', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态与默认排版参数', () {
      final state = container.read(readerControllerProvider);
      expect(state.isNativeMode, isTrue);
      expect(state.fontSize, 16.0);
      expect(state.lineHeight, 1.75);
      expect(state.progress, 0.0);
      expect(state.paperIndex, 0);
    });

    test('setNativeMode 模式切换', () {
      final notifier = container.read(readerControllerProvider.notifier);
      notifier.setNativeMode(false);
      expect(container.read(readerControllerProvider).isNativeMode, isFalse);

      notifier.setNativeMode(true);
      expect(container.read(readerControllerProvider).isNativeMode, isTrue);
    });

    test('setFontSize 字号设置与 12~24 范围截断', () {
      final notifier = container.read(readerControllerProvider.notifier);

      notifier.setFontSize(20.0);
      expect(container.read(readerControllerProvider).fontSize, 20.0);

      // 低于 12 截断到 12
      notifier.setFontSize(8.0);
      expect(container.read(readerControllerProvider).fontSize, 12.0);

      // 高于 24 截断到 24
      notifier.setFontSize(30.0);
      expect(container.read(readerControllerProvider).fontSize, 24.0);
    });

    test('setLineHeight 行高设置与 1.3~2.2 范围截断', () {
      final notifier = container.read(readerControllerProvider.notifier);

      notifier.setLineHeight(1.9);
      expect(container.read(readerControllerProvider).lineHeight, 1.9);

      notifier.setLineHeight(1.0);
      expect(container.read(readerControllerProvider).lineHeight, 1.3);

      notifier.setLineHeight(3.0);
      expect(container.read(readerControllerProvider).lineHeight, 2.2);
    });

    test('setProgress 阅读进度更新与防微小抖动', () {
      final notifier = container.read(readerControllerProvider.notifier);

      notifier.setProgress(0.5);
      expect(container.read(readerControllerProvider).progress, 0.5);

      // 微小变化（< 0.005）不触发更新
      notifier.setProgress(0.502);
      expect(container.read(readerControllerProvider).progress, 0.5);

      notifier.setProgress(0.8);
      expect(container.read(readerControllerProvider).progress, 0.8);
    });

    test('setPaperIndex 纸底配色切换', () {
      final notifier = container.read(readerControllerProvider.notifier);

      notifier.setPaperIndex(2);
      expect(container.read(readerControllerProvider).paperIndex, 2);
    });
  });
}
