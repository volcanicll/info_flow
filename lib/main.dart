import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // 点击通知栏时，将 payload 路由路径交给 GoRouter 跳转
    NotificationService.onNotificationTap = (route) {
      ref.read(goRouterProvider).push(route);
    };
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
      ),
    );
  }
}
