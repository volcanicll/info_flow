import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme.dart';
import 'app/router.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/kv_storage.dart';
import 'features/smart_money/data/smart_money_alerts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 预加载 SharedPreferences，通过 override 注入，全部 store 同步读取初始值
  final prefs = await SharedPreferences.getInstance();

  // 初始化本地通知（信号/异动主动触达），失败不阻塞启动
  await NotificationService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
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
    // 启动聪明钱后台告警轮询（keepAlive，60s 增量拉 tape）
    ref.read(smartMoneyAlertsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'InfoFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
