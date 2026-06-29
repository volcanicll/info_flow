# 信息聚合类 App 技术方案

---

## 一、产品定位

### 1.1 产品概述

一款基于 AI 驱动的信息聚合 App，从多源渠道（新闻、社交媒体、RSS、公众号、视频等）抓取内容，通过智能算法去重、摘要、分类，为用户提供**一站式、个性化、高信噪比**的信息消费体验。

### 1.2 核心价值

| 痛点 | 解决方案 |
|------|----------|
| 信息过载，噪音多 | AI 摘要 + 智能过滤，只看核心内容 |
| 多平台切换，效率低 | 多源聚合，一个 App 看完所有关注源 |
| 算法投喂，信息茧房 | 用户自主订阅 + AI 推荐双模式 |
| 长文阅读耗时 | AI 一键生成摘要、要点提炼 |

### 1.3 目标用户

- 信息工作者（产品经理、分析师、运营、开发者）
- 内容创作者（需要追踪行业动态）
- 深度阅读用户（追求高质量信息消费）

---

## 二、功能架构

```
┌──────────────────────────────────────────────────────┐
│                    信息聚合 App                        │
├──────────┬──────────┬──────────┬─────────────────────┤
│  信息流   │  AI 能力  │  订阅管理  │     个人中心       │
├──────────┼──────────┼──────────┼─────────────────────┤
│ 推荐流    │ AI 摘要   │ RSS 订阅  │ 阅读统计           │
│ 关注流    │ AI 翻译   │ 公众号    │ 收藏夹             │
│ 话题流    │ 要点提炼   │ 社交媒体  │ 阅读偏好设置       │
│ 热榜      │ 智能去重   │ 新闻源    │ 主题/字体设置      │
│ 搜索      │ 情感分析   │ 自定义源  │ 数据导出           │
│ 稍后阅读  │ 对话问答   │ OPML 导入 │ 账号与隐私         │
└──────────┴──────────┴──────────┴─────────────────────┘
```

### 2.1 核心功能说明

#### 信息流
- **推荐流**：基于用户行为 + 偏好的个性化推荐
- **关注流**：用户订阅源的按时间排序内容
- **话题流**：按科技/财经/产品/设计等话题分类
- **热榜**：多源热度聚合排行
- **搜索**：全文搜索 + 语义搜索
- **稍后阅读**：一键收藏，离线可读

#### AI 能力
- **AI 摘要**：一键生成文章 3-5 句核心摘要
- **AI 翻译**：外文内容实时翻译
- **要点提炼**：长文自动提取关键要点列表
- **智能去重**：同一事件多源报道自动合并
- **情感分析**：标注文章情感倾向（正面/中性/负面）
- **对话问答**：基于已订阅内容进行 AI 问答

#### 订阅管理
- **RSS 订阅**：支持 RSS 2.0 / Atom / JSON Feed
- **公众号**：微信公众号内容抓取
- **社交媒体**：微博 / Twitter / 即刻等
- **新闻源**：36kr / 虎嗅 / 少数派等
- **自定义源**：支持 CSS Selector 配置抓取规则
- **OPML 导入**：支持从其他 RSS 阅读器迁移

---

## 三、技术架构

### 3.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        客户端 (Flutter)                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐  │
│  │ 信息流页面 │ │ 阅读页面  │ │ 订阅管理  │ │  AI 对话页面   │  │
│  └─────┬────┘ └─────┬────┘ └─────┬────┘ └──────┬────────┘  │
│        └─────────────┴───────────┴──────────────┘           │
│                    │ 统一 API 网关                            │
└────────────────────┼────────────────────────────────────────┘
                     │ HTTPS / WebSocket
┌────────────────────┼────────────────────────────────────────┐
│                    ▼          服务端                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              API Gateway (Kong / Nginx)               │   │
│  └──────┬──────────┬──────────┬──────────┬──────────────┘   │
│         │          │          │          │                    │
│  ┌──────▼───┐ ┌────▼────┐ ┌──▼───┐ ┌───▼──────┐            │
│  │ 用户服务  │ │ 内容服务 │ │AI服务 │ │ 订阅服务  │            │
│  └──────┬───┘ └────┬────┘ └──┬───┘ └───┬──────┘            │
│         │          │         │         │                     │
│  ┌──────▼──────────▼─────────▼─────────▼──────┐             │
│  │              消息队列 (Kafka)                │             │
│  └──────────────────┬────────────────────────┘              │
│                     │                                        │
│  ┌──────────────────▼────────────────────────┐              │
│  │            数据层                           │              │
│  │  PostgreSQL │ Redis │ Elasticsearch │ S3   │              │
│  └───────────────────────────────────────────┘              │
│                                                              │
│  ┌───────────────────────────────────────────┐              │
│  │          爬虫调度服务 (独立部署)             │              │
│  │  RSS 爬虫 │ 网页爬虫 │ API 对接 │ 清洗管道  │              │
│  └───────────────────────────────────────────┘              │
└──────────────────────────────────────────────────────────────┘
```

### 3.2 技术选型

#### 客户端

| 模块 | 技术选型 | 选型理由 |
|------|---------|---------|
| **框架** | Flutter 3.x | 性能最优、UI 一致性、单代码库双端 |
| **语言** | Dart 3.x | 空安全、模式匹配、AOT 编译 |
| **状态管理** | Riverpod 2.x | 编译时安全、可测试、依赖注入 |
| **路由** | go_router | 声明式路由、深链接支持 |
| **网络请求** | Dio + retrofit | 拦截器链、自动序列化 |
| **本地数据库** | Drift (SQLite) + Isar | 离线缓存、全文搜索 |
| **WebView** | flutter_inappwebview | 原文阅读 |
| **富文本渲染** | flutter_html / 自定义 Render | 文章内容展示 |
| **图片缓存** | cached_network_image | 内存+磁盘二级缓存 |
| **推送** | firebase_messaging + 极光推送 | 双平台推送 |
| **分享** | share_plus | 系统分享面板 |

#### 服务端

| 模块 | 技术选型 | 选型理由 |
|------|---------|---------|
| **主框架** | Go (Gin/Fiber) | 高并发、低资源、适合 I/O 密集 |
| **AI 服务** | Python (FastAPI) | AI 生态丰富、LLM 集成方便 |
| **API 网关** | Kong / Nginx | 限流、鉴权、日志 |
| **消息队列** | Kafka | 高吞吐、内容处理管道 |
| **主数据库** | PostgreSQL | JSON 支持、全文搜索、可靠 |
| **缓存** | Redis | 热点数据、会话、限流 |
| **搜索引擎** | Elasticsearch | 全文搜索 + 语义搜索 |
| **对象存储** | MinIO / S3 | 图片、文章快照 |
| **爬虫框架** | Scrapy + 自研调度 | RSS + 网页 + API 多源抓取 |
| **任务调度** | Celery + Redis | 定时抓取、AI 处理任务 |
| **容器化** | Docker + K8s | 弹性伸缩、灰度发布 |

#### AI 能力

| 能力 | 技术选型 | 说明 |
|------|---------|------|
| **摘要生成** | GPT-4o-mini / 通义千问 | 性价比高，摘要质量好 |
| **翻译** | DeepL API / 大模型 | 兼顾质量与成本 |
| **语义搜索** | BGE/M3E Embedding + ES | 向量检索 + 关键词检索混合 |
| **智能去重** | SimHash + 语义相似度 | 两级去重，先粗后精 |
| **情感分析** | 大模型 few-shot | 无需训练，效果稳定 |
| **对话问答** | RAG (检索增强生成) | 基于用户订阅内容回答 |

---

## 四、数据模型设计

### 4.1 核心实体

```sql
-- 用户
CREATE TABLE users (
    id          BIGSERIAL PRIMARY KEY,
    username    VARCHAR(50) UNIQUE NOT NULL,
    email       VARCHAR(255) UNIQUE NOT NULL,
    avatar_url  TEXT,
    preferences JSONB DEFAULT '{}',  -- 阅读偏好、主题设置
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 订阅源
CREATE TABLE feeds (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    url         TEXT NOT NULL,
    feed_type   VARCHAR(20) NOT NULL,  -- rss/wechat/twitter/custom
    icon_url    TEXT,
    category    VARCHAR(50),
    fetch_config JSONB DEFAULT '{}',   -- 抓取规则配置
    last_fetched TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 用户订阅关系
CREATE TABLE subscriptions (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT REFERENCES users(id),
    feed_id     BIGINT REFERENCES feeds(id),
    group_name  VARCHAR(100),          -- 分组名
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, feed_id)
);

-- 文章
CREATE TABLE articles (
    id          BIGSERIAL PRIMARY KEY,
    feed_id     BIGINT REFERENCES feeds(id),
    title       VARCHAR(500) NOT NULL,
    url         TEXT NOT NULL,
    content     TEXT,                   -- 正文(清洗后)
    raw_content TEXT,                   -- 原始HTML
    summary     TEXT,                   -- AI 摘要
    key_points  JSONB,                  -- AI 要点列表
    sentiment   VARCHAR(10),            -- positive/neutral/negative
    cover_image TEXT,
    published_at TIMESTAMPTZ,
    fetched_at  TIMESTAMPTZ DEFAULT NOW(),
    -- 向量字段(用于语义搜索)
    embedding   vector(768),
    -- 去重标记
    dedup_group VARCHAR(50),
    UNIQUE(feed_id, url)
);

-- 用户阅读行为
CREATE TABLE read_actions (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT REFERENCES users(id),
    article_id  BIGINT REFERENCES articles(id),
    action      VARCHAR(20) NOT NULL,   -- read/like/share/bookmark/skip
    read_progress FLOAT,                -- 阅读进度 0-1
    duration    INT,                    -- 阅读时长(秒)
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 收藏
CREATE TABLE bookmarks (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT REFERENCES users(id),
    article_id  BIGINT REFERENCES articles(id),
    folder      VARCHAR(100),           -- 收藏夹
    note        TEXT,                   -- 批注
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, article_id)
);
```

### 4.2 缓存策略

| 数据类型 | 缓存方案 | TTL |
|---------|---------|-----|
| 用户信息 | Redis Hash | 24h |
| 信息流 | Redis Sorted Set | 5min |
| 文章内容 | Redis String + 本地 SQLite | 1h / 永久(离线) |
| 订阅源列表 | Redis Hash | 10min |
| 热榜 | Redis Sorted Set | 1min |
| AI 摘要 | Redis String | 24h |

---

## 五、核心流程设计

### 5.1 内容抓取与处理流程

```
┌─────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ 定时调度  │───▶│  多源抓取  │───▶│  内容清洗  │───▶│  入库存储  │
│ (Celery) │    │ (Scrapy) │    │ (管道)    │    │ (PG+ES)  │
└─────────┘    └──────────┘    └─────┬────┘    └──────────┘
                                     │
                              ┌──────▼──────┐
                              │  Kafka 消息  │
                              └──────┬──────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
              ┌─────▼─────┐  ┌──────▼──────┐  ┌─────▼─────┐
              │ AI 摘要生成 │  │  智能去重    │  │ 向量索引构建│
              │ (LLM API) │  │ (SimHash+   │  │ (Embedding)│
              │           │  │  语义相似度) │  │           │
              └───────────┘  └─────────────┘  └───────────┘
```

**抓取频率策略：**
- 热门源：每 5 分钟
- 普通源：每 15-30 分钟
- 低频源：每 1-2 小时
- 用户自定义源：可配置

### 5.2 信息流推荐流程

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ 用户行为  │───▶│ 特征提取  │───▶│ 候选召回  │───▶│ 精排打分  │
│ (阅读/点赞│    │ (兴趣标签 │    │ (协同过滤 │    │ (深度学习 │
│  /分享等) │    │  +向量)   │    │  +内容匹配)│    │  排序模型) │
└──────────┘    └──────────┘    └──────────┘    └─────┬────┘
                                                     │
                                              ┌──────▼──────┐
                                              │  去重+多样性  │
                                              │  +打散+插入   │
                                              └──────┬──────┘
                                                     │
                                              ┌──────▼──────┐
                                              │  最终信息流   │
                                              └─────────────┘
```

**推荐策略：**
- 冷启动：基于用户选择的兴趣标签 + 热门内容
- 成长期：内容匹配 + 协同过滤
- 成熟期：深度排序模型 + 实时行为反馈
- **防茧房机制**：每个信息流插入 15% 探索内容（用户兴趣外但高质量）

### 5.3 AI 摘要生成流程

```
用户点击"AI 摘要"
       │
       ▼
  检查缓存(Redis) ──命中──▶ 直接返回
       │ 未命中
       ▼
  文章内容预处理
  - 去除广告/导航等噪音
  - 提取正文段落
  - 截断超长文(上限 8000 tokens)
       │
       ▼
  调用 LLM API
  Prompt: "请用3-5句话总结以下文章的核心内容..."
       │
       ▼
  结果缓存 + 返回展示
```

---

## 六、客户端架构设计

### 6.1 分层架构

```
lib/
├── app/                      # 应用入口与全局配置
│   ├── app.dart
│   ├── router.dart           # go_router 路由配置
│   └── theme.dart            # Material 3 主题
│
├── core/                     # 基础设施层
│   ├── network/              # Dio 网络封装
│   │   ├── api_client.dart
│   │   ├── interceptors.dart
│   │   └── api_result.dart
│   ├── storage/              # 本地存储
│   │   ├── app_database.dart # Drift 数据库
│   │   └── kv_storage.dart   # SharedPreferences
│   ├── ai/                   # AI 能力封装
│   │   ├── summary_provider.dart
│   │   ├── translation_provider.dart
│   │   └── chat_provider.dart
│   └── utils/
│
├── features/                 # 功能模块(按 Feature 组织)
│   ├── feed/                 # 信息流
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   ├── widgets/
│   │   │   └── controllers/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   └── domain/
│   │       ├── entities/
│   │       └── usecases/
│   │
│   ├── reader/               # 阅读器
│   ├── subscription/         # 订阅管理
│   ├── search/               # 搜索
│   ├── bookmark/             # 收藏
│   ├── ai_chat/              # AI 对话
│   └── profile/              # 个人中心
│
├── shared/                   # 跨模块共享
│   ├── widgets/
│   └── models/
│
└── main.dart
```

### 6.2 状态管理设计

```dart
// 以信息流为例的 Riverpod 设计

// 1. 数据源 Provider
@riverpod
FeedApiClient feedApiClient(Ref ref) => FeedApiClient();

// 2. Repository Provider
@riverpod
FeedRepository feedRepository(Ref ref) => FeedRepository(ref.watch(feedApiClientProvider));

// 3. UseCase Provider
@riverpod
GetFeedArticles getFeedArticles(Ref ref) => GetFeedArticles(ref.watch(feedRepositoryProvider));

// 4. Controller (AsyncNotifier)
@riverpod
class FeedController extends _$FeedController {
  @override
  FutureOr<List<Article>> build() => _loadArticles();

  Future<List<Article>> _loadArticles() {
    final useCase = ref.read(getFeedArticlesProvider);
    return useCase.execute(page: 1, pageSize: 20);
  }

  Future<void> loadMore() async { ... }
  Future<void> refresh() async { ... }
  Future<void> likeArticle(String articleId) async { ... }
}
```

### 6.3 离线策略

```
┌──────────────────────────────────────────────┐
│                离线优先策略                     │
├──────────────────────────────────────────────┤
│                                                │
│  读取流程:                                     │
│  本地 SQLite ──有数据──▶ 直接展示(标记离线)     │
│       │ 无数据                                  │
│       ▼                                        │
│  网络请求 ──成功──▶ 展示 + 写入本地              │
│       │ 失败                                   │
│       ▼                                        │
│  展示错误 + 重试按钮                            │
│                                                │
│  写入流程:                                     │
│  先写本地 ──标记待同步──▶ 后台同步到服务端        │
│                                                │
│  预加载策略:                                   │
│  - WiFi 下自动预加载未读文章前 50 篇正文         │
│  - AI 摘要随文章一起缓存                        │
│  - 图片按质量压缩后缓存                         │
└──────────────────────────────────────────────┘
```

---

## 七、服务端架构设计

### 7.1 微服务划分

```
┌─────────────────────────────────────────────────────┐
│                    API Gateway                        │
│                   (Kong / Nginx)                      │
└──┬──────┬──────┬──────┬──────┬──────┬──────┬────────┘
   │      │      │      │      │      │      │
   ▼      ▼      ▼      ▼      ▼      ▼      ▼
┌─────┐┌─────┐┌─────┐┌─────┐┌─────┐┌─────┐┌─────┐
│用户  ││内容  ││订阅  ││推荐  ││搜索  ││AI   ││爬虫  │
│服务  ││服务  ││服务  ││服务  ││服务  ││服务  ││调度  │
│(Go) ││(Go) ││(Go) ││(Go) ││(Go) ││(Py) ││(Py) │
└─────┘└─────┘└─────┘└─────┘└─────┘└─────┘└─────┘
   │      │      │      │      │      │      │
   └──────┴──────┴──────┴──────┴──────┴──────┘
                        │
              ┌─────────┼─────────┐
              ▼         ▼         ▼
         PostgreSQL   Redis    Elasticsearch
```

### 7.2 关键接口设计

```
# 信息流
GET    /api/v1/feed/recommend       # 推荐流 (游标分页)
GET    /api/v1/feed/following       # 关注流 (游标分页)
GET    /api/v1/feed/topic/{id}      # 话题流
GET    /api/v1/feed/hot             # 热榜

# 文章
GET    /api/v1/articles/{id}        # 文章详情
POST   /api/v1/articles/{id}/like   # 点赞
POST   /api/v1/articles/{id}/share  # 分享(记录)

# AI 能力
POST   /api/v1/ai/summary           # 生成摘要
POST   /api/v1/ai/translate         # 翻译
POST   /api/v1/ai/chat              # AI 对话
GET    /api/v1/ai/key-points/{id}   # 获取要点

# 订阅
GET    /api/v1/subscriptions        # 订阅列表
POST   /api/v1/subscriptions        # 添加订阅
DELETE /api/v1/subscriptions/{id}   # 取消订阅
POST   /api/v1/subscriptions/import # OPML 导入

# 搜索
GET    /api/v1/search               # 全文搜索
GET    /api/v1/search/suggest       # 搜索建议

# 用户
POST   /api/v1/auth/login           # 登录
POST   /api/v1/auth/register        # 注册
GET    /api/v1/users/profile        # 个人信息
PUT    /api/v1/users/preferences    # 更新偏好
```

---

## 八、性能优化方案

### 8.1 客户端性能

| 优化点 | 方案 |
|--------|------|
| **列表流畅度** | ListView.builder + AutomaticKeepAliveClientMixin 复用 |
| **图片加载** | 渐进式加载 + 缩略图优先 + 内存缓存 LRU |
| **首屏速度** | 骨架屏 + 分页预加载 + 本地缓存优先 |
| **WebView 白屏** | 预创建 WebView 池 + 进度条 |
| **动画性能** | Impeller 引擎 + 避免 setState 大范围重建 |
| **包体积** | Tree Shaking + 按需加载 + 图片资源 CDN |
| **内存占用** | 文章正文分页渲染 + 图片回收 |

### 8.2 服务端性能

| 优化点 | 方案 |
|--------|------|
| **高并发读** | Redis 多级缓存 + CDN 静态资源 |
| **数据库查询** | 读写分离 + 索引优化 + 慢查询监控 |
| **AI 调用延迟** | 异步处理 + 结果缓存 + 流式返回(SSE) |
| **爬虫效率** | 增量抓取 + 并发控制 + 代理池 |
| **搜索性能** | ES 索引优化 + 向量检索 HNSW 算法 |

---

## 九、安全与隐私

| 领域 | 措施 |
|------|------|
| **传输安全** | 全站 HTTPS + 证书固定(Certificate Pinning) |
| **数据加密** | 敏感字段 AES-256 加密存储 |
| **认证鉴权** | JWT + Refresh Token + OAuth2.0 第三方登录 |
| **隐私保护** | 阅读数据本地优先、可选云端同步、支持数据导出与删除 |
| **爬虫合规** | 遵守 robots.txt、频率限制、仅抓取公开内容 |
| **内容安全** | 敏感词过滤 + AI 内容审核 |

---

## 十、项目规划

### 10.1 里程碑

| 阶段 | 周期 | 交付物 |
|------|------|--------|
| **MVP** | 6 周 | RSS 订阅 + 信息流 + 基础阅读 + AI 摘要 |
| **V1.0** | 4 周 | 推荐系统 + 搜索 + 收藏 + 稍后阅读 |
| **V1.5** | 3 周 | 社交媒体源 + AI 翻译 + 对话问答 |
| **V2.0** | 4 周 | 智能去重 + 热榜 + 阅读统计 + 主题定制 |

### 10.2 MVP 阶段详细排期

| 周 | 任务 |
|----|------|
| W1 | 客户端框架搭建 + 服务端基础架构 + 数据库设计 |
| W2 | RSS 抓取管道 + 内容清洗 + 文章入库 |
| W3 | 信息流页面 + 阅读页面 + 订阅管理页面 |
| W4 | AI 摘要集成 + 缓存策略 + 离线支持 |
| W5 | 用户系统 + 收藏 + 稍后阅读 |
| W6 | 联调测试 + 性能优化 + 上线准备 |

### 10.3 团队配置

| 角色 | 人数 | 职责 |
|------|------|------|
| Flutter 开发 | 2 | 客户端全部功能 |
| Go 后端开发 | 2 | 核心服务 + API |
| Python 开发 | 1 | AI 服务 + 爬虫调度 |
| 产品/设计 | 1 | 产品设计 + UI/UX |

---

## 十一、技术风险与应对

| 风险 | 影响 | 应对方案 |
|------|------|---------|
| AI API 成本高 | 运营成本 | 摘要按需生成 + 结果缓存 + 小模型优先 |
| 爬虫被封禁 | 内容缺失 | 代理池 + 频率控制 + 多源冗余 |
| 推荐冷启动 | 用户体验差 | 兴趣标签引导 + 热门内容兜底 |
| WebView 兼容性 | 阅读体验 | 正文提取 + 原生渲染优先，WebView 兜底 |
| 数据合规 | 法律风险 | 仅抓取公开内容 + 用户数据可删除 + 隐私政策 |
