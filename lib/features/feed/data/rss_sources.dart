import 'dart:ui';

/// 订阅源分类（专注于 Web3 与四大核心链/生态）
enum FeedCategory {
  all('全部'),
  solana('Solana'),
  base('Base'),
  bsc('BSC'),
  robinhood('Robinhood'),
  news('行业要闻'),
  defi('DeFi/Alpha');

  final String label;
  const FeedCategory(this.label);
}

/// 一个 RSS 订阅源定义
class RssSource {
  final String id;
  final String name;
  /// RSS/Atom 订阅地址
  final String feedUrl;
  /// 站点首页地址（用于取 favicon）
  final String siteUrl;
  final FeedCategory category;
  /// 来源主色（用于图标渐变 / 头像背景）
  final Color color;
  final String description;

  const RssSource({
    required this.id,
    required this.name,
    required this.feedUrl,
    required this.siteUrl,
    required this.category,
    required this.color,
    required this.description,
  });

  /// 取站点域名（用于抓取 favicon 图标）
  String get faviconUrl {
    final uri = Uri.tryParse(siteUrl);
    if (uri == null || uri.host.isEmpty) return '';
    return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
  }
}

/// 生产级链上与 Web3 订阅源注册表
class RssSources {
  RssSources._();

  // 专属品牌色
  static const Color _cSolana = Color(0xFF14F195);
  static const Color _cBase = Color(0xFF0052FF);
  static const Color _cBsc = Color(0xFFF3BA2F);
  static const Color _cRobinhood = Color(0xFF00C805);
  static const Color _cCoinDesk = Color(0xFF0D1B2A);
  static const Color _cDecrypt = Color(0xFF1B1B1B);
  static const Color _cBlockworks = Color(0xFFFF5200);
  static const Color _cCointelegraph = Color(0xFFFABD00);
  static const Color _cForesight = Color(0xFF2563EB);
  static const Color _cPANews = Color(0xFF0EA5E9);
  static const Color _cBankless = Color(0xFFE11D48);
  static const Color _cTheBlock = Color(0xFF000000);
  static const Color _cSoPilot = Color(0xFF14171A);

  static const List<RssSource> all = [
    // ====== Solana 生态 ======
    RssSource(
      id: 'solana-floor',
      name: 'Solana Floor',
      feedUrl: 'https://solanafloor.com/feed',
      siteUrl: 'https://solanafloor.com',
      category: FeedCategory.solana,
      color: _cSolana,
      description: 'Solana 原生生态资讯与 DeFi 动态',
    ),
    RssSource(
      id: 'solana-blog',
      name: 'Solana 官方博客',
      feedUrl: 'https://solana.com/news/rss.xml',
      siteUrl: 'https://solana.com',
      category: FeedCategory.solana,
      color: _cSolana,
      description: 'Solana 基金会与技术升级公告',
    ),

    // ====== Base 生态 ======
    RssSource(
      id: 'base-mirror',
      name: 'Base 官方资讯',
      feedUrl: 'https://base.mirror.xyz/feed/atom',
      siteUrl: 'https://base.org',
      category: FeedCategory.base,
      color: _cBase,
      description: 'Coinbase 孵化 L2 网络 Base 核心动态',
    ),
    RssSource(
      id: 'optimism-blog',
      name: 'Superchain 动态',
      feedUrl: 'https://optimism.mirror.xyz/feed/atom',
      siteUrl: 'https://optimism.io',
      category: FeedCategory.base,
      color: _cBase,
      description: 'OP Stack 与 Superchain 生态演进',
    ),

    // ====== BSC (BNB Smart Chain) 生态 ======
    RssSource(
      id: 'bsc-news',
      name: 'BSC News',
      feedUrl: 'https://www.bsc.news/feed',
      siteUrl: 'https://www.bsc.news',
      category: FeedCategory.bsc,
      color: _cBsc,
      description: 'BNB 链上生态项目与 DeFi 报道',
    ),
    RssSource(
      id: 'bnbchain-blog',
      name: 'BNB Chain 官方',
      feedUrl: 'https://www.bnbchain.org/en/blog/rss.xml',
      siteUrl: 'https://www.bnbchain.org',
      category: FeedCategory.bsc,
      color: _cBsc,
      description: 'BNB Chain 开发者及黑客松官方公告',
    ),

    // ====== Robinhood 生态 ======
    RssSource(
      id: 'robinhood-crypto',
      name: 'Robinhood Crypto',
      feedUrl: 'https://robinhood.com/us/en/newsroom/rss/',
      siteUrl: 'https://robinhood.com',
      category: FeedCategory.robinhood,
      color: _cRobinhood,
      description: 'Robinhood 上币公告、SEC 合规与加密业务动态',
    ),

    // ====== 行业核心要闻 ======
    RssSource(
      id: 'coindesk',
      name: 'CoinDesk',
      feedUrl: 'https://www.coindesk.com/arc/outboundfeeds/rss/',
      siteUrl: 'https://www.coindesk.com',
      category: FeedCategory.news,
      color: _cCoinDesk,
      description: '全球顶级加密财经与监管前沿',
    ),
    RssSource(
      id: 'decrypt',
      name: 'Decrypt',
      feedUrl: 'https://decrypt.co/feed',
      siteUrl: 'https://decrypt.co',
      category: FeedCategory.news,
      color: _cDecrypt,
      description: '深入浅出的 Web3 与链上要闻',
    ),
    RssSource(
      id: 'blockworks',
      name: 'Blockworks',
      feedUrl: 'https://blockworks.co/feed',
      siteUrl: 'https://blockworks.co',
      category: FeedCategory.news,
      color: _cBlockworks,
      description: '面向机构投资者的加密与宏观洞察',
    ),
    RssSource(
      id: 'cointelegraph',
      name: 'Cointelegraph',
      feedUrl: 'https://cointelegraph.com/rss',
      siteUrl: 'https://cointelegraph.com',
      category: FeedCategory.news,
      color: _cCointelegraph,
      description: '突发加密新闻与行情异动分析',
    ),
    RssSource(
      id: 'foresight-news',
      name: 'Foresight News',
      feedUrl: 'https://foresightnews.pro/rss/rss.xml',
      siteUrl: 'https://foresightnews.pro',
      category: FeedCategory.news,
      color: _cForesight,
      description: '中文前沿 Web3 深度研报与快讯',
    ),
    RssSource(
      id: 'panews',
      name: 'PANews',
      feedUrl: 'https://rsshub.app/panewslab/news',
      siteUrl: 'https://www.panewslab.com',
      category: FeedCategory.news,
      color: _cPANews,
      description: '全天候区块链即时深度快讯',
    ),

    // ====== DeFi 与 Alpha 投研 ======
    RssSource(
      id: 'bankless',
      name: 'Bankless',
      feedUrl: 'https://www.bankless.com/rss/feed',
      siteUrl: 'https://www.bankless.com',
      category: FeedCategory.defi,
      color: _cBankless,
      description: '链上财富密码与加密金融指南',
    ),
    RssSource(
      id: 'the-block',
      name: 'The Block',
      feedUrl: 'https://www.theblock.co/rss.xml',
      siteUrl: 'https://www.theblock.co',
      category: FeedCategory.defi,
      color: _cTheBlock,
      description: '权威链上数据研究与行业情报',
    ),
    RssSource(
      id: 'sopilot-hot-tweets',
      name: 'SoPilot · X 起爆帖',
      feedUrl: 'https://sopilot.net/rss/hottweets',
      siteUrl: 'https://sopilot.net/zh/hot-tweets',
      category: FeedCategory.defi,
      color: _cSoPilot,
      description: 'X 上正在起爆的 Web3 帖子（爆速监测，约 30 分钟更新）',
    ),
  ];

  /// 按分类获取
  static List<RssSource> byCategory(FeedCategory category) {
    if (category == FeedCategory.all) return all;
    return all.where((s) => s.category == category).toList();
  }

  /// 默认订阅源
  static const List<String> defaultSubscribedIds = [
    'solana-floor',
    'base-mirror',
    'bsc-news',
    'robinhood-crypto',
    'coindesk',
    'decrypt',
    'foresight-news',
    'panews',
    'bankless',
    'sopilot-hot-tweets',
  ];

  /// 根据 id 查找
  static RssSource? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
