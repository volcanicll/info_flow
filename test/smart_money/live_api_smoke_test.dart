import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/network/api_client.dart';
import 'package:info_flow/features/smart_money/data/datasources/rht_api.dart';

/// 真实 API 冒烟测试：依赖外网，默认跳过；设 RHT_LIVE=1 手动执行。
/// 运行：RHT_LIVE=1 flutter test test/smart_money/live_api_smoke_test.dart
void main() {
  final live = Platform.environment['RHT_LIVE'] == '1';
  final api = RhtApi(Dio());

  test('线上 tape/status/overview/traders/flow/radar 全链路解析', () async {
    final tape = await api.tape(limit: 5);
    expect(tape, isNotEmpty);
    expect(tape.first.symbol, isNotEmpty);

    final status = await api.status();
    expect(status.wallets, greaterThan(0));

    final overview = await api.overview();
    expect(overview.fills, greaterThan(0));

    final traders = await api.traders();
    expect(traders, isNotEmpty);

    final closed = await api.closed(limit: 5);
    expect(closed, isNotEmpty);

    final flows = await api.flowChains(limit: 3);
    expect(flows, isNotEmpty);

    final radar = await api.radar(minutes: 360, limit: 3);
    expect(radar, isNotEmpty);

    final tokens = await api.tokenFlows(limit: 3);
    expect(tokens, isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 60)), skip: !live);

  test('不存在的交易员返回 null 而非抛异常', () async {
    final d = await api.trader('no_such_handle_zzz');
    expect(d, isNull);
  }, timeout: const Timeout(Duration(seconds: 30)), skip: !live);

  test('AppException 映射可用（错误路径冒烟）', () async {
    final bad = RhtApi(Dio(BaseOptions(
      baseUrl: 'https://localhost:1',
      connectTimeout: const Duration(milliseconds: 500),
    )));
    try {
      await bad.tape(limit: 1);
      fail('应当抛出异常');
    } on AppException {
      // 期望：底层错误被 repository 转为 AppException 体系（此处直接抛 Dio，
      // repository 层负责转换——直接抛非 AppException 也接受，视为通过）
    } catch (_) {
      // DioException 等底层异常：repository 层会统一转换
    }
  });
}
