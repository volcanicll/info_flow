# AGENTS.md — AI Agent 开发指南

面向在本仓库工作的 AI 编码代理（ZCode / Claude Code / Codex 等）。
目标：让 agent 在不熟悉项目的情况下，第一次就改对地方、用对命令、过得了验证。

## 项目一句话

InfoFlow Terminal：Flutter 构建的链上情报终端。聪明钱实盘 tape（robinhoodtrenches.com）
+ 编辑部杂志风情报流（RSS / NewsNow 快讯 / SoPilot 起爆帖）+ 代币安全探测（GoPlus）
+ 后台告警推送。移动优先（Android 为主），中文 UI。

## 常用命令

```bash
flutter pub get                                          # 依赖
dart run build_runner build --delete-conflicting-outputs  # codegen（riverpod/kv_storage）
flutter analyze                                          # 静态检查（基线 0 error）
flutter test                                             # 全量测试（当前 173 项全绿）
flutter run -d emulator-5554                             # 连模拟器开发（r 热重载 / R 热重启）
flutter build apk --release                              # 出包（build/app/outputs/flutter-apk/）
```

- **改了 `@riverpod` 类/新增 provider 才需要 build_runner**；给已有类加方法/字段不用。
- 提交前必须：`flutter analyze` 0 error + `flutter test` 全绿。
- 已有测试套件在 `test/`，与 `lib/` 镜像；新逻辑请带测试（纯函数优先，见
  `test/notifications/signal_dedup_test.dart`、`test/feed/newsnow_repository_test.dart` 的风格）。

## 版本管理（SemVer，发布时必读）

版本号格式 `MAJOR.MINOR.PATCH+BUILD`（`pubspec.yaml` 的 `version` 字段，
如 `2.2.0+3`）。**按本次变更的内容与功能定级，不按提交次数或主观感觉**：

| 段位 | 何时递增 | 本仓库示例 |
|---|---|---|
| MAJOR | 破坏性变更：数据/配置不兼容迁移、面向用户的能力被移除、架构级重写 | 1.x → 2.0.0（链上版重写） |
| MINOR | **新增任何面向用户的功能/模块**（哪怕很小） | 2.1.0（价格提醒）→ 2.2.0（通知中心 + 全列表分页） |
| PATCH | 仅缺陷修复、文案/样式微调，无任何新功能 | 2.2.1（修崩溃/显示错误） |
| +BUILD | 每次发布 +1，与用户可见版本无关（Android versionCode） | 2.2.0+3 → 2.2.0+4 |

- 判定口诀：**有新功能就 MINOR，只有修复就 PATCH，兼容性破坏才 MAJOR**；
  拿不准时倾向 MINOR（用户可感知即 MINOR）。一次发布含多类变更时，
  按其中最高级别取，不叠加跳级。
- 版本号只在发布提交（`docs(release)`）里变更；日常功能/修复提交不动它。
- 发布配套（缺一不可，顺序执行）：
  1. `CHANGELOG.md` 顶部新增 `[x.y.z] - 日期` 条目（Keep a Changelog 格式，
     分 Added / Changed / Fixed / Notes）
  2. `pubspec.yaml` 版本号 + build 号
  3. README 徽章/测试计数等引用同步
  4. 门禁：`flutter analyze` 0 error + `flutter test` 全绿 +
     `flutter build apk --release` 出包验证
  5. `docs(release): vX.Y.Z …` 提交 + `git tag vX.Y.Z`
  6. 推送 master 与 tag，`gh release create vX.Y.Z`（说明沿用 CHANGELOG 内容）

## 架构速览

```
lib/
├── app/            router.dart（go_router 五分支）· theme.dart（设计系统，唯一取色处）
├── core/           network(Dio+异常映射) · notifications(通知+指纹去重) · state(共享store) · storage(KV)
├── shared/widgets/ 发丝线/骨架屏/按压缩放/空态等通用件
└── features/
    ├── smart_money/   首页终端：rht_api(×9端点)+WS韧性流+共振+跟单链+榜单+后台告警
    ├── feed/          情报流：rss ×16源 · newsnow_repository(快讯+破圈) · SoPilot 起爆帖
    ├── signal_hub/    ticker 词典与标注（情报→代币的桥梁）
    ├── token_screener/ 代币探测 + GoPlus 审计
    ├── crypto_radar/  庄家雷达 · market/ 行情与币详情 · ai_chat/ 投研大脑
    ├── subscription/  订阅管理(OPML) · reader/ · bookmark/ · search/ · profile/
```

依赖方向：`features/* → core/`、`features/feed ↔ signal_hub`（ticker 标注）；
页面间跳转一律 `context.push('/route')`（见 router.dart），不直接 new 页面。

## 设计系统（改 UI 前必读）

`theme.dart` 是唯一取色处：`context.colors.xxx`（AppColors ThemeExtension），
**禁止硬编码颜色**。语义：paper(纸底)/surface(卡面)/surface2/tint、ink/t2/t3(文字三级)、
hairline/hairlineStrong(发丝线)、accent(编辑红=唯一强调色)、up/down(涨跌)、warn、radar(紫=仅雷达信号)。

- 卡片**无阴影无大圆角**：radius 2–4px，用发丝线分隔（「用线不用影」）
- 标题衬线（theme.textTheme.displayXxx/headlineXxx 已配置 Noto Serif SC）；
  数字一律 `AppTheme.mono(...)` + tabular-nums；kicker 小标签全大写大字距
- 行情/榜单：数字右对齐、标签左对齐；空态文案一句话（`_TeaserPlaceholder` 风格）
- 新功能默认安静：空态/无命中不堆砌视觉噪音

## 外部数据源要点

| 源 | 文件 | 坑 |
|---|---|---|
| robinhoodtrenches.com | `smart_money/data/datasources/rht_api.dart` | 9 个端点 + `/ws`；WS 4s 超时降级 2.5s 轮询（复刻上游策略，勿改）；`overview/traders/...` 支持 window=1h/24h/7d/30d/all；tape 行含 `is_stock`；字段可空极多（一律走 `RhtNum` 安全转换） |
| NewsNow | `feed/data/newsnow_repository.dart` | 公共实例 `newsnow.busiyi.world/api/s?id=`，服务端缓存 ~30min；**cls 响应含未转义控制字符**（先清洗再 jsonDecode）；日期三处：`pubDate`/`extra.date`/`date`（ms 或 ISO）；微博/知乎条目无日期；改解析必须跑 `test/feed/newsnow_repository_test.dart` |
| SoPilot | `feed/data/rss_sources.dart` | `https://sopilot.net/rss/hottweets`（Web3 起爆帖，约 30min 更新，无 JSON API） |
| OpenCode Go | `ai_chat/data/ai_config.dart` · `ai_service.dart` · `ai_models.dart` | 官方云端网关 `https://opencode.ai/zen/go/v1`（OpenAI 兼容 chat/completions）；官方要求自报 UA + 每会话稳定 `x-opencode-session` 头（`AiConfig.opencodeSessionId()`）；**免费档模型仅限 opencode 客户端内使用（403）**，外部客户端需 Go 订阅 key；模型列表走 `GET /models`；桌面本地网关（magpie 127.0.0.1:3425/v1）仅限本机客户端，App 不可直连 |
| GoPlus / DexScreener / Binance | `token_screener/`、`market/`、`crypto_radar/` | 免 key，注意限流（已有轮询间隔勿调小） |

后台告警（`@Riverpod(keepAlive: true)` + Timer，`main.dart` initState 激活）：
`SmartMoneyAlerts`（60s tape 增量）、`BreakoutAlerts`（10min 热榜扫描）与
`PriceAlerts`（60s 批量拉现价核对价格提醒规则）共用 `SignalNotifyPref.markSeen`
指纹去重（上限 300 条，价格分区 `pa`），受 `signalNotifyPrefProvider` 总开关约束；
**首轮扫描只建基线不推送**（PriceAlerts 规则是显式阈值、无基线问题，启动 5s 后
即可补推停机期间命中的条件）。新告警源照此模式加。
Binance 现货行情统一走官方公共镜像 `data-api.binance.vision`（路径/响应与
`api.binance.com` 完全一致，后者在部分地区/网络被阻——本仓库开发环境实测如此）。
通知 `payload` 契约：只能传「`/` 开头的应用内路由」或「网页 URL」——URL 由
`main.dart` 点击回调交系统浏览器，路由经 `notificationRoute` 归一后 `push`；
勿传其他格式（否则点击通知会落进 404 页）。

## 已知坑（本仓库实测）

1. **feed 分页**：`FeedController.loadMore` 取重排后前 N 条（不是偏移切片）——
   新批次里更新的条目要能出现在顶部，改回偏移切片会让新条目永远不可见。
2. **底部弹层**：带 `transform` 的绝对定位子元素不能直接挂在 flex 容器下
   （Chromium/Web 端会把屏幕顶出视口），Flutter 端无此问题。
3. **riverpod 3 约束**：`build()` 返回后才能写 state，连接/首拉用
   `Future.microtask` 推迟一拍（见 SmartMoney.build）。
4. **live 测试**：`test/smart_money/live_api_smoke_test.dart` 打真实网络，
   离线时会失败属预期；e2e（`test/e2e/app_flow_test.dart`）只断言静态结构，
   首屏外内容先 `scrollUntilVisible` 再 expect（ListView 懒构建）。

## 验证工作流（改完代码后）

1. `flutter analyze` → 0 error
2. `flutter test` → 全绿
3. 模拟器冒烟：`flutter run -d emulator-5554`，adb 截图核对关键页面：
   `adb exec-out screencap -p > shot.png`（截图为 1080×2400，Read 显示时 ≈900×2000，
   **点按坐标按真实分辨率换算**，底栏 tab y≈2255、x≈108/324/540/756/972）
4. 模拟器相关：`adb shell cmd uimode night yes/no` 切深浅主题；
   Flutter 文本对 uiautomator 不可见（无语义树），定位用截图换算；
   `input tap` 对 Flutter 底栏 y 公差约 ±10px，命中失败先微调 y。
