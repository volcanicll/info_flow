<div align="center">

# InfoFlow

**AI 驱动的信息聚合 App**

一站式聚合 RSS 订阅、智能阅读、AI 对话与加密市场雷达的跨端 Flutter 应用。

![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

</div>

## ✨ 功能特性

InfoFlow 采用 Feature 分层架构，各模块职责清晰、状态全局联动：

| 模块 | 说明 |
| --- | --- |
| 📡 **脉搏（Pulse）** | 信息+市场异动交织的实时时间线，资讯自动识别标的并展示实时行情徽章（信号中枢 P0） |
| 📰 **信息流** | 接入真实 RSS 数据源，支持分类切换、下拉刷新、文章卡片交互 |
| 📖 **阅读器** | WebView 加载文章原文，自动标记已读、累计阅读统计 |
| 🔖 **收藏** | 收藏 / 稍后阅读持久化存储，与信息流状态实时联动 |
| 🔍 **搜索** | 基于已抓取文章池的全文检索，关键词高亮、搜索历史持久化 |
| 🤖 **AI 助手** | 本地规则引擎 + 可选 LLM API（OpenAI 兼容接口），智能问答与摘要 |
| 📚 **订阅** | RSS 源管理，按分类浏览与订阅 |
| 📡 **加密雷达** | 庄家雷达模块，对接 Binance API，提供持仓量（OI）异动监控、资金池与交易信号 |
| 👤 **个人中心** | 阅读统计、深色模式、字号调节等个性化设置 |

> 💡 **核心特色 · 信号中枢（Signal Hub）**：把资讯与市场异动首次缝合——每条新闻自动识别涉及的标的（加密/贵金属），并展示实时行情徽章。「信息即信号」，让每条资讯带着它的市场身份证。完整方案见 [设计文档](docs/superpowers/specs/2026-07-01-signal-hub-design.md)。

## 🛠 技术栈

- **框架**：[Flutter](https://flutter.dev) / Dart 3.12+
- **状态管理**：[Riverpod](https://riverpod.dev)（`flutter_riverpod` + `riverpod_generator` 代码生成）
- **路由**：[go_router](https://pub.dev/packages/go_router)
- **网络**：[dio](https://pub.dev/packages/dio)、`html`、`xml`
- **本地存储**：`shared_preferences`、`path_provider`
- **UI 组件**：`cached_network_image`、`shimmer`、`pull_down_button`、`flutter_spinkit`
- **代码生成**：`build_runner`、`freezed`、`json_serializable`
- **其他**：`webview_flutter`、`url_launcher`、`share_plus`、`connectivity_plus`、`logger`

## 📁 项目结构

```
lib/
├── main.dart                # 应用入口
├── app/                     # 应用级配置（路由、主题）
│   ├── router.dart
│   └── theme.dart
├── core/                    # 核心基础设施
│   ├── network/             # 网络请求封装
│   ├── state/               # 跨页面共享状态（收藏、统计、AI 配置）
│   └── storage/             # 本地存储封装
├── shared/                  # 跨模块共享组件
│   └── widgets/
└── features/                # 业务功能模块（按 Feature 切分）
    ├── feed/                # 信息流
    ├── reader/              # 阅读器
    ├── bookmark/            # 收藏
    ├── search/              # 搜索
    ├── ai_chat/             # AI 助手
    ├── subscription/        # 订阅
    ├── crypto_radar/        # 加密雷达
    └── profile/             # 个人中心
```

每个 `features` 模块内部遵循 `data / domain / presentation` 分层，便于独立开发与测试。

## 🚀 快速开始

### 环境要求

- Flutter SDK ≥ 3.12
- Dart SDK ≥ 3.12
- Android Studio / Xcode（用于移动端构建）

### 安装与运行

```bash
# 1. 克隆仓库
git clone https://github.com/volcanicll/info_flow.git
cd info_flow

# 2. 安装依赖
flutter pub get

# 3. 生成代码（Riverpod / Freezed / JSON 序列化）
dart run build_runner build --delete-conflicting-outputs

# 4. 运行
flutter run
```

### 构建 Release 包

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 📄 开源协议

本项目基于 [MIT License](./LICENSE) 开源，版权所有 © 2026 volcanic。
