import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import 'datasources/rht_api.dart';
import 'models/rht_models.dart';
import 'models/rht_position.dart';
import 'models/rht_token.dart';
import 'models/rht_trader.dart';

final rhtApiProvider = Provider<RhtApi>((ref) => RhtApi(ref.watch(dioProvider)));

final smartMoneyRepositoryProvider = Provider<SmartMoneyRepository>((ref) {
  return SmartMoneyRepository(ref.watch(rhtApiProvider));
});

/// 聪明钱数据仓库：统一异常转换，UI 层只看 AppException。
class SmartMoneyRepository {
  final RhtApi _api;

  SmartMoneyRepository(this._api);

  Future<List<RhtFill>> fetchTape({int limit = 400, int? sinceId}) async {
    try {
      return await _api.tape(limit: limit, sinceId: sinceId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<RhtStatus> fetchStatus() async {
    try {
      return await _api.status();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<RhtOverview> fetchOverview({String window = '24h'}) async {
    try {
      return await _api.overview(window: window);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<RhtTrader>> fetchTraders() async {
    try {
      return await _api.traders();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<RhtClosedPosition>> fetchClosed() async {
    try {
      return await _api.closed();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<RhtTokenFlow>> fetchTokenFlows() async {
    try {
      return await _api.tokenFlows();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<RhtFlowChain>> fetchFlowChains() async {
    try {
      return await _api.flowChains();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<RhtRadarItem>> fetchRadar({int minutes = 120}) async {
    try {
      return await _api.radar(minutes: minutes);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// 上游无此交易员时返回 null（非异常）。
  Future<RhtTraderDetail?> fetchTraderDetail(String handle) async {
    try {
      return await _api.trader(handle);
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
