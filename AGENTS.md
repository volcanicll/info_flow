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
flutter test                                             # 全量测试（当前 107 项全绿）
flutter run -d emulator-5554                             # 连模拟器开发（r 热重载 / R 热重启）
flutter build apk --release                              # 出包（build/app/outputs/flutter-apk/）
```

- **改了 `@riverpod` 类/新增 provider 才需要 build_runner**；给已有类加方法/字段不用。
- 提交前必须：`flutter analyze` 0 error + `flutter test` 全绿。
- 已有测试套件在 `test/`，与 `lib/` 镜像；新逻辑请带测试（纯函数优先，见
  `test/notifications/signal_dedup_test.dart`、`test/feed/newsnow_repository_test.dart` 的风格）。

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
| GoPlus / DexScreener / Binance | `token_screener/`、`market/`、`crypto_radar/` | 免 key，注意限流（已有轮询间隔勿调小） |

后台告警（`@Riverpod(keepAlive: true)` + Timer，`main.dart` initState 激活）：
`SmartMoneyAlerts`（60s tape 增量）与 `BreakoutAlerts`（10min 热榜扫描）共用
`SignalNotifyPref.markSeen` 指纹去重（上限 300 条），受 `signalNotifyPrefProvider`
总开关约束；**首轮扫描只建基线不推送**。新告警源照此模式加。

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
