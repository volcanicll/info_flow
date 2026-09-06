import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../fomo_api_key_store.dart';
import '../models/rht_models.dart';

final fomoApiProvider = Provider<FomoApi>((ref) {
  return FomoApi(
    ref.watch(dioProvider),
    () => ref.watch(fomoApiKeyStoreProvider),
  );
});

/// fomoapi.io 数据源（fomo.family 生态的社交交易数据 API）。
///
/// 文档 https://fomoapi.io/docs ，Base https://api.fomoapi.io ：
/// - `GET /v2/leaderboard/{window}`：24h/7d/30d/all 收益榜，**免 key**（IP 限流）；
/// - `GET /token/{address}/holders`：被追踪聪明钱对某代币的持仓，需 key；
/// 其余端点（handle 解析、trades、balances）无 key 一律 401，未集成。
/// 免费档：10,000 请求/月，注册即取 key（fomoapi.io/dashboard）。
class FomoApi {
  final Dio _dio;

  /// 返回当前配置的 key（可为空）。调用时读取，改 key 立即生效。
  final String Function() _key;

  FomoApi(this._dio, this._key);

  static const baseUrl = 'https://api.fomoapi.io';

  Options _options() {
    final key = _key();
    return Options(
      headers: key.isEmpty ? null : {'authorization': 'Bearer $key'},
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map) {
      for (final k in const ['traders', 'leaderboard', 'data', 'holders', 'results']) {
        if (data[k] is List) return data[k];
      }
      if (data['error'] != null) throw ServerException();
    }
    return data;
  }

  /// 多窗口收益榜。[window] ∈ 24h / 7d / 30d / all。
  Future<List<FomoLeaderEntry>> leaderboard({
    String window = '7d',
    int limit = 60,
  }) async {
    final resp = await _dio.get<dynamic>(
      '$baseUrl/v2/leaderboard/$window',
      queryParameters: {'limit': limit},
      options: _options(),
    );
    final rows = _unwrap(resp.data);
    if (rows is! List) throw const ParseException();
    return rows
        .whereType<Map<String, dynamic>>()
        .map(FomoLeaderEntry.fromJson)
        .toList();
  }

  /// 代币聪明钱持仓：被追踪大户对某代币的当前持仓（需 key）。
  Future<List<FomoHolder>> tokenHolders(String address) async {
    final resp = await _dio.get<dynamic>(
      '$baseUrl/token/$address/holders',
      options: _options(),
    );
    final rows = _unwrap(resp.data);
    if (rows is! List) throw const ParseException();
    return rows
        .whereType<Map<String, dynamic>>()
        .map(FomoHolder.fromJson)
        .toList();
  }
}

/// 收益榜条目（跨链，字段比 robinhoodtrenches 榜单精简：无仓位状态/胜率）。
class FomoLeaderEntry {
  final int rank;
  final String handle;
  final String? displayName;
  final double pnlUsd;
  final double volumeUsd;
  final int trades;
  final int followers;
  final int holdings;
  final String? solanaWallet;
  final String? evmWallet;
  final bool verified;

  const FomoLeaderEntry({
    required this.rank,
    required this.handle,
    required this.displayName,
    required this.pnlUsd,
    required this.volumeUsd,
    required this.trades,
    required this.followers,
    required this.holdings,
    required this.solanaWallet,
    required this.evmWallet,
    required this.verified,
  });

  factory FomoLeaderEntry.fromJson(Map<String, dynamic> j) {
    final wallets = j['wallets'] as Map<String, dynamic>?;
    return FomoLeaderEntry(
      rank: j.i('rank') ?? 0,
      handle: j['handle'] as String? ?? '—',
      displayName: j['displayName'] as String?,
      pnlUsd: j.d('pnlUsd') ?? 0,
      volumeUsd: j.d('volumeUsd') ?? 0,
      trades: j.i('trades') ?? 0,
      followers: j.i('followers') ?? 0,
      holdings: j.i('holdings') ?? 0,
      solanaWallet: wallets?['solana'] as String?,
      evmWallet: wallets?['evm'] as String?,
      verified: j.b('verified'),
    );
  }

  String get title =>
      (displayName != null && displayName!.isNotEmpty) ? displayName! : handle;
}

/// 聪明钱对某代币的当前持仓。
class FomoHolder {
  final String handle;
  final double amount;
  final double valueUsd;
  final double? priceUsd;

  const FomoHolder({
    required this.handle,
    required this.amount,
    required this.valueUsd,
    required this.priceUsd,
  });

  factory FomoHolder.fromJson(Map<String, dynamic> j) => FomoHolder(
        handle: j['handle'] as String? ?? '—',
        amount: j.d('amount') ?? 0,
        valueUsd: j.d('valueUsd') ?? 0,
        priceUsd: j.d('priceUsd'),
      );
}

/// 代币聪明钱持仓查询：供代币详情页使用（需 key，未配置时上层隐藏入口）。
final tokenHoldersProvider = FutureProvider.autoDispose
    .family<List<FomoHolder>, String>((ref, address) {
  return ref.watch(fomoApiProvider).tokenHolders(address);
});
