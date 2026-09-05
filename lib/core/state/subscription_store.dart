import 'dart:convert';
import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:info_flow/core/logging/logger.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:info_flow/features/feed/data/rss_sources.dart';
import 'package:info_flow/features/subscription/data/opml_parser.dart';

part 'subscription_store.g.dart';

/// OPML 导入结果统计。
class OpmlImportResult {
  final int added;
  final int alreadySubscribed;
  final int duplicate;
  final int invalid;
  OpmlImportResult({
    required this.added,
    required this.alreadySubscribed,
    required this.duplicate,
    required this.invalid,
  });
}

class CustomSourceData {
  final String id;
  final String name;
  final String feedUrl;
  final String siteUrl;
  final String categoryName;
  final String description;

  const CustomSourceData({
    required this.id,
    required this.name,
    required this.feedUrl,
    this.siteUrl = '',
    this.categoryName = 'news',
    this.description = '',
  });

  RssSource toRssSource() {
    final cat = FeedCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => FeedCategory.news,
    );
    return RssSource(
      id: id,
      name: name,
      feedUrl: feedUrl,
      siteUrl: siteUrl.isNotEmpty ? siteUrl : feedUrl,
      category: cat,
      color: Color(name.hashCode | 0xFF000000),
      description: description.isNotEmpty ? description : '自定义订阅源',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'feedUrl': feedUrl,
        'siteUrl': siteUrl,
        'categoryName': categoryName,
        'description': description,
      };

  factory CustomSourceData.fromJson(Map<String, dynamic> json) =>
      CustomSourceData(
        id: json['id'] as String,
        name: json['name'] as String,
        feedUrl: json['feedUrl'] as String,
        siteUrl: json['siteUrl'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? 'news',
        description: json['description'] as String? ?? '',
      );
}

@Riverpod(keepAlive: true)
class SubscriptionStore extends _$SubscriptionStore {
  static const _kSubscribed = 'subscribed_source_ids';
  static const _kInited = 'subscribed_inited';
  static const _kCustomSources = 'custom_sources';

  Map<String, CustomSourceData> _customSources = {};

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Set<String> build() {
    // 同步读取：首次启动写入默认订阅，其余直接恢复
    final inited = _prefs.getBool(_kInited) ?? false;
    Set<String> ids;
    if (inited) {
      ids = (_prefs.getStringList(_kSubscribed) ?? []).toSet();
    } else {
      ids = RssSources.defaultSubscribedIds.toSet();
      _prefs.setStringList(_kSubscribed, ids.toList());
      _prefs.setBool(_kInited, true);
    }

    final customJson = _prefs.getString(_kCustomSources);
    if (customJson != null) {
      try {
        final map = jsonDecode(customJson) as Map<String, dynamic>;
        _customSources = map.map((k, v) =>
            MapEntry(k, CustomSourceData.fromJson(v as Map<String, dynamic>)));
      } catch (e) {
        ref.read(loggerProvider).w('自定义订阅源解析失败，已忽略', error: e);
        _customSources = {};
      }
    }
    return ids;
  }

  bool isSubscribed(String sourceId) => state.contains(sourceId);

  Future<void> toggle(String sourceId) async {
    final next = Set<String>.from(state);
    if (!next.add(sourceId)) next.remove(sourceId);
    state = next;
    await _prefs.setStringList(_kSubscribed, next.toList());
  }

  List<RssSource> get subscribedSources {
    final result = <RssSource>[];
    for (final id in state) {
      final builtIn = RssSources.byId(id);
      if (builtIn != null) {
        result.add(builtIn);
      } else if (_customSources.containsKey(id)) {
        result.add(_customSources[id]!.toRssSource());
      }
    }
    return result;
  }

  RssSource? resolveSource(String id) {
    final builtIn = RssSources.byId(id);
    if (builtIn != null) return builtIn;
    final custom = _customSources[id];
    if (custom != null) return custom.toRssSource();
    return null;
  }

  List<CustomSourceData> get customSources => _customSources.values.toList();

  Future<void> addCustomSource(
      String name, String feedUrl, String categoryName) async {
    final id = 'custom_${name.hashCode}_${feedUrl.hashCode}';
    if (_customSources.containsKey(id)) return;
    final src = CustomSourceData(
      id: id,
      name: name,
      feedUrl: feedUrl,
      categoryName: categoryName,
    );
    _customSources[id] = src;
    await _prefs.setString(
        _kCustomSources,
        jsonEncode(
            _customSources.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<void> removeCustomSource(String id) async {
    _customSources.remove(id);
    await _prefs.setString(
        _kCustomSources,
        jsonEncode(
            _customSources.map((k, v) => MapEntry(k, v.toJson()))));
    final next = Set<String>.from(state)..remove(id);
    state = next;
    await _prefs.setStringList(_kSubscribed, next.toList());
  }

  /// 批量导入 OPML 订阅：命中内置源则直接订阅，否则创建自定义源并订阅。
  /// 按 feedUrl 去重，返回统计信息。
  Future<OpmlImportResult> importOpml(List<OpmlSubscription> items) async {
    var added = 0;
    var alreadySubscribed = 0;
    var duplicate = 0;
    var invalid = 0;
    final knownUrls = <String>{
      for (final s in RssSources.all) s.feedUrl,
      for (final s in _customSources.values) s.feedUrl,
    };
    final next = Set<String>.from(state);

    for (final item in items) {
      final url = item.feedUrl.trim();
      if (url.isEmpty || !url.startsWith('http')) {
        invalid++;
        continue;
      }
      if (knownUrls.contains(url)) {
        // 已在源库中：尝试订阅
        final builtIn = RssSources.all
            .where((s) => s.feedUrl == url)
            .firstOrNull;
        final id = builtIn?.id ??
            _customSources.values
                .where((s) => s.feedUrl == url)
                .firstOrNull
                ?.id;
        if (id == null) {
          duplicate++;
          continue;
        }
        if (next.contains(id)) {
          alreadySubscribed++;
        } else {
          next.add(id);
          alreadySubscribed++;
        }
        continue;
      }
      // 新源：创建自定义源
      final name = item.name.isNotEmpty ? item.name : _deriveName(url);
      final id = 'custom_${name.hashCode}_$url'.hashCode.toString();
      if (_customSources.containsKey(id)) {
        duplicate++;
        continue;
      }
      _customSources[id] = CustomSourceData(
        id: id,
        name: name,
        feedUrl: url,
        siteUrl: item.siteUrl,
        categoryName: _matchCategory(item.category),
      );
      knownUrls.add(url);
      next.add(id);
      added++;
    }

    state = next;
    await _prefs.setStringList(_kSubscribed, next.toList());
    await _prefs.setString(
        _kCustomSources,
        jsonEncode(
            _customSources.map((k, v) => MapEntry(k, v.toJson()))));
    return OpmlImportResult(
      added: added,
      alreadySubscribed: alreadySubscribed,
      duplicate: duplicate,
      invalid: invalid,
    );
  }

  /// 导出已订阅源为 OPML 字符串（含内置源与自定义源）。
  String exportOpml() {
    final subs = subscribedSources
        .map(
          (s) => OpmlSubscription(
            name: s.name,
            feedUrl: s.feedUrl,
            siteUrl: s.siteUrl,
            category: s.category.label,
          ),
        )
        .toList();
    return OpmlBuilder.build(title: 'InfoFlow 订阅', subscriptions: subs);
  }

  String _deriveName(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) return uri.host;
    return url;
  }

  String _matchCategory(String label) {
    for (final cat in FeedCategory.values) {
      if (cat.label == label || cat.name == label) return cat.name;
    }
    return 'news';
  }
}
