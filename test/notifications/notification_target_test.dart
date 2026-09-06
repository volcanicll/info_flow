import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/notifications/notification_service.dart';

void main() {
  group('notificationExternalUrl', () {
    test('http/https 链接返回解析后的 Uri', () {
      expect(
        notificationExternalUrl('https://example.com/a?b=1'),
        Uri.parse('https://example.com/a?b=1'),
      );
      expect(
        notificationExternalUrl('http://example.com/post'),
        Uri.parse('http://example.com/post'),
      );
    });

    test('scheme 大小写不敏感', () {
      expect(
        notificationExternalUrl('HTTPS://EXAMPLE.COM/POST'),
        Uri.parse('HTTPS://EXAMPLE.COM/POST'),
      );
    });

    test('应用内路由与非网页内容返回 null', () {
      expect(notificationExternalUrl('/smart-money'), isNull);
      expect(notificationExternalUrl('crypto-radar'), isNull);
      expect(notificationExternalUrl('example.com/no-scheme'), isNull);
      expect(notificationExternalUrl(''), isNull);
      expect(notificationExternalUrl('   '), isNull);
    });
  });

  group('notificationRoute', () {
    test('合法路由原样返回', () {
      expect(notificationRoute('/smart-money'), '/smart-money');
      expect(notificationRoute('/reader/abc-123'), '/reader/abc-123');
    });

    test('缺前导斜杠的历史 payload 补齐', () {
      expect(notificationRoute('crypto-radar'), '/crypto-radar');
    });

    test('空白 payload 返回 null', () {
      expect(notificationRoute(''), isNull);
      expect(notificationRoute('   '), isNull);
    });
  });
}
