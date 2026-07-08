# InfoFlow · 信息流增量加载设计

> 日期：2026-07-08
> 目标：解决 RSS 订阅源全部一次性加载的性能与体验问题
> 状态：已实现
> 范围：FeedController / FeedPage

---

## 一、问题

### 1.1 现状

信息流页面在 `FeedController._loadArticles()` 中一次性并发了全部 RSS 源（推荐页 18 个源，最多 180 篇文章）。加载完成后才显示第一页，后续 `loadMore()` 仅从已加载的全量内存数据切片，没有真正的新增数据到达。

两个具体问题：

| 问题 | 表现 | 根因 |
|------|------|------|
| 首次加载慢 | 等待所有源抓完才显示内容 | 18 个源串行分批（每批 3 个），最慢的源决定首屏时间 |
| 加载指示器卡死 | 底部 spinner 一直转，数据不再增加 | `ListView.itemCount = articles.length + 1` 恒多一个，`loadMore()` 无数据时静默返回 |

### 1.2 约束

- RSS 协议**不支持服务端分页**（每个源返回该源的全部最新文章，无法传 `?page=N`）
- 订阅源数量固定（推荐 18、热榜 6、关注取决于用户订阅数）
- 每个源限 `maxItems=10`，全量数据上限可控

---

## 二、方案：分批增量抓取

### 2.1 核心思路

将「一次性抓完所有源再分页展示」改为 **「首次抓取少量源 + 滚动到底部时抓取下一批」**。

```
之前：
  _loadArticles() → fetch ALL 18 sources → List<Article>(~180)
    → slice page 1 (12) → display
    → loadMore() → slice page 2 from same ~180 → display
    → loadMore() → slice page 3 → ...（无新增网络请求）

之后：
  _loadArticles() → fetch 3 sources → List<Article>(~30)
    → slice page 1 (12) → display
    → loadMore() → slice next 12 from ~30 → display
    → loadMore() → current >= _all → fetch next 3 sources → merge + sort
    → slice next 12 → display
    → ...（滚动到底即触发网络请求）
```

### 2.2 状态变化

| 字段 | 类型 | 说明 |
|------|------|------|
| `_sourceQueue` | `List<RssSource>` | 待抓取的源队列，按优先级排序 |
| `_sourceCursor` | `int` | 已抓取的源数量（指向队列中下一个要抓的源） |
| `_seenUrls` | `Set<String>` | 累积去重集合，跨批次共享 |
| `_all` | `List<Article>` | 已抓取的全部文章，每次新批次后追加 + 全量排序 |
| `_hasMore` | `bool` | 是否有更多数据（源队列未耗尽 or 数据未展示完） |
| `hasMore` | `bool` (getter) | 公开属性，供 UI 控制 loading indicator 显隐 |

### 2.3 抓取流程

```
loadArticles()
  ├── _sourceQueue = _sourcesForType(type)
  ├── _sourceCursor = 0
  ├── _fetchNextBatch(3)        ← 首次抓 3 个源
  │     ├── fetchSource × 3 (并行)
  │     ├── seenUrls 去重 → _all.addAll
  │     ├── TickerResolver 注入
  │     └── _all.sort(by publishedAt)
  └── return _paginate(_all, 1)

loadMore()
  ├── if current.length >= _all.length
  │     ├── if _sourceCursor >= _sourceQueue.length → _hasMore = false
  │     └── _fetchNextBatch(3)  ← 滚动到底触发
  ├── sublist(current.length, +pageSize) → more
  └── state = [...current, ...more]
```

### 2.4 UI 配合

`feed_page.dart` 中：

```dart
// 不再固定 +1
itemCount: articles.length + (notifier.hasMore ? 1 : 0),
```

- `_hasMore = false` 时底部不留空白，不再显示 spinner
- `_hasMore` 在每个 `loadMore()` 结束时如有变化即 `state = AsyncData([...current])` 触发重建

### 2.5 边界处理

| 场景 | 处理 |
|------|------|
| 所有源首次抓取全部失败 | 抛出异常，UI 显示错误页 + 重试按钮 |
| 部分源失败 | 静默跳过（`failedCount` 递增），有数据的源正常展示 |
| 首屏数据不足一页（≤12 条） | `_hasMore = false`，不显示 spinner |
| 刷新（下拉） | 重置 `_sourceCursor`、`_seenUrls`，重新抓取首批 |
| 最后一批数据恰好不满一页 | `more` 为空时设 `_hasMore = false`，通知 UI |

---

## 三、效果对比

| 指标 | 改造前 | 改造后 |
|------|--------|--------|
| 首屏时间（推荐页） | 等待全部 18 个源（最慢者决定） | 等待前 3 个源（≈之前的 1/6） |
| 网络请求总量 | 不变（全量） | 不变（全量） |
| 请求时间分布 | 集中 | 分散到用户滚动操作中 |
| spinner 停转 | 永不（bug） | 无数据时自动隐藏 |
| 增量加载感 | 无 | 有（每次触发新网络请求） |

---

## 四、YAGNI

- 不做服务端分页（依赖 RSS 协议升级，短期不可行）
- 不做虚拟列表（文章数上限 ≈ 180，不需要）
- 不做预加载（用户翻到底再抓，避免浪费流量）
