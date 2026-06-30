import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/metal_price.dart';

class MetalsRepository {
  final Dio _dio;

  MetalsRepository(this._dio);

  Future<List<MetalPrice>> fetchPrices() async {
    final resp = await _dio.get<String>(
      'https://hq.sinajs.cn/list=hf_XAU,gds_AUTD,hf_XAG,gds_AGTD',
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Referer': 'https://finance.sina.com.cn/',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      ),
    );

    final body = resp.data;
    if (body == null || body.isEmpty) return [];

    final results = <MetalPrice>[];
    final regex = RegExp(r'var hq_str_(\w+)="([^"]+)";');
    for (final match in regex.allMatches(body)) {
      final code = match.group(1)!;
      final data = match.group(2)!.split(',');

      if (data.length < 8) continue;
      final current = double.tryParse(data[0]) ?? 0;
      final prevClose = double.tryParse(data[7]) ?? 0;
      final changePct =
          prevClose > 0 ? ((current - prevClose) / prevClose * 100) : 0.0;

      switch (code) {
        case 'hf_XAU':
          results.add(MetalPrice(
            name: '纽约金 (XAU)',
            code: 'XAU',
            currency: 'USD',
            price: current,
            changePercent: changePct,
          ));
        case 'gds_AUTD':
          results.add(MetalPrice(
            name: '上海金 (AU T+D)',
            code: 'AUTD',
            currency: 'CNY',
            price: current,
            changePercent: changePct,
          ));
        case 'hf_XAG':
          results.add(MetalPrice(
            name: '纽约银 (XAG)',
            code: 'XAG',
            currency: 'USD',
            price: current,
            changePercent: changePct,
          ));
        case 'gds_AGTD':
          results.add(MetalPrice(
            name: '上海银 (AG T+D)',
            code: 'AGTD',
            currency: 'CNY',
            price: current,
            changePercent: changePct,
          ));
      }
    }

    return results;
  }
}

final metalsRepositoryProvider = Provider<MetalsRepository>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));
  return MetalsRepository(dio);
});
