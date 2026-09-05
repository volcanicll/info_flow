enum ChainType {
  solana('solana', 'Solana', 'SOL'),
  base('base', 'Base', 'BASE'),
  bsc('bsc', 'BNB Smart Chain', 'BSC'),
  robinhood('robinhood', 'Robinhood', 'HOOD');

  final String id;
  final String label;
  final String shortName;
  const ChainType(this.id, this.label, this.shortName);

  static ChainType fromId(String? id) {
    if (id == null) return ChainType.solana;
    final lower = id.toLowerCase();
    if (lower.contains('solana') || lower == 'sol') return ChainType.solana;
    if (lower == 'base') return ChainType.base;
    if (lower.contains('bsc') || lower == 'binance' || lower == '56') {
      return ChainType.bsc;
    }
    if (lower.contains('robinhood') || lower == 'hood') {
      return ChainType.robinhood;
    }
    return ChainType.solana;
  }
}

/// 链上代币行情与基础信息
class OnChainToken {
  final String address;
  final String name;
  final String symbol;
  final ChainType chain;
  final double priceUsd;
  final double priceChange5m;
  final double priceChange1h;
  final double priceChange24h;
  final double volume24h;
  final double liquidityUsd;
  final double fdv;
  final double? marketCap;
  final String? pairAddress;
  final String? dexId;
  final String? url;
  final String? iconUrl;
  final int txns24hBuys;
  final int txns24hSells;
  final DateTime? pairCreatedAt;

  const OnChainToken({
    required this.address,
    required this.name,
    required this.symbol,
    required this.chain,
    required this.priceUsd,
    this.priceChange5m = 0,
    this.priceChange1h = 0,
    this.priceChange24h = 0,
    this.volume24h = 0,
    this.liquidityUsd = 0,
    this.fdv = 0,
    this.marketCap,
    this.pairAddress,
    this.dexId,
    this.url,
    this.iconUrl,
    this.txns24hBuys = 0,
    this.txns24hSells = 0,
    this.pairCreatedAt,
  });

  factory OnChainToken.fromDexScreenerPair(Map<String, dynamic> json) {
    final baseToken = json['baseToken'] as Map<String, dynamic>? ?? {};
    final priceChange = json['priceChange'] as Map<String, dynamic>? ?? {};
    final volume = json['volume'] as Map<String, dynamic>? ?? {};
    final liquidity = json['liquidity'] as Map<String, dynamic>? ?? {};
    final txns = json['txns'] as Map<String, dynamic>? ?? {};
    final txns24h = txns['h24'] as Map<String, dynamic>? ?? {};
    final info = json['info'] as Map<String, dynamic>? ?? {};

    double parseNum(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final chainStr = json['chainId'] as String? ?? 'solana';

    return OnChainToken(
      address: baseToken['address']?.toString() ?? '',
      name: baseToken['name']?.toString() ?? 'Unknown',
      symbol: (baseToken['symbol']?.toString() ?? '').toUpperCase(),
      chain: ChainType.fromId(chainStr),
      priceUsd: parseNum(json['priceUsd']),
      priceChange5m: parseNum(priceChange['m5']),
      priceChange1h: parseNum(priceChange['h1']),
      priceChange24h: parseNum(priceChange['h24']),
      volume24h: parseNum(volume['h24']),
      liquidityUsd: parseNum(liquidity['usd']),
      fdv: parseNum(json['fdv']),
      marketCap: json['marketCap'] != null ? parseNum(json['marketCap']) : null,
      pairAddress: json['pairAddress']?.toString(),
      dexId: json['dexId']?.toString(),
      url: json['url']?.toString(),
      iconUrl: info['imageUrl']?.toString(),
      txns24hBuys: (txns24h['buys'] as num?)?.toInt() ?? 0,
      txns24hSells: (txns24h['sells'] as num?)?.toInt() ?? 0,
      pairCreatedAt: json['pairCreatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['pairCreatedAt'] as num).toInt())
          : null,
    );
  }
}

enum SecurityRiskLevel {
  safe('安全', 0xFF10B981),
  warning('中危', 0xFFF59E0B),
  danger('高危/貔貅', 0xFFEF4444);

  final String label;
  final int colorValue;
  const SecurityRiskLevel(this.label, this.colorValue);
}

/// GoPlus 链上安全审计结果
class TokenSecurity {
  final bool isHoneypot;
  final double buyTax;
  final double sellTax;
  final bool isMintable;
  final bool isFreezable;
  final bool canTakeBackOwnership;
  final bool isBlacklist;
  final double top10HolderPercent;
  final int holderCount;
  final bool isOpenSource;
  final int score;
  final SecurityRiskLevel riskLevel;
  final List<String> warnings;

  const TokenSecurity({
    required this.isHoneypot,
    required this.buyTax,
    required this.sellTax,
    required this.isMintable,
    required this.isFreezable,
    required this.canTakeBackOwnership,
    required this.isBlacklist,
    required this.top10HolderPercent,
    required this.holderCount,
    required this.isOpenSource,
    required this.score,
    required this.riskLevel,
    required this.warnings,
  });

  factory TokenSecurity.fromGoPlusEvm(Map<String, dynamic> json) {
    bool isTrue(dynamic v) => v == '1' || v == 1 || v == true;
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final isHoneypot = isTrue(json['is_honeypot']);
    final buyTax = toDouble(json['buy_tax']) * 100;
    final sellTax = toDouble(json['sell_tax']) * 100;
    final isMintable = isTrue(json['is_mintable']);
    final canTakeBack = isTrue(json['can_take_back_ownership']);
    final isBlacklist = isTrue(json['is_blacklisted']);
    final isOpenSource = isTrue(json['is_open_source']);
    final holderCount = int.tryParse(json['holder_count']?.toString() ?? '0') ?? 0;

    // 计算 top10 holders
    double top10 = 0.0;
    final holders = json['holders'] as List<dynamic>?;
    if (holders != null) {
      for (final h in holders.take(10)) {
        if (h is Map) {
          top10 += toDouble(h['percent']) * 100;
        }
      }
    }

    final warnings = <String>[];
    int penalty = 0;

    if (isHoneypot) {
      warnings.add('🚨 貔貅代码：无法正常卖出');
      penalty += 80;
    }
    if (buyTax > 10) {
      warnings.add('⚠️ 极高买税: ${buyTax.toStringAsFixed(1)}%');
      penalty += 20;
    }
    if (sellTax > 10) {
      warnings.add('⚠️ 极高卖税: ${sellTax.toStringAsFixed(1)}%');
      penalty += 25;
    }
    if (isMintable) {
      warnings.add('⚠️ 存在增发权限 (Mintable)');
      penalty += 15;
    }
    if (canTakeBack) {
      warnings.add('⚠️ 所有权可被找回');
      penalty += 20;
    }
    if (isBlacklist) {
      warnings.add('⚠️ 包含黑名单功能');
      penalty += 15;
    }
    if (top10 > 70) {
      warnings.add('⚠️ 前10持币地址占比集中 (${top10.toStringAsFixed(1)}%)');
      penalty += 15;
    }
    if (!isOpenSource && !isHoneypot) {
      warnings.add('ℹ️ 合约未开源');
      penalty += 10;
    }

    final score = (100 - penalty).clamp(0, 100);
    SecurityRiskLevel level;
    if (isHoneypot || score < 40) {
      level = SecurityRiskLevel.danger;
    } else if (score < 75) {
      level = SecurityRiskLevel.warning;
    } else {
      level = SecurityRiskLevel.safe;
    }

    return TokenSecurity(
      isHoneypot: isHoneypot,
      buyTax: buyTax,
      sellTax: sellTax,
      isMintable: isMintable,
      isFreezable: false,
      canTakeBackOwnership: canTakeBack,
      isBlacklist: isBlacklist,
      top10HolderPercent: top10,
      holderCount: holderCount,
      isOpenSource: isOpenSource,
      score: score,
      riskLevel: level,
      warnings: warnings,
    );
  }

  factory TokenSecurity.fromGoPlusSolana(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    // Solana: 检查 freeze authority / mint authority / closable / balance_mutable
    final mintAuth = json['mint_authority'] as Map<String, dynamic>?;
    final isMintable = mintAuth != null && mintAuth['status'] != '0';

    final freezeAuth = json['freeze_authority'] as Map<String, dynamic>?;
    final isFreezable = freezeAuth != null && freezeAuth['status'] != '0';

    final closable = json['closable'] as Map<String, dynamic>?;
    final isClosable = closable != null && closable['status'] != '0';

    final holderCount = int.tryParse(json['holder_count']?.toString() ?? '0') ?? 0;

    double top10 = 0.0;
    final holders = json['holders'] as List<dynamic>?;
    if (holders != null) {
      for (final h in holders.take(10)) {
        if (h is Map) {
          top10 += toDouble(h['percent']) * 100;
        }
      }
    }

    final warnings = <String>[];
    int penalty = 0;

    if (isFreezable) {
      warnings.add('🚨 冻结权限未丢弃 (Freeze Authority Active)');
      penalty += 35;
    }
    if (isMintable) {
      warnings.add('⚠️ 铸造权限未丢弃 (Mint Authority Active)');
      penalty += 25;
    }
    if (isClosable) {
      warnings.add('⚠️ 代币账户可被关闭 (Closable)');
      penalty += 15;
    }
    if (top10 > 60) {
      warnings.add('⚠️ 前10持币地址集中 (${top10.toStringAsFixed(1)}%)');
      penalty += 15;
    }

    final score = (100 - penalty).clamp(0, 100);
    SecurityRiskLevel level;
    if (score < 50) {
      level = SecurityRiskLevel.danger;
    } else if (score < 80) {
      level = SecurityRiskLevel.warning;
    } else {
      level = SecurityRiskLevel.safe;
    }

    return TokenSecurity(
      isHoneypot: isFreezable,
      buyTax: 0,
      sellTax: 0,
      isMintable: isMintable,
      isFreezable: isFreezable,
      canTakeBackOwnership: false,
      isBlacklist: false,
      top10HolderPercent: top10,
      holderCount: holderCount,
      isOpenSource: true,
      score: score,
      riskLevel: level,
      warnings: warnings,
    );
  }

  static TokenSecurity safeDefault() => const TokenSecurity(
        isHoneypot: false,
        buyTax: 0,
        sellTax: 0,
        isMintable: false,
        isFreezable: false,
        canTakeBackOwnership: false,
        isBlacklist: false,
        top10HolderPercent: 15.0,
        holderCount: 1000,
        isOpenSource: true,
        score: 95,
        riskLevel: SecurityRiskLevel.safe,
        warnings: [],
      );
}
