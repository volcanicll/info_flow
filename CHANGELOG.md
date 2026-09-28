# Changelog

本文件记录 InfoFlow Terminal 的版本发布历史。格式参考
[Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [2.2.0] - 2026-09-28

大厂级产品打磨专项：修复硬伤、补齐状态组件层、统一交互反馈与设计系统执行，
并为全部主列表接入触底分页。

### Added

- **应用内通知中心（真实收件箱）**：后台告警触发系统通知的同时落一份到
  应用内收件箱（持久化，上限 50 条、同题同文去重、坏数据容错）；
  报头铃铛带未读红点，弹层支持点击条目按 payload 契约直达路由/网页、
  清空收件箱，关闭即清未读（`core/notifications/alert_inbox.dart`，含单测）
- **列表触底分页**：情报流 / 代币探测 / 搜索结果 / 聪明钱大户榜 / 平仓 /
  跟单链 / 代币动向全部接入「加载更多 spinner + 已经到底了」页脚模式；
  探测/搜索为本地窗口渐进渲染，聪明钱各榜 15s 轮询换列表实例不重置窗口
  （收缩才收敛，保住滚动位置）；页脚提取为共享组件 `LoadMoreFooter`（含单测）
- **AI 回复失败兜底与重试**：`send()` 全程异常兜底，失败出错误气泡、
  点击整条重试，输入框与「正在思考…」不再永久卡死
- **市场总览进入即自动加载**，首拉展示与探测页同构的骨架屏
  （情绪条 + 行情行灰面）；币详情拉取完成但无行情时展示
  「暂无行情数据 + 重新加载」，不再落回「--」占位
- **复制链接**：文章操作栏的「评论（即将上线）」假功能替换为可用的
  复制链接（带触觉与 SnackBar 反馈）
- **收藏左滑撤销**：移除收藏/移出稍后读后 3.2s 内可撤销
- 共享脉冲骨架组件 `SkeletonBox`：情报流目录行、探测结果卡、
  币详情首屏、聪明钱持仓区块的加载态统一为呼吸动画灰面

### Changed

- **交互反馈对齐大厂手感**：触觉反馈从 7 处扩到 20+（底栏 Tab、五处下拉
  刷新、AI 发送、分享、全部已读、订阅切换、主题/提醒切换等）；约 15 处
  裸 GestureDetector 全部接上 `PressScale` 按压缩放（并支持 behavior 透传）
- **币详情实时性**：补下拉刷新 + 60s 静默轮询，刷新按钮不再被 spinner 顶掉
- **底部弹层全站统一**：theme 级 `bottomSheetTheme`（纸底 + 拖拽把手 +
  10px 顶角）覆盖 17 处弹层，替换 M3 默认 28px
- **设计系统执行**：清除全部越界硬编码色（domain 层 Tailwind 风险色 →
  主题语义色、`Colors.grey/white/white10` → `context.colors` 等）、
  圆角收敛（pill 999 / 卡片 2–4px）、四处文字溢出加 ellipsis/Flexible、
  rss_sources 品牌色与 `ChainColors` 去重、阅读器纸色引用主题常量
- **空态引导**：收藏页「去情报流逛逛」、搜索无结果「清除重搜」、
  聪明钱共振/破圈区块错误态行内「重试」
- 市场总览微价币（PEPE 类）价格格式化保留有效位，不再显示 `0.00000`

### Fixed

- 探测页搜索清除按钮从不出现（`suffixIcon` 依赖输入文本但缺 listener）
- 情报流加载更多页脚假转圈（与真实加载态无关），改为响应式加载指示
- `router_404_test` 因骨架屏无限脉冲动画 `pumpAndSettle` 超时，
  改为固定帧推进

### Notes

- 测试 162 → 173 项；`flutter analyze` 保持 0 error 基线
- 通知中心 payload 复用通知契约：仅「/ 开头的应用内路由」或「网页 URL」

## [2.1.0] - 2026-09-28

### Added

- **代币价格监控与提醒**：按「涨破 / 跌破指定价」或「自基线涨跌幅 ≥ X%」监控
  代币现价，后台 60s 批量轮询 Binance 现货核对，命中即系统通知
  （独立「价格提醒」渠道），点击通知直达币种详情
  （`/price-alerts` 管理页 · 币详情页铃铛直达 · 规则持久化 ·
  触发一次自动停用可重新启用 · 通知指纹含代数防重复推送）
- **AI 投研大脑支持 OpenCode Go 官方接入**：直连官方云端网关
  `opencode.ai/zen/go/v1`（OpenAI 兼容），按官方客户端要求携带自报
  User-Agent 与稳定 `x-opencode-session` 会话头；AI 设置支持
  OpenAI 兼容 / OpenCode Go 双接入方式切换（智能回填各默认值）
- AI 设置新增「获取模型列表」：从任意 OpenAI 兼容网关的 `/models`
  拉取模型目录点选回填（OpenCode Go 网关 40+ 模型实测可用）
- Profile 页新增「代币价格提醒」入口；AI 助手报头 kicker 随接入方式变化

### Changed

- Binance 现货行情统一切换至官方公共镜像 `data-api.binance.vision`
  （路径/响应与 api.binance.com 完全一致；后者在部分地区/网络被阻，
  本仓库开发环境实测如此，切换后「基准市场总览」在网络受限环境恢复可用）
- 后台告警体系新增 `PriceAlerts` 引擎（60s 轮询，`pa` 指纹分区）

### Fixed

- AI 请求 baseUrl 尾部斜杠归一化，避免拼接出 `…/v1//chat/completions`

### Notes

- OpenCode Go 免费档（Zen free）模型仅限 opencode 官方客户端内使用，
  外部客户端接入需 Go 订阅 API Key（`opencode.ai/auth` 获取）
- 价格提醒行情源为 Binance 现货，仅支持已上架币种，创建规则时即校验

## [2.0.0] - 2026-09（On-Chain Edition）

生产级链上版：聪明钱实盘终端（robinhoodtrenches.com tape + WS 韧性流 +
三源共振 + 抱团跟单链 + 大户榜 + 庄家雷达）、编辑部杂志风链上情报流
（16 个专业源 + NewsNow 快讯 + SoPilot 起爆帖 + ticker 标注）、代币探测
与 GoPlus 安全审计、破圈雷达、聪明钱/破圈后台告警推送、「纸上终端」
设计系统双主题。
