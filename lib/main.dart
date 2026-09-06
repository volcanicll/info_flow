import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app/theme.dart';
import 'app/router.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/kv_storage.dart';
import 'features/feed/data/breakout_alerts.dart';
import 'features/smart_money/data/smart_money_alerts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局错误边界：捕获 Widget build 异常与异步未处理异常，防止红屏
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error\n$stack');
    return true;
  };

  // 预加载 SharedPreferences，通过 override 注入，全部 store 同步读取初始值
  final prefs = await SharedPreferences.getInstance();

  // 初始化本地通知（信号/异动主动触达），失败不阻塞启动
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('[Notification] init failed: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const InfoFlowApp(),
  ));
}

class InfoFlowApp extends ConsumerStatefulWidget {
  const InfoFlowApp({super.key});

  @override
  ConsumerState<InfoFlowApp> createState() => _InfoFlowAppState();
}

class _InfoFlowAppState extends ConsumerState<InfoFlowApp> {
  @override
  void initState() {
    super.initState();
    // 启动后台告警轮询（keepAlive）：
    // 聪明钱 60s 增量拉 tape；破圈雷达 10min 扫大众热榜
    ref.read(smartMoneyAlertsProvider);
    ref.read(breakoutAlertsProvider);

    // 点击通知栏时按 payload 契约分发：网页链接交系统浏览器，
    // 应用内路由（归一为 / 开头）交 GoRouter push
    NotificationService.onNotificationTap = (payload) {
      final url = notificationExternalUrl(payload);
      if (url != null) {
        unawaited(_openExternalUrl(url));
        return;
      }
      final route = notificationRoute(payload);
      if (route != null) {
        ref.read(goRouterProvider).push(route);
      }
    };
  }

  /// 系统浏览器打开网页链接；失败只记日志，不影响前台。
  Future<void> _openExternalUrl(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[Notification] open url failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // 根据当前主题动态设置状态栏图标亮度
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MaterialApp.router(
        title: 'InfoFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) {
          return MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.3,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
