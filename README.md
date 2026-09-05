<div align="center">

# InfoFlow Terminal

**生产级链上区块链信息与情报获取平台**

专注于 **Robinhood · BSC · Base · Solana** 四大链生态，聚合 DexScreener 流动性行情、GoPlus 智能合约貔貅审计、巨鲸聪明钱异动与全天候链上情报。

![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white)
![Chains](https://img.shields.io/badge/Chains-Robinhood%20%7C%20BSC%20%7C%20Base%20%7C%20Solana-success)
![Security](https://img.shields.io/badge/Security-GoPlus%20Audited-blue)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

</div>

## ✨ 核心特性

InfoFlow Terminal 针对链上交易员与 Web3 投研团队打造，分为五大生产级核心支柱：

| 模块 | 功能说明 |
| --- | --- |
| 📡 **多链雷达 (Radar)** | 四链切换 (`Solana`, `Base`, `BSC`, `Robinhood`)，实时追踪 DEX 热门池子、新币启动 (Pump.fun/Virtuals/Four.meme) 及巨鲸大额买卖异动 |
| 📰 **链上情报 (Intel)** | 汇聚 CoinDesk、Decrypt、Blockworks、Foresight News、PANews 及各公链官方博客，自动提取 \$SOL, \$BNB, \$AERO, \$PEPE 等标的，徽章直通详情 |
| 🔍 **代币探测 (Screener)** | 支持输入合约地址 (CA) 或 Symbol 检索任意代币；**GoPlus 深度安全体检**（貔貅检测、买卖税率、丢弃权限、Top 10 大户占比、一键复制 CA 与浏览器直达） |
| 🤖 **投研大脑 (Copilot)** | 结合实时流动性池数据与 GoPlus 审计指标，提供合约风险诊断、生态热点提炼与每日链上 Alpha 播报 |
| 👤 **终端设置 (Terminal)** | 跨链自选池监控、异动主动触达通知、主题模式（浅色/深色杂志风）与偏好设置 |

> 💡 **核心特色 · 链上信号中枢 (Signal Hub)**：每条链上快讯自动识别涉及的代币标的并绑定其实时 DEX 报价与涨跌幅；点击代币徽章一键直达代币探测与安全审计，实现「情报即信号，信号即交易」。

## 🛠 技术栈

- **框架**：[Flutter](https://flutter.dev) / Dart 3.12+
- **状态管理**：[Riverpod](https://riverpod.dev)（`flutter_riverpod` + `riverpod_generator`）
- **路由**：[go_router](https://pub.dev/packages/go_router)
- **数据管道**：
  - [DexScreener API](https://dexscreener.com)：多链实时 DEX 交易对、流动性、24h 交易量与买卖分布
  - [GoPlus Security API](https://gopluslabs.io)：EVM (BSC/Base) & Solana 智能合约貔貅与权限安全审计
  - [Binance API](https://binance.com)：主流现货与合约深度报价
  - Web3 RSS & 链上官方资讯流
- **本地存储**：`shared_preferences`、`path_provider`
- **代码生成**：`build_runner`、`riverpod_generator`

## 📁 平台架构与工程结构

```
lib/
├── main.dart                      # 应用入口
├── app/                           # 应用级配置（路由、设计系统）
│   ├── router.dart                # 五大核心分支路由与深链
│   └── theme.dart                 # 终端杂志风设计系统 (黑白纸感/语义色)
├── core/                          # 核心基础设施
│   ├── network/                   # 网络请求封装 (Dio)
│   ├── notifications/             # 链上异动本地通知服务
│   ├── state/                     # 全局共享状态 (缓存/自选池)
│   └── storage/                   # 本地键值存储
└── features/                      # 业务模块
    ├── onchain_radar/             # 多链雷达 (Solana/Base/BSC/Robinhood)
    ├── token_screener/            # 代币探测器与 GoPlus 安全审计引擎
    ├── signal_hub/                # 标的词典与情报徽章中枢 (Pulse)
    ├── feed/                      # Web3 链上情报流
    ├── ai_chat/                   # 链上 AI 投研助手
    ├── bookmark/                  # 自选池与稍后阅读
    └── profile/                   # 终端偏好与数据源设置
```

## 🚀 快速开始

### 运行环境

- Flutter SDK ≥ 3.12
- Dart SDK ≥ 3.12

### 安装与运行

```bash
# 1. 安装依赖
flutter pub get

# 2. 生成代码（Riverpod 代码生成）
dart run build_runner build --delete-conflicting-outputs

# 3. 运行测试
flutter test

# 4. 启动应用
flutter run
```

## 📄 开源协议

本项目基于 [MIT License](./LICENSE) 开源。
