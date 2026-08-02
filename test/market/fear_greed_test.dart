import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/market/data/fear_greed_repository.dart';
import 'package:info_flow/features/market/domain/models/fear_greed_index.dart';

void main() {
  final ts = DateTime(2024, 1, 1);

  group('FearGreedIndex 模型', () {
    test('数值映射到五档', () {
      expect(
        FearGreedIndex(value: 10, classification: 'Extreme Fear', timestamp: ts)
            .band,
        FearGreedBand.extremeFear,
      );
      expect(
        FearGreedIndex(value: 35, classification: 'Fear', timestamp: ts).band,
        FearGreedBand.fear,
      );
      expect(
        FearGreedIndex(value: 50, classification: 'Neutral', timestamp: ts).band,
        FearGreedBand.neutral,
      );
      expect(
        FearGreedIndex(value: 66, classification: 'Greed', timestamp: ts).band,
        FearGreedBand.greed,
      );
      expect(
        FearGreedIndex(value: 90, classification: 'Extreme Greed', timestamp: ts)
            .band,
        FearGreedBand.extremeGreed,
      );
    });

    test('isFear / isGreed 边界', () {
      final fear = FearGreedIndex(value: 44, classification: 'Fear', timestamp: ts);
      final neutral =
          FearGreedIndex(value: 50, classification: 'Neutral', timestamp: ts);
      final greed = FearGreedIndex(value: 56, classification: 'Greed', timestamp: ts);
      expect(fear.isFear, true);
      expect(neutral.isFear, false);
      expect(neutral.isGreed, false);
      expect(greed.isGreed, true);
    });
  });

  group('FearGreedRepository 解析', () {
    test('正常响应解析出指数', () async {
      final repo = FearGreedRepository(_FakeDioReturnsFng());
      final idx = await repo.fetchIndex();
      expect(idx, isNotNull);
      expect(idx!.value, 72);
      expect(idx.classification, 'Greed');
      expect(idx.band, FearGreedBand.greed);
    });

    test('异常响应降级为 null（不抛）', () async {
      final repo = FearGreedRepository(_FakeDioThrows());
      expect(await repo.fetchIndex(), isNull);
    });
  });
}

class _FakeDioReturnsFng implements Dio {
  _FakeDioReturnsFng();

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final resp = Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'data': [
          {
            'value': '72',
            'value_classification': 'Greed',
            'timestamp': '1700000000',
          },
        ],
      } as T,
    );
    return resp;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeDioThrows implements Dio {
  _FakeDioThrows();

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    throw DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
