import 'dart:convert';
import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/feed/data/rss_sources.dart';

part 'subscription_store.g.dart';

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
    this.categoryName = 'tech',
    this.description = '',
  });

  RssSource toRssSource() {
    final cat = FeedCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => FeedCategory.tech,
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
        categoryName: json['categoryName'] as String? ?? 'tech',
        description: json['description'] as String? ?? '',
      );
}

@Riverpod(keepAlive: true)
class SubscriptionStore extends _$SubscriptionStore {
  static const _kSubscribed = 'subscribed_source_ids';
  static const _kInited = 'subscribed_inited';
  static const _kCustomSources = 'custom_sources';

  Map<String, CustomSourceData> _customSources = {};

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final inited = prefs.getBool(_kInited) ?? false;
    Set<String> ids;
    if (inited) {
      ids = (prefs.getStringList(_kSubscribed) ?? []).toSet();
    } else {
      ids = RssSources.defaultSubscribedIds.toSet();
      await prefs.setStringList(_kSubscribed, ids.toList());
      await prefs.setBool(_kInited, true);
    }
    state = ids;

    final customJson = prefs.getString(_kCustomSources);
    if (customJson != null) {
      try {
        final map = jsonDecode(customJson) as Map<String, dynamic>;
        _customSources = map.map((k, v) =>
            MapEntry(k, CustomSourceData.fromJson(v as Map<String, dynamic>)));
      } catch (_) {
        _customSources = {};
      }
    }
  }

  bool isSubscribed(String sourceId) => state.contains(sourceId);

  Future<void> toggle(String sourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final next = Set<String>.from(state);
    if (!next.add(sourceId)) next.remove(sourceId);
    state = next;
    await prefs.setStringList(_kSubscribed, next.toList());
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kCustomSources,
        jsonEncode(
            _customSources.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<void> removeCustomSource(String id) async {
    _customSources.remove(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kCustomSources,
        jsonEncode(
            _customSources.map((k, v) => MapEntry(k, v.toJson()))));
    final next = Set<String>.from(state)..remove(id);
    state = next;
    await prefs.setStringList(_kSubscribed, next.toList());
  }
}
