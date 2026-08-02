import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:info_flow/core/network/api_client.dart';

import '../domain/models/fear_greed_index.dart';

/// 恐惧贪婪指数数据源：alternative.me 免费 API。
class FearGreedRepository {
  FearGreedRepository(this._dio);

  final Dio _dio;

  Future<FearGreedIndex?> fetchIndex() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        'https://api.alternative.me/fng/',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Accept': 'application/json'},
        ),
      );

      final data = resp.data?['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) return null;

      final first = data.first as Map<String, dynamic>;
      final value = int.tryParse('${first['value']}');
      if (value == null) return null;

      final ts = int.tryParse('${first['timestamp']}');
      return FearGreedIndex(
        value: value,
        classification: first['value_classification'] as String? ?? '',
        timestamp: ts != null
            ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
            : DateTime.now(),
      );
    } catch (_) {
      // 情感指数是可降级数据：失败返回 null，由 UI 隐藏该区块
      return null;
    }
  }
}

final fearGreedRepositoryProvider = Provider<FearGreedRepository>((ref) {
  return FearGreedRepository(ref.watch(dioProvider));
});
