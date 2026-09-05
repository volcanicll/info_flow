import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/token_screener/domain/models/onchain_token.dart';

void main() {
  group('OnChainToken 模型与链解析测试', () {
    test('ChainType 正确识别 solana, base, bsc, robinhood', () {
      expect(ChainType.fromId('solana'), ChainType.solana);
      expect(ChainType.fromId('sol'), ChainType.solana);
      expect(ChainType.fromId('base'), ChainType.base);
      expect(ChainType.fromId('bsc'), ChainType.bsc);
      expect(ChainType.fromId('binance'), ChainType.bsc);
      expect(ChainType.fromId('robinhood'), ChainType.robinhood);
      expect(ChainType.fromId('hood'), ChainType.robinhood);
      expect(ChainType.fromId(null), ChainType.solana);
    });

    test('fromDexScreenerPair 正确解析交易对字典', () {
      final json = {
        'chainId': 'base',
        'dexId': 'aerodrome',
        'url': 'https://dexscreener.com/base/0x123',
        'pairAddress': '0xpair123',
        'baseToken': {
          'address': '0xbase123',
          'name': 'Aerodrome',
          'symbol': 'AERO',
        },
        'priceUsd': '1.25',
        'priceChange': {
          'm5': '0.5',
          'h1': '-1.2',
          'h24': '15.4',
        },
        'volume': {
          'h24': '12500000',
        },
        'liquidity': {
          'usd': '45000000',
        },
        'fdv': '1250000000',
        'txns': {
          'h24': {
            'buys': 5200,
            'sells': 3800,
          },
        },
      };

      final token = OnChainToken.fromDexScreenerPair(json);
      expect(token.symbol, 'AERO');
      expect(token.name, 'Aerodrome');
      expect(token.chain, ChainType.base);
      expect(token.priceUsd, 1.25);
      expect(token.priceChange24h, 15.4);
      expect(token.volume24h, 12500000);
      expect(token.liquidityUsd, 45000000);
      expect(token.txns24hBuys, 5200);
      expect(token.txns24hSells, 3800);
    });
  });

  group('TokenSecurity GoPlus 安全审计测试', () {
    test('EVM 貔貅代码与高税识别', () {
      final evilJson = {
        'is_honeypot': '1',
        'buy_tax': '0.15',
        'sell_tax': '0.25',
        'is_mintable': '1',
        'can_take_back_ownership': '1',
        'is_blacklisted': '1',
        'holder_count': '45',
        'holders': [
          {'percent': '0.80'},
        ],
      };

      final sec = TokenSecurity.fromGoPlusEvm(evilJson);
      expect(sec.isHoneypot, true);
      expect(sec.buyTax, 15.0);
      expect(sec.sellTax, 25.0);
      expect(sec.isMintable, true);
      expect(sec.canTakeBackOwnership, true);
      expect(sec.isBlacklist, true);
      expect(sec.riskLevel, SecurityRiskLevel.danger);
      expect(sec.warnings.length, greaterThanOrEqualTo(4));
    });

    test('Solana 冻结权未放弃识别', () {
      final solJson = {
        'mint_authority': {'status': '1'},
        'freeze_authority': {'status': '1'},
        'closable': {'status': '0'},
        'holder_count': '1500',
      };

      final sec = TokenSecurity.fromGoPlusSolana(solJson);
      expect(sec.isFreezable, true);
      expect(sec.isMintable, true);
      expect(sec.riskLevel, SecurityRiskLevel.danger);
      expect(sec.warnings.any((w) => w.contains('Freeze')), true);
    });

    test('安全默认值', () {
      final safe = TokenSecurity.safeDefault();
      expect(safe.isHoneypot, false);
      expect(safe.score, 95);
      expect(safe.riskLevel, SecurityRiskLevel.safe);
      expect(safe.warnings, isEmpty);
    });
  });
}
