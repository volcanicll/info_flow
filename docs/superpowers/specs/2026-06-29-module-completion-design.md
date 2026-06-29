# 各模块功能完善设计

> 日期：2026-06-29
> 目标：把 InfoFlow 各模块从桩代码/mock 状态改造为真实可用功能。

## 背景

当前 App 已接入真实 RSS 数据源并完成 UI 美化，但多个功能模块仍是写死数据或空操作：

| 模块 | 现状 | 问题 |
|---|---|---|
| Reader 阅读器 | 写死的 GPT-5 mock 内容 | 不读真实文章、收藏/翻译空操作 |
| Bookmark 收藏 | 5 条写死数据 | 与 feed 收藏状态脱节、不持久化 |
| Search 搜索 | 假结果"搜索结果1~5" | 不搜索真实文章 |
| AI Chat | 1秒后返回写死回复 | 无真实交互逻辑 |
| Profile 我的 | 统计写死、深色模式开关无效 | 设置无实际功能 |
| Feed 卡片交互 | 点赞/收藏按钮 `onTap: () {}` | 不联动状态 |

## 需求边界（用户确认）

- **AI 功能**：本地规则版 + 预留 LLM API key 升级入口
- **必做**：收藏持久化、深色模式真实切换、状态全局联动、真实搜索
- **阅读器**：WebView 加载文章原文

## 架构方案

采用「状态层下沉到共享 provider，复用现有基础设施」。

### 新增共享状态层 `lib/core/state/`

所有跨页面状态集中管理，各 feature 页面 watch 同一 provider，实现联动：

```
lib/core/state/
├── library_store.dart   # 收藏 / 点赞 / 已读 / 稍后阅读，SharedPreferences 持久化
├── reading_stats.dart   # 阅读统计：文章数、阅读时长、收藏数
└── ai_config.dart       # AI key 配置 + 本地规则引擎开关
```

### 现有可复用基础设施

- `sharedPreferencesProvider`（已存在）
- `ThemeModeNotifier`（已存在，main.dart 已接入，但 Profile 开关未连接）
- `FontSizeNotifier`（已存在，未连接）
- `feedControllerProvider`（已抓取真实文章，可作为搜索/AI 检索的数据源）

## 模块设计

### 1. Reader 阅读器

- 路由 `/reader/:articleId`：feed 页跳转时，把文章存入「文章缓存 provider」（按 id），reader 按 id 取真实文章
- 顶栏标题/来源/时间/头像用真实文章数据
- **正文用 `webview_flutter` 加载 `article.url`**：顶部进度条 + 加载失败重试 + 在浏览器打开兜底
- AI 摘要底部 sheet：有 RSS summary 展示 summary + keyPoints，无则提示「该源未提供摘要」
- 收藏按钮接入 `libraryStoreProvider`；分享用 `share_plus` 分享真实 url
- 进入页面自动标记已读 + 累计阅读统计

### 2. Bookmark 收藏

- 监听 `libraryStoreProvider.bookmarks`（持久化的真实收藏）
- 三个 tab：全部 / 文章 / 稍后阅读
- 复用 ArticleCard 展示，点击进 reader
- 取消收藏即时更新；空状态引导去订阅源

### 3. Search 搜索

- 输入关键词后，在 feed controller 缓存的文章池中按 标题/摘要/来源 全文匹配
- 结果高亮关键词，显示来源与时间，点击进 reader
- 搜索历史用 SharedPreferences 持久化（可清空）
- 热门搜索基于实际订阅源名称生成

### 4. AI 助手 Chat

- **本地规则引擎**：按用户提问关键词从已抓取文章检索组织回复
  - "今日要闻/最新" → 返回最新 N 条标题 + 摘要
  - "推荐订阅源/源" → 返回 RssSources 分类列表
  - 其他 → 关键词匹配相关文章标题
- ⚙️ 设置入口可填 LLM API key（OpenAI 兼容接口）+ base url
- **填了 key → 切换为真实 LLM 调用**（dio 流式/非流式）；无 key 用本地规则
- 打字指示器、错误处理、快捷问题

### 5. Profile 我的

- 阅读统计读 `readingStatsProvider`（真实文章数/时长/收藏数）
- 深色模式：接入 `themeModeNotifierProvider`，三态切换（跟随系统/亮/暗）
- 字体大小：接入 `fontSizeNotifierProvider`（slider，影响 reader 正文）
- 「关于」展示真实版本号、订阅源总数

### 6. Feed 卡片联动

- ArticleCard 点赞/收藏按钮接入全局 provider
- Reader 顶栏收藏按钮与卡片同步

## 数据流

```
用户操作（卡片/阅读器收藏）
        ↓
libraryStoreProvider.toggleBookmark(article)
        ↓ 持久化到 SharedPreferences
        ↓
自动通知所有 watcher:
  - BookmarkPage（收藏列表刷新）
  - FeedPage 卡片（收藏图标刷新）
  - ReaderPage（收藏按钮刷新）
  - ProfilePage（收藏数刷新）
```

## 持久化数据结构

收藏存「文章元数据」（不存全文，节省空间）：

```json
[
  {
    "id": "36kr_xxx",
    "feedId": "36kr",
    "feedName": "36氪",
    "feedColor": 428xxxxxx,
    "title": "...",
    "url": "https://...",
    "summary": "...",
    "coverImageUrl": "https://...",
    "publishedAt": "2026-06-29T10:00:00",
    "bookmarkedAt": "2026-06-29T11:00:00",
    "isReadLater": false
  }
]
```

点赞/已读只存 id 集合（Set<String>）。

## 新增依赖

- `webview_flutter: ^4.10.0`（阅读器正文加载）

## 错误处理

- WebView 加载失败 → 显示重试按钮 + 浏览器打开兜底
- RSS 源无 summary → AI 摘要 sheet 提示
- AI key 无效 → 回退本地规则 + 错误提示
- 搜索无结果 → 空状态

## 测试

- 单元测试：libraryStore 持久化读写、本地规则引擎检索、搜索匹配
- 手动验证：收藏→重启→仍在；深色模式切换生效；搜索真实命中

## 不做（YAGNI）

- 不引入 SQLite（SharedPreferences 足够当前规模）
- 不做 RSS 全文抓取清洗（用 WebView 兜底）
- 不做用户账号系统
- 不做推送通知
