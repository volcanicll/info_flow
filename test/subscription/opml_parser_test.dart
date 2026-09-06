import 'package:flutter_test/flutter_test.dart';

import 'package:info_flow/features/subscription/data/opml_parser.dart';

void main() {
  group('OpmlParser', () {
    test('解析标准 OPML：outline 带 xmlUrl', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head><title>Subscriptions</title></head>
  <body>
    <outline text="科技" title="科技">
      <outline type="rss" text="36氪" title="36氪" xmlUrl="https://36kr.com/feed" htmlUrl="https://36kr.com"/>
      <outline type="rss" text="虎嗅" title="虎嗅" xmlUrl="https://rsshub.app/huxiu/article"/>
    </outline>
    <outline type="atom" text="Hacker News" title="Hacker News" xmlUrl="https://hnrss.org/frontpage" htmlUrl="https://news.ycombinator.com"/>
  </body>
</opml>
''';
      final items = OpmlParser.parse(xml);
      expect(items.length, 3);
      expect(items[0].name, '36氪');
      expect(items[0].feedUrl, 'https://36kr.com/feed');
      expect(items[0].siteUrl, 'https://36kr.com');
      expect(items[1].feedUrl, 'https://rsshub.app/huxiu/article');
      expect(items[2].name, 'Hacker News');
    });

    test('缺少 xmlUrl 的 outline 被跳过', () {
      const xml = '''
<opml version="2.0">
  <body>
    <outline text="分组">
      <outline text="无订阅地址"/>
    </outline>
  </body>
</opml>
''';
      expect(OpmlParser.parse(xml), isEmpty);
    });

    test('title 缺失时回退到 text', () {
      const xml = '''
<opml version="2.0">
  <body>
    <outline type="rss" text="少数派" xmlUrl="https://sspai.com/feed"/>
  </body>
</opml>
''';
      final items = OpmlParser.parse(xml);
      expect(items.single.name, '少数派');
    });
  });

  group('OpmlBuilder', () {
    test('生成合法 OPML 且可被解析器读回', () {
      final xml = OpmlBuilder.build(
        title: 'InfoFlow 订阅',
        subscriptions: const [
          OpmlSubscription(
            name: '36氪',
            feedUrl: 'https://36kr.com/feed',
            siteUrl: 'https://36kr.com',
          ),
          OpmlSubscription(
            name: '虎嗅',
            feedUrl: 'https://rsshub.app/huxiu/article',
          ),
        ],
      );
      expect(xml, contains('<opml version="2.0">'));
      expect(xml, contains('https://36kr.com/feed'));

      final items = OpmlParser.parse(xml);
      expect(items.length, 2);
      expect(items[0].name, '36氪');
      expect(items[0].feedUrl, 'https://36kr.com/feed');
      expect(items[0].siteUrl, 'https://36kr.com');
    });

    test('XML 特殊字符被转义', () {
      final xml = OpmlBuilder.build(
        title: 'A & B <测试>',
        subscriptions: const [
          OpmlSubscription(
            name: 'R&D <Blog>',
            feedUrl: 'https://example.com/feed?x=1&y=2',
          ),
        ],
      );
      expect(xml.contains('R&amp;D &lt;Blog&gt;'), isTrue);
      expect(xml.contains('feed?x=1&amp;y=2'), isTrue);
    });
  });
}
