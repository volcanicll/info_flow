import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:info_flow/core/notifications/signal_dedup.dart';
import 'package:info_flow/core/storage/kv_storage.dart';

/// 本地通知服务：信号/异动主动触达。
///
/// 封装 flutter_local_notifications 的初始化、权限申请与展示。
/// 使用单例插件实例，进程内共享。
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 应用启动时调用；重复调用安全。
  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[Notification] tapped: ${response.payload}');
      },
    );
    // Android 13+ 需要运行时权限；12 及以下自动授予。
    await requestPermissions();
    _initialized = true;
  }

  /// 申请通知权限（Android 13+ / iOS）。
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final impl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (impl == null) return false;
      await impl.requestNotificationsPermission();
      // Android 14+ 精确闹钟权限（信号时效敏感，按需请求）
      await impl.requestExactAlarmsPermission();
      return true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await impl?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  /// 展示一条信号提醒通知。
  Future<void> showSignalAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      1001,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'signal_alerts',
          '信号提醒',
          channelDescription: '庄家雷达/信号中枢发现新信号时提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}

/// 信号通知开关（默认开启，持久化到 SharedPreferences）。
class SignalNotifyPref extends Notifier<bool> {
  static const _key = 'signal_notify_enabled';
  static const _seenKey = 'signal_notify_seen';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_key, value);
  }

  /// 记录一组已通知过的信号指纹，返回其中「新」的信号指纹。
  /// 指纹 = coin|direction|score，用于跨扫描去重，避免重复打扰。
  /// 已见指纹上限 300 条（保留最新）：指纹含长标题，不设上限会随
  /// 使用无限增长（SmartMoneyAlerts 与 BreakoutAlerts 共用本存储）。
  List<String> markSeen(List<String> fingerprints) {
    final prefs = ref.read(sharedPreferencesProvider);
    final seen = prefs.getStringList(_seenKey) ?? <String>[];
    final fresh = diffFreshSignals(fingerprints, seen);
    if (fresh.isNotEmpty) {
      final merged = [...seen, ...fresh];
      prefs.setStringList(_seenKey,
          merged.length > 300 ? merged.sublist(merged.length - 300) : merged);
    }
    return fresh;
  }
}

final signalNotifyPrefProvider =
    NotifierProvider<SignalNotifyPref, bool>(SignalNotifyPref.new);

/// Riverpod provider，便于在 controller 中读取。
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});
