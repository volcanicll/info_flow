import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:info_flow/core/notifications/alert_inbox.dart';

void main() {
  AlertInboxEntry entry({
    String id = 'e1',
    String kind = 'signal',
    String title = '聪明钱异动 1 笔',
    String body = 'whale 买入 BTC \$1.2k',
    String? payload = '/smart-money',
    DateTime? createdAt,
    bool read = false,
  }) =>
      AlertInboxEntry(
        id: id,
        kind: kind,
        title: title,
        body: body,
        payload: payload,
        createdAt: createdAt ?? DateTime(2026, 1, 1, 12),
        read: read,
      );

  group('mergeAlertInbox', () {
    test('空收件箱直接入箱', () {
      final merged = mergeAlertInbox(const [], entry());
      expect(merged, hasLength(1));
      expect(merged.first.title, '聪明钱异动 1 笔');
    });

    test('新条目置顶', () {
      final old = entry(id: 'old', title: '旧告警', body: 'old');
      final merged = mergeAlertInbox([old], entry());
      expect(merged.first.id, 'e1');
      expect(merged.last.id, 'old');
    });

    test('与最新一条同题同文的重复告警不入箱', () {
      final existing = [entry()];
      final merged = mergeAlertInbox(existing, entry(id: 'e2'));
      expect(merged, same(existing));
      expect(merged, hasLength(1));
    });

    test('同题不同文正常入箱', () {
      final existing = [entry()];
      final merged = mergeAlertInbox(
        existing,
        entry(body: 'whale 卖出 ETH \$3k'),
      );
      expect(merged, hasLength(2));
    });

    test('超出容量裁掉最旧条目', () {
      final existing = List.generate(50, (i) => entry(id: 'e$i'));
      final merged = mergeAlertInbox(
        existing,
        entry(id: 'new', body: 'whale 首买 SOL \$5k'),
        cap: 50,
      );
      expect(merged, hasLength(50));
      expect(merged.first.id, 'new', reason: '新条目置顶');
      expect(merged.any((e) => e.id == 'e49'), isFalse,
          reason: '末尾最旧的 e49 应被裁掉');
      expect(merged.last.id, 'e48');
    });
  });

  group('AlertInboxEntry 序列化', () {
    test('toJson/fromJson 往返一致', () {
      final original = entry(read: true, payload: null);
      final decoded = AlertInboxEntry.tryFromJson(original.toJson());
      expect(decoded, isNotNull);
      expect(decoded!.id, original.id);
      expect(decoded.kind, original.kind);
      expect(decoded.title, original.title);
      expect(decoded.body, original.body);
      expect(decoded.payload, isNull);
      expect(decoded.createdAt, original.createdAt);
      expect(decoded.read, isTrue);
    });

    test('tryFromJson 对坏数据返回 null 而不抛异常', () {
      expect(AlertInboxEntry.tryFromJson(null), isNull);
      expect(AlertInboxEntry.tryFromJson('garbage'), isNull);
      expect(AlertInboxEntry.tryFromJson({'no_title': 1}), isNull);
      expect(AlertInboxEntry.tryFromJson(jsonDecode('{"body": 1}')), isNull);
    });

    test('kind 缺失兜底为 signal，read 缺失兜底为未读', () {
      final decoded = AlertInboxEntry.tryFromJson({
        'title': 't',
        'body': 'b',
        'createdAt': 1700000000000,
      });
      expect(decoded, isNotNull);
      expect(decoded!.kind, 'signal');
      expect(decoded.read, isFalse);
    });
  });
}
