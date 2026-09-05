import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/rht_models.dart';
import '../models/rht_position.dart';
import '../models/rht_token.dart';
import '../models/rht_trader.dart';

/// robinhoodtrenches.com 公开 API 数据源（只读、无鉴权）。
///
/// 站点 cache-control 为 public, max-age=2，官方允许轻轮询；
/// 上游字段见 data/models/ 各 fromJson。
/// [baseUrl] 可注入：测试指向不可达地址即可整体隔离真实网络。
class RhtApi {
  final Dio _dio;

  /// baseUrl 抽成实例字段：上游若关停可切换到自建索引服务。
  final String baseUrl;

  RhtApi(this._dio, {this.baseUrl = defaultBaseUrl});

  static const defaultBaseUrl = 'https://robinhoodtrenches.com';

  Future<dynamic> _get(String path, Map<String, dynamic> params) async {
    final resp = await _dio.get<dynamic>('$baseUrl/api$path',
        queryParameters: params);
    if (resp.statusCode != 200) {
      throw ServerException(statusCode: resp.statusCode);
    }
    return resp.data;
  }

  List<Map<String, dynamic>> _getListData(dynamic data) {
    if (data is! List) throw const ParseException();
    return data.whereType<Map<String, dynamic>>().toList();
  }

  /// 实盘成交。首轮拉 [limit]=400 做回填；增量用 [sinceId] 游标。
  Future<List<RhtFill>> tape({int limit = 400, int? sinceId}) async {
    final data = await _get('/tape', {
      'limit': limit,
      'stocks': 'true',
      if (sinceId != null && sinceId > 0) 'since_id': sinceId,
    });
    return _getListData(data).map(RhtFill.fromJson).toList();
  }

  Future<RhtStatus> status() async {
    final data = await _get('/status', const {});
    if (data is! Map<String, dynamic>) throw const ParseException();
    return RhtStatus.fromJson(data);
  }

  Future<RhtOverview> overview({String window = '24h'}) async {
    final data = await _get('/overview', {'window': window, 'stocks': 'false'});
    if (data is! Map<String, dynamic>) throw const ParseException();
    return RhtOverview.fromJson(data);
  }

  Future<List<RhtTrader>> traders({String window = '24h'}) async {
    final data =
        await _get('/traders', {'window': window, 'stocks': 'false'});
    return _getListData(data).map(RhtTrader.fromJson).toList();
  }

  Future<List<RhtClosedPosition>> closed(
      {String window = '24h', int limit = 80}) async {
    final data = await _get(
        '/closed', {'window': window, 'stocks': 'false', 'limit': limit});
    return _getListData(data).map(RhtClosedPosition.fromJson).toList();
  }

  Future<List<RhtTokenFlow>> tokenFlows(
      {String window = '24h', int limit = 60}) async {
    final data = await _get(
        '/tokens', {'window': window, 'stocks': 'false', 'limit': limit});
    return _getListData(data).map(RhtTokenFlow.fromJson).toList();
  }

  /// 跟单链：领买人 → 跟随者（含滞后秒数）。
  Future<List<RhtFlowChain>> flowChains(
      {String window = '24h', int limit = 40}) async {
    final data = await _get(
        '/flow', {'window': window, 'stocks': 'false', 'limit': limit});
    return _getListData(data).map(RhtFlowChain.fromJson).toList();
  }

  /// 聪明钱雷达：近 [minutes] 分钟被追踪钱包首买的新币。
  Future<List<RhtRadarItem>> radar({int minutes = 120, int limit = 40}) async {
    final data =
        await _get('/radar', {'minutes': minutes, 'limit': limit});
    return _getListData(data).map(RhtRadarItem.fromJson).toList();
  }

  /// 交易员详情（handle 区分大小写）。上游 404 时返回 null。
  Future<RhtTraderDetail?> trader(String handle) async {
    try {
      final resp = await _dio.get<dynamic>(
          '$baseUrl/api/trader/${Uri.encodeComponent(handle)}',
          queryParameters: {'window': '24h', 'stocks': 'false'});
      if (resp.statusCode != 200) return null;
      final data = resp.data;
      if (data is! Map<String, dynamic> || data['error'] != null) return null;
      return RhtTraderDetail.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
