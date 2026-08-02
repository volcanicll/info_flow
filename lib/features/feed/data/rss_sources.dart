import 'dart:ui';

/// 订阅源分类
enum FeedCategory {
  tech('科技'),
  ai('AI'),
  design('设计'),
  product('产品'),
  openSource('开源'),
  business('商业'),
  news('资讯'),
  macro('宏观'),
  community('社区');

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

/// 全量订阅源注册表
///
/// 这些都是公开、稳定、可离线解析的真实 RSS/Atom 源。
/// 涵盖国内外主流科技 / AI / 设计 / 产品 / 开源 / 资讯媒体。
class RssSources {
  RssSources._();

  // 颜色常量
  static const Color _c36k = Color(0xFF0061FE);
  static const Color _cHuxiu = Color(0xFFE8384F);
  static const Color _cSspai = Color(0xFFC71D2F);
  static const Color _cInfoQ = Color(0xFF0053CC);
  static const Color _cJiqizhixin = Color(0xFF1A1A1A);
  static const Color _cLiangziwei = Color(0xFF5D3CF5);
  static const Color _cIfanr = Color(0xFFCA484C);
  static const Color _cPingwest = Color(0xFF1B8AED);
  static const Color _cTechPlanet = Color(0xFF1E88E5);
  static const Color _cHacker = Color(0xFFFF6600);
  static const Color _cGithub = Color(0xFF24292E);
  static const Color _cRust = Color(0xFFDEA584);
  static const Color _cFlutter = Color(0xFF02569B);
  static const Color _cSmashing = Color(0xFFD33A2C);
  static const Color _cNielsen = Color(0xFF6B21A8);
  static const Color _cWired = Color(0xFF000000);
  static const Color _cTechCrunch = Color(0xFF00C8FF);
  static const Color _cVerge = Color(0xFF5200FF);
  static const Color _cV2ex = Color(0xFFE2A63B);
  static const Color _cProductHunt = Color(0xFFDA552F);
  static const Color _cHuggingFace = Color(0xFFFFD21E);
  static const Color _cCnbc = Color(0xFF0B5AA6);
  static const Color _cReuters = Color(0xFFFF8000);
  static const Color _cBloomberg = Color(0xFF191919);
  static const Color _cMit = Color(0xFF9A1B1B);
  static const Color _cGoogle = Color(0xFF4285F4);
  static const Color _cOpenai = Color(0xFF10A37F);
  static const Color _cArxiv = Color(0xFFB31B1B);
  static const Color _cTldr = Color(0xFF5B21B6);
  static const Color _cGitHubBlog = Color(0xFF6E5494);
  static const Color _cSmol = Color(0xFF0F766E);
  static const Color _cLobsters = Color(0xFFBE2300);
  static const Color _cReddit = Color(0xFFFF4500);
  static const Color _cJuejin = Color(0xFF007FFF);
  static const Color _cSegmentfault = Color(0xFF029F5B);

  static const List<RssSource> all = [
    // ====== 科技 ======
    RssSource(
      id: '36kr',
      name: '36氪',
      feedUrl: 'https://36kr.com/feed',
      siteUrl: 'https://36kr.com',
      category: FeedCategory.tech,
      color: _c36k,
      description: '让一部分人先看到未来',
    ),
    RssSource(
      id: 'huxiu',
      name: '虎嗅',
      feedUrl: 'https://rsshub.app/huxiu/article',
      siteUrl: 'https://www.huxiu.com',
      category: FeedCategory.tech,
      color: _cHuxiu,
      description: '聚合优质创新信息与人群',
    ),
    RssSource(
      id: 'ifanr',
      name: '爱范儿',
      feedUrl: 'https://sso.ifanr.com/feed',
      siteUrl: 'https://www.ifanr.com',
      category: FeedCategory.tech,
      color: _cIfanr,
      description: '关注泛科技与生活方式',
    ),
    RssSource(
      id: 'infoq',
      name: 'InfoQ',
      feedUrl: 'https://www.infoq.cn/feed.xml',
      siteUrl: 'https://www.infoq.cn',
      category: FeedCategory.tech,
      color: _cInfoQ,
      description: '促进软件开发领域知识与创新的传播',
    ),
    RssSource(
      id: 'pingwest',
      name: '品玩',
      feedUrl: 'https://rsshub.app/pingwest/status',
      siteUrl: 'https://www.pingwest.com',
      category: FeedCategory.tech,
      color: _cPingwest,
      description: '有品好玩的科技见闻',
    ),
    RssSource(
      id: 'verge',
      name: 'The Verge',
      feedUrl: 'https://www.theverge.com/rss/index.xml',
      siteUrl: 'https://www.theverge.com',
      category: FeedCategory.tech,
      color: _cVerge,
      description: '科技、科学与文化新闻',
    ),
    RssSource(
      id: 'techcrunch',
      name: 'TechCrunch',
      feedUrl: 'https://techcrunch.com/feed/',
      siteUrl: 'https://techcrunch.com',
      category: FeedCategory.tech,
      color: _cTechCrunch,
      description: '初创公司与科技新闻',
    ),

    // ====== AI ======
    RssSource(
      id: 'jiqizhixin',
      name: '机器之心',
      feedUrl: 'https://rsshub.app/jiqizhixin/news',
      siteUrl: 'https://www.jiqizhixin.com',
      category: FeedCategory.ai,
      color: _cJiqizhixin,
      description: '专业的人工智能媒体',
    ),
    RssSource(
      id: 'liangziwei',
      name: '量子位',
      feedUrl: 'https://rsshub.app/qbitai/category/industry',
      siteUrl: 'https://www.qbitai.com',
      category: FeedCategory.ai,
      color: _cLiangziwei,
      description: '追踪 AI 技术与产品动态',
    ),
    RssSource(
      id: 'hackernews',
      name: 'Hacker News',
      feedUrl: 'https://hnrss.org/frontpage',
      siteUrl: 'https://news.ycombinator.com',
      category: FeedCategory.ai,
      color: _cHacker,
      description: '黑客与创业社区热榜',
    ),

    // ====== 设计 ======
    RssSource(
      id: 'sspai',
      name: '少数派',
      feedUrl: 'https://sspai.com/feed',
      siteUrl: 'https://sspai.com',
      category: FeedCategory.design,
      color: _cSspai,
      description: '高效工作和品质生活',
    ),
    RssSource(
      id: 'smashing',
      name: 'Smashing Magazine',
      feedUrl: 'https://www.smashingmagazine.com/feed/',
      siteUrl: 'https://www.smashingmagazine.com',
      category: FeedCategory.design,
      color: _cSmashing,
      description: '面向设计师与开发者的前沿内容',
    ),

    // ====== 产品 ======
    RssSource(
      id: 'woshipm',
      name: '人人都是产品经理',
      feedUrl: 'https://rsshub.app/woshipm/popular',
      siteUrl: 'https://www.woshipm.com',
      category: FeedCategory.product,
      color: _cNielsen,
      description: '产品经理学习交流社区',
    ),

    // ====== 开源 ======
    RssSource(
      id: 'github',
      name: 'GitHub Trending',
      feedUrl: 'https://rsshub.app/github/trending/daily/all',
      siteUrl: 'https://github.com',
      category: FeedCategory.openSource,
      color: _cGithub,
      description: '每日热门开源项目',
    ),
    RssSource(
      id: 'flutter',
      name: 'Flutter 官方',
      feedUrl: 'https://docs.flutter.dev/feeds/feed.xml',
      siteUrl: 'https://flutter.dev',
      category: FeedCategory.openSource,
      color: _cFlutter,
      description: 'Flutter 最新动态与教程',
    ),
    RssSource(
      id: 'rust',
      name: 'Rust Blog',
      feedUrl: 'https://blog.rust-lang.org/feed.xml',
      siteUrl: 'https://blog.rust-lang.org',
      category: FeedCategory.openSource,
      color: _cRust,
      description: 'Rust 语言官方博客',
    ),

    // ====== 资讯 ======
    RssSource(
      id: 'solidot',
      name: 'Solidot',
      feedUrl: 'https://www.solidot.org/index.rss',
      siteUrl: 'https://www.solidot.org',
      category: FeedCategory.news,
      color: _cTechPlanet,
      description: '科技与奇客资讯',
    ),
    RssSource(
      id: 'wired',
      name: 'WIRED',
      feedUrl: 'https://www.wired.com/feed/rss',
      siteUrl: 'https://www.wired.com',
      category: FeedCategory.news,
      color: _cWired,
      description: '科技如何重塑未来',
    ),

    // ====== V2EX ======
    RssSource(
      id: 'v2ex',
      name: 'V2EX',
      feedUrl: 'https://www.v2ex.com/index.xml',
      siteUrl: 'https://www.v2ex.com',
      category: FeedCategory.tech,
      color: _cV2ex,
      description: '创意工作者社区热门话题',
    ),

    // ====== Product Hunt ======
    RssSource(
      id: 'producthunt',
      name: 'Product Hunt',
      feedUrl: 'https://rsshub.app/producthunt/today',
      siteUrl: 'https://www.producthunt.com',
      category: FeedCategory.product,
      color: _cProductHunt,
      description: '每日最佳新产品',
    ),

    // ====== AI 模型 ======
    RssSource(
      id: 'huggingface',
      name: 'HuggingFace',
      feedUrl: 'https://rsshub.app/huggingface/daily-papers',
      siteUrl: 'https://huggingface.co',
      category: FeedCategory.ai,
      color: _cHuggingFace,
      description: 'AI 趋势模型与论文',
    ),

    // ====== 宏观金融（来自 TechDaily 宏观模块） ======
    RssSource(
      id: 'cnbc-markets',
      name: 'CNBC Markets',
      feedUrl: 'https://www.cnbc.com/id/100003114/device/rss/rss.html',
      siteUrl: 'https://www.cnbc.com',
      category: FeedCategory.macro,
      color: _cCnbc,
      description: '全球市场与宏观要闻',
    ),
    RssSource(
      id: 'reuters-business',
      name: 'Reuters Business',
      feedUrl: 'https://www.reutersagency.com/feed/',
      siteUrl: 'https://www.reuters.com',
      category: FeedCategory.macro,
      color: _cReuters,
      description: '路透商业与金融资讯',
    ),
    RssSource(
      id: 'bloomberg-markets',
      name: 'Bloomberg Markets',
      feedUrl: 'https://feeds.bloomberg.com/markets/news.rss',
      siteUrl: 'https://www.bloomberg.com/markets',
      category: FeedCategory.macro,
      color: _cBloomberg,
      description: '彭博市场与宏观数据',
    ),

    // ====== AI 官方 / 研究博客（来自 TechDaily AI 资讯模块） ======
    RssSource(
      id: 'mit-tech-ai',
      name: 'MIT Tech Review AI',
      feedUrl:
          'https://www.technologyreview.com/topic/artificial-intelligence/feed',
      siteUrl: 'https://www.technologyreview.com',
      category: FeedCategory.ai,
      color: _cMit,
      description: 'MIT 科技评论人工智能专题',
    ),
    RssSource(
      id: 'google-ai',
      name: 'Google AI Blog',
      feedUrl: 'https://research.google/blog/rss',
      siteUrl: 'https://research.google',
      category: FeedCategory.ai,
      color: _cGoogle,
      description: 'Google Research 官方博客',
    ),
    RssSource(
      id: 'openai-news',
      name: 'OpenAI Blog',
      feedUrl: 'https://openai.com/news/rss.xml',
      siteUrl: 'https://openai.com',
      category: FeedCategory.ai,
      color: _cOpenai,
      description: 'OpenAI 官方新闻与研究',
    ),
    RssSource(
      id: 'arxiv-cs-ai',
      name: 'ArXiv CS.AI',
      feedUrl: 'https://rss.arxiv.org/rss/cs.ai',
      siteUrl: 'https://arxiv.org/list/cs.AI/recent',
      category: FeedCategory.ai,
      color: _cArxiv,
      description: '人工智能领域最新论文预印本',
    ),
    RssSource(
      id: 'tldr-tech',
      name: 'TLDR Tech',
      feedUrl: 'https://tldr.tech/tech.rss',
      siteUrl: 'https://tldr.tech',
      category: FeedCategory.tech,
      color: _cTldr,
      description: '开发者每日科技摘要',
    ),

    // ====== Agent Code 前沿（来自 TechDaily Agent Code 模块） ======
    RssSource(
      id: 'github-blog',
      name: 'GitHub Blog',
      feedUrl: 'https://github.blog/feed/',
      siteUrl: 'https://github.blog',
      category: FeedCategory.tech,
      color: _cGitHubBlog,
      description: 'GitHub 官方博客（Copilot / Agent）',
    ),
    RssSource(
      id: 'smol-ai',
      name: 'Smol AI News',
      feedUrl: 'https://news.smol.ai/rss.xml',
      siteUrl: 'https://news.smol.ai',
      category: FeedCategory.ai,
      color: _cSmol,
      description: 'AI 编程与 Agent 前沿动态',
    ),

    // ====== 技术社区（来自 TechDaily 社区模块） ======
    RssSource(
      id: 'lobsters',
      name: 'Lobsters',
      feedUrl: 'https://lobste.rs/rss',
      siteUrl: 'https://lobste.rs',
      category: FeedCategory.community,
      color: _cLobsters,
      description: '黑客与开发者技术社区',
    ),
    RssSource(
      id: 'reddit-programming',
      name: 'Reddit r/programming',
      feedUrl: 'https://www.reddit.com/r/programming/.rss',
      siteUrl: 'https://www.reddit.com/r/programming',
      category: FeedCategory.community,
      color: _cReddit,
      description: '编程与软件开发社区热帖',
    ),
    RssSource(
      id: 'reddit-ml',
      name: 'Reddit r/MachineLearning',
      feedUrl: 'https://www.reddit.com/r/MachineLearning/.rss',
      siteUrl: 'https://www.reddit.com/r/MachineLearning',
      category: FeedCategory.community,
      color: _cReddit,
      description: '机器学习研究者社区热帖',
    ),
    RssSource(
      id: 'reddit-localllama',
      name: 'Reddit r/LocalLLaMA',
      feedUrl: 'https://www.reddit.com/r/LocalLLaMA/.rss',
      siteUrl: 'https://www.reddit.com/r/LocalLLaMA',
      category: FeedCategory.community,
      color: _cReddit,
      description: '本地大模型社区（LLM/Agent）',
    ),
    RssSource(
      id: 'juejin',
      name: '掘金',
      feedUrl: 'https://rsshub.app/juejin/category/6809637773838385159',
      siteUrl: 'https://juejin.cn',
      category: FeedCategory.community,
      color: _cJuejin,
      description: '中文开发者社区热门文章',
    ),
    RssSource(
      id: 'segmentfault',
      name: 'SegmentFault',
      feedUrl: 'https://segmentfault.com/questions/hot/rss',
      siteUrl: 'https://segmentfault.com',
      category: FeedCategory.community,
      color: _cSegmentfault,
      description: '中文技术问答社区热门问题',
    ),
  ];

  /// 按分类获取
  static List<RssSource> byCategory(FeedCategory category) =>
      all.where((s) => s.category == category).toList();

  /// 默认订阅（信息流推荐源）
  static const List<String> defaultSubscribedIds = [
    '36kr',
    'huxiu',
    'ifanr',
    'infoq',
    'jiqizhixin',
    'liangziwei',
    'sspai',
    'hackernews',
    'github',
    'solidot',
    'v2ex',
    'producthunt',
    'huggingface',
    'cnbc-markets',
    'mit-tech-ai',
    'openai-news',
    'github-blog',
    'lobsters',
    'reddit-programming',
    'juejin',
  ];

  /// 根据 id 查找
  static RssSource? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
