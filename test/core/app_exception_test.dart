import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/network/api_client.dart';

DioException _dioError(DioExceptionType type, {int? statusCode}) {
  final options = RequestOptions(path: 'https://example.com');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  group('mapToAppException', () {
    test('超时类 DioException 映射为 TimeoutException', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final e = mapToAppException(_dioError(type));
        expect(e, isA<TimeoutException>(), reason: '$type');
        expect(e.message, '连接超时，请检查网络');
      }
    });

    test('connectionError 映射为 NetworkException', () {
      final e = mapToAppException(_dioError(DioExceptionType.connectionError));
      expect(e, isA<NetworkException>());
      expect(e.message, '网络连接失败，请检查网络设置');
    });

    test('badResponse 映射为 ServerException 并携带状态码', () {
      final e = mapToAppException(
        _dioError(DioExceptionType.badResponse, statusCode: 502),
      );
      expect(e, isA<ServerException>());
      expect((e as ServerException).statusCode, 502);
      expect(e.message, '服务暂时不可用，请稍后重试');
    });

    test('其余 DioException 类型兜底为 NetworkException', () {
      final e = mapToAppException(_dioError(DioExceptionType.cancel));
      expect(e, isA<NetworkException>());
    });

    test('FormatException 映射为 ParseException', () {
      final e = mapToAppException(const FormatException('bad json'));
      expect(e, isA<ParseException>());
      expect(e.message, '数据解析失败');
    });

    test('已是 AppException 时原样返回', () {
      const source = TimeoutException();
      expect(identical(mapToAppException(source), source), true);
    });

    test('未知异常兜底为 NetworkException 并保留 cause', () {
      final cause = StateError('boom');
      final e = mapToAppException(cause);
      expect(e, isA<NetworkException>());
      expect(e.cause, cause);
    });

    test('toString 直接返回用户消息', () {
      expect(const ParseException().toString(), '数据解析失败');
    });
  });
}
