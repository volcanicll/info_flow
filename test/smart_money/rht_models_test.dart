import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/smart_money/data/models/rht_models.dart';
import 'package:info_flow/features/smart_money/data/models/rht_position.dart';
import 'package:info_flow/features/smart_money/data/models/rht_token.dart';
import 'package:info_flow/features/smart_money/data/models/rht_trader.dart';

void main() {
  group('RhtStatus.fromJson', () {
    test('解析真实 /api/status 响应样例', () {
      final s = RhtStatus.fromJson({
        'ok': true,
        'chain': 'robinhood',
        'chain_id': 4663,
        'wallets': 108,
        'uptime': 43185,
        'source': 'websocket',
        'lag_seconds': 0.1,
        'last_block': 54933675,
        'trades': 31308,
        'latency': {'n': 200, 'median': 1.2, 'p90': 1.6},
        'viewers': 936,
        'last_ts': 1788592420,
        'server_ts': 1788592427,
      });
      expect(s.wallets, 108);
      expect(s.chainId, 4663);
      expect(s.trades, 31308);
      expect(s.latencyMedian, 1.2);
      expect(s.viewers, 936);
    });
  });

  group('RhtFill.fromJson', () {
    test('解析 sell 成交（首条为实测 /api/tape 样本）', () {
      final f = RhtFill.fromJson({
        'id': 38739,
        'ts': 1788592420,
        'tx': '0x888e14',
        'side': 'sell',
        'usd': 2236.124396,
        'amount': 13725756.69,
        'price': 0.00016291447136971293,
        'new_position': 0,
        'is_stock': 0,
        'block': 54933642,
        'priced': 'cash_leg',
        'handle': '31337___',
        'display_name': '31337',
        'followers': 38559,
        'wallet': '0xc9ca',
        'token': '0x07a4',
        'symbol': 'AGI',
        'name': 'Artificial Gooner Intelligence',
        'mark': null,
        'liquidity': null,
        'pair_url': null,
        'flags': [],
      });
      expect(f.isBuy, isFalse);
      expect(f.usd, 2236.124396);
      expect(f.handle, '31337___');
      expect(f.isNewPosition, isFalse);
      expect(f.pairUrl, isNull);
    });

    test('new_position=1 标记首买，buy 判定正确', () {
      final f = RhtFill.fromJson({
        'id': 38735,
        'ts': 1788592161,
        'side': 'buy',
        'usd': 497.58,
        'amount': 17813.1,
        'price': 0.027933,
        'new_position': 1,
        'handle': '0xnobi',
        'display_name': 'nobi',
        'followers': 38058,
        'wallet': '0x8afc',
        'token': '0xd5f1',
        'symbol': 'microduck',
      });
      expect(f.isNewPosition, isTrue);
      expect(f.isBuy, isTrue);
      expect(f.price, 0.027933);
    });

    test('缺失字段不抛异常', () {
      final f = RhtFill.fromJson({'id': 1, 'side': 'buy'});
      expect(f.symbol, '???');
      expect(f.usd, 0);
      expect(f.flags, isEmpty);
    });
  });

  group('RhtOverview.fromJson', () {
    test('解析真实 /api/overview 样例，最大赢家/买单分字段取值', () {
      final o = RhtOverview.fromJson({
        'biggest_win': {
          'pnl_usd': 81999.007,
          'handle': 'traderpow',
          'symbol': 'TENDIES',
          'pct': 25.84,
        },
        'biggest_buy': {
          'usd': 49930.249,
          'handle': 'change',
          'symbol': 'CASHCAT',
        },
        'window': '24h',
        'fills': 3012,
        'buys': 1958,
        'sells': 1054,
        'active_traders': 76,
        'volume': 13692661.9,
        'realized_pnl': -455921.47,
        'net_pnl': 7457445.3,
        'win_rate': 0.399,
        'closed_trades': 406,
        'last_5m': {'buys': 2, 'sells': 1, 'volume': 4125.4},
      });
      expect(o.fills, 3012);
      expect(o.biggestWin!.usd, 81999.007);
      expect(o.biggestWin!.symbol, 'TENDIES');
      expect(o.biggestBuy!.usd, 49930.249);
      expect(o.netPnl, closeTo(7457445.3, 0.1));
      expect(o.winRate, closeTo(0.399, 1e-9));
      expect(o.last5mBuys, 2);
    });
  });

  group('RhtTrader / RhtClosedPosition / RhtFlowChain / RhtRadarItem', () {
    test('排行榜行解析与标题回退', () {
      final t = RhtTrader.fromJson({
        'address': '0x9ce0',
        'handle': 'PoorGoat_',
        'display_name': 'PoorGoat🐂',
        'followers': 497807,
        'volume': 588.469,
        'fills': 1,
        'buys': 1,
        'sells': 0,
        'realized_pnl': 0,
        'net_pnl': -0.314,
        'win_rate': null,
        'state': 'flat',
        'active': true,
      });
      expect(t.title, 'PoorGoat🐂');
      expect(t.winRate, isNull);
      expect(t.state, 'flat');
      expect(t.active, isTrue);
    });

    test('display_name 为空时标题回退到 handle', () {
      final t = RhtTrader.fromJson({'handle': 'unipcs'});
      expect(t.title, 'unipcs');
    });

    test('已平仓解析', () {
      final p = RhtClosedPosition.fromJson({
        'wallet': '0xc9ca',
        'token': '0x07a4',
        'opened_ts': 1788591698,
        'closed_ts': 1788592420,
        'cost_sold': 1497.01,
        'proceeds_usd': 2236.12,
        'pnl_usd': 739.11,
        'pnl_pct': 49.37,
        'buys': 1,
        'sells': 1,
        'handle': '31337___',
        'symbol': 'AGI',
        'hold_seconds': 722,
      });
      expect(p.pnlUsd, closeTo(739.11, 0.01));
      expect(p.holdSeconds, 722);
    });

    test('跟单链解析：领买 + 跟随者滞后秒数', () {
      final c = RhtFlowChain.fromJson({
        'token': '0xf9e0',
        'symbol': 'COMMOTITTES',
        'lead': {
          'ts': 1788590757,
          'usd': 446.41,
          'handle': 'FartmanSacks',
          'followers': 39253,
          'wallet': '0x7f6e',
        },
        'followers': [
          {
            'ts': 1788590791,
            'usd': 1496.86,
            'handle': '31337___',
            'followers': 38559,
            'wallet': '0xc9ca',
            'lag_seconds': 34,
          },
        ],
        'follower_count': 2,
        'total_usd': 6935.65,
      });
      expect(c.lead.handle, 'FartmanSacks');
      expect(c.followers, hasLength(1));
      expect(c.followers.first.lagSeconds, 34);
      expect(c.totalUsd, closeTo(6935.65, 0.01));
    });

    test('聪明钱雷达条目解析', () {
      final r = RhtRadarItem.fromJson({
        'token': '0x3ee1',
        'symbol': 'SEX',
        'first_ts': 1788591972,
        'buyers': 1,
        'usd_in': 3910.6,
        'fresh': true,
        'first_buyer': {
          'handle': 'MomoOnChain',
          'followers': 28213,
          'ts': 1788591972,
        },
      });
      expect(r.fresh, isTrue);
      expect(r.firstBuyer!.handle, 'MomoOnChain');
      expect(r.firstBuyer!.followers, 28213);
    });
  });
}
