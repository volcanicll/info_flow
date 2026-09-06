import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/data/newsnow_repository.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

void main() {
  final repo = NewsNowRepository(Dio());

  group('NewsNowRepository.parsePayload', () {
    test('cls 风格：pubDate 毫秒 + 原始控制字符清洗', () {
      const body = '{"status":"cache","id":"cls","items":['
          '{"id":2475067,"title":"财联社今日焦点","mobileUrl":"https://m.cls.cn/1",'
          '"pubDate":1788661107000,"url":"https://www.cls.cn/detail/2475067"},'
          '{"id":2475064,"title":"第二大行\n宣布上调油价比重36%","pubDate":1788660617000,"url":"https://www.cls.cn/detail/2475064"}'
          ']}';
      final items = repo.parsePayload('cls', '财联社快讯', 0xFFB03A2E, body);
      expect(items, hasLength(2));
      expect(items[0].title, '财联社今日焦点');
      expect(items[0].feedId, 'newsnow-cls');
      expect(items[0].feedName, '财联社快讯');
      expect(items[0].publishedAt, isNotNull);
      expect(items[1].publishedAt, isNotNull, reason: '原始换行被清洗后日期解析不受影响');
    });

    test('wallstreetcn 风格：日期在 extra.date', () {
      const body = '{"status":"cache","id":"wallstreetcn","items":['
          '{"id":3160913,"title":"测试快讯标题","extra":{"date":1788655684000},'
          '"url":"https://wallstreetcn.com/livenews/3160913"}]}';
      final items = repo.parsePayload(
          'wallstreetcn', '华尔街见闻', 0xFF57534E, body);
      expect(items, hasLength(1));
      expect(items[0].publishedAt, isNotNull);
      expect(items[0].url, 'https://wallstreetcn.com/livenews/3160913');
    });

    test('weibo 风格：无日期字段时 publishedAt 为 null，不抛异常', () {
      const body = '{"status":"cache","id":"weibo","items":['
          '{"id":"话题一","title":"某热搜话题","url":"https://s.weibo.com/weibo?q=1"}]}';
      final items = repo.parsePayload('weibo', '微博', 0xFF57534E, body);
      expect(items, hasLength(1));
      expect(items[0].publishedAt, isNull);
      expect(items[0].url, 'https://s.weibo.com/weibo?q=1');
    });

    test('畸形 body 静默返回空列表', () {
      expect(repo.parsePayload('cls', '财联社快讯', 0, 'not json'), isEmpty);
      expect(repo.parsePayload('cls', '财联社快讯', 0, '{"items":"wrong"}'), isEmpty);
    });
  });

  group('matchBreakoutKeyword', () {
    test('行业通用词命中', () {
      expect(matchBreakoutKeyword('稳定币立法草案公布'), '稳定币');
      expect(matchBreakoutKeyword(' Web3 人才报告发布'), 'web3');
    });

    test('主流币中文别名与拉丁词命中', () {
      expect(matchBreakoutKeyword('比特币突破历史新高'), 'BTC');
      expect(matchBreakoutKeyword('Robinhood 宣布上币'), 'HOOD');
      expect(matchBreakoutKeyword('SOL 生态周报'), 'SOL');
    });

    test('拉丁短别名不误伤包含它的英文单词', () {
      expect(matchBreakoutKeyword('solar panels reach new record'), isNull);
      expect(matchBreakoutKeyword('assume nothing about rwa'), isNull);
    });

    test('无关标题返回 null', () {
      expect(matchBreakoutKeyword('某地出台老旧住房更新政策'), isNull);
    });
  });

  test('AssetClass.crypto 过滤：金属/宏观不参与破圈匹配', () {
    // 词典中 XAU/DXY 等非 crypto 条目不应命中（如标题含 gold/xau）
    expect(matchBreakoutKeyword('gold price rally continues'), isNull);
  });
}
