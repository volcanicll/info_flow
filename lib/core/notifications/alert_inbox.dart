import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/kv_storage.dart';

/// 应用内告警收件箱：后台告警（聪明钱/破圈/价格提醒）触发系统通知的同时
/// 落一份到应用内，供「通知中心」展示历史记录。
///
/// 纯函数 [mergeAlertInbox] 负责合并/去重/裁剪，便于单测；
/// [AlertInbox] 只做持久化编排（SharedPreferences JSON 串行，上限 50 条）。
class AlertInboxEntry {
  final String id;
  final String kind; // 'signal'（信号提醒）| 'price'（价格提醒）
  final String title;
  final String body;
  final String? payload; // 路由（/ 开头）或网页 URL，同通知 payload 契约
  final DateTime createdAt;
  final bool read;

  const AlertInboxEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.payload,
    required this.createdAt,
    this.read = false,
  });

  AlertInboxEntry copyWith({bool? read}) {
    return AlertInboxEntry(
      id: id,
      kind: kind,
      title: title,
      body: body,
      payload: payload,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind,
        'title': title,
        'body': body,
        if (payload != null) 'payload': payload,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'read': read,
      };

  /// 解码失败返回 null（坏行跳过不炸整个收件箱）。
  static AlertInboxEntry? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final title = json['title'];
    final body = json['body'];
    if (title is! String || body is! String) return null;
    final createdAtMs = json['createdAt'];
    return AlertInboxEntry(
      id: json['id'] is String ? json['id'] as String : '',
      kind: json['kind'] is String ? json['kind'] as String : 'signal',
      title: title,
      body: body,
      payload: json['payload'] is String ? json['payload'] as String : null,
      createdAt: createdAtMs is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
          : DateTime.now(),
      read: json['read'] == true,
    );
  }
}

/// 合并新告警到收件箱头部：与最新一条同题同文的重复告警不重复入箱；
/// 超出 [cap] 时裁掉最旧条目。
List<AlertInboxEntry> mergeAlertInbox(
  List<AlertInboxEntry> existing,
  AlertInboxEntry entry, {
  int cap = 50,
}) {
  final first = existing.isEmpty ? null : existing.first;
  if (first != null && first.title == entry.title && first.body == entry.body) {
    return existing;
  }
  final merged = [entry, ...existing];
  return merged.length > cap ? merged.sublist(0, cap) : merged;
}

class AlertInbox extends Notifier<List<AlertInboxEntry>> {
  static const _key = 'alert_inbox_entries';

  @override
  List<AlertInboxEntry> build() => _load();

  List<AlertInboxEntry> _load() {
    final raw = ref
        .read(sharedPreferencesProvider)
        .getStringList(_key) ??
        const <String>[];
    final entries = <AlertInboxEntry>[];
    for (final line in raw) {
      try {
        final entry = AlertInboxEntry.tryFromJson(jsonDecode(line));
        if (entry != null) entries.add(entry);
      } catch (_) {
        // 坏行跳过
      }
    }
    return entries;
  }

  void _persist(List<AlertInboxEntry> entries) {
    ref.read(sharedPreferencesProvider).setStringList(
          _key,
          entries.map((e) => jsonEncode(e.toJson())).toList(),
        );
  }

  /// 新告警入箱（置顶、去重、裁剪）。
  void add({
    required String kind,
    required String title,
    required String body,
    String? payload,
  }) {
    final entry = AlertInboxEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      kind: kind,
      title: title,
      body: body,
      payload: payload,
      createdAt: DateTime.now(),
    );
    final merged = mergeAlertInbox(state, entry);
    if (identical(merged, state)) return;
    state = merged;
    _persist(merged);
  }

  /// 全部标记已读（打开通知中心时调用）。
  void markAllRead() {
    if (state.every((e) => e.read)) return;
    state = [for (final e in state) e.copyWith(read: true)];
    _persist(state);
  }

  /// 清空收件箱。
  void clearAll() {
    if (state.isEmpty) return;
    state = const [];
    _persist(state);
  }
}

final alertInboxProvider =
    NotifierProvider<AlertInbox, List<AlertInboxEntry>>(AlertInbox.new);

/// 未读告警数：供报头铃铛角标。
final alertInboxUnreadProvider = Provider<int>((ref) {
  return ref.watch(alertInboxProvider).where((e) => !e.read).length;
});
