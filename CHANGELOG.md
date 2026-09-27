# Changelog

本文件记录 InfoFlow Terminal 的版本发布历史。格式参考
[Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

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
