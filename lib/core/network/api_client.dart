import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:info_flow/core/logging/logger.dart';

/// 应用统一异常：携带用户可读的中文消息。
///
/// repository 层捕获底层异常后统一转为 AppException 抛出，
/// controller 层经 AsyncValue 呈现，UI 直接展示 [message]。
sealed class AppException implements Exception {
  final String message;
  final Object? cause;
  const AppException(this.message, {this.cause});

  @override
  String toString() => message;
}

/// 连接/收发超时
class TimeoutException extends AppException {
  const TimeoutException({Object? cause})
      : super('连接超时，请检查网络', cause: cause);
}

/// 网络不可达
class NetworkException extends AppException {
  const NetworkException({Object? cause})
      : super('网络连接失败，请检查网络设置', cause: cause);
}

/// 服务端错误（4xx/5xx）
class ServerException extends AppException {
  final int? statusCode;
  const ServerException({this.statusCode, Object? cause})
      : super('服务暂时不可用，请稍后重试', cause: cause);
}

/// 响应数据解析失败
class ParseException extends AppException {
  const ParseException({Object? cause})
      : super('数据解析失败', cause: cause);
}

/// 将任意异常规整为 AppException。
AppException mapToAppException(Object error) {
  if (error is AppException) return error;
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(cause: error);
      case DioExceptionType.connectionError:
        return NetworkException(cause: error);
      case DioExceptionType.badResponse:
        return ServerException(
          statusCode: error.response?.statusCode,
          cause: error,
        );
      default:
        return NetworkException(cause: error);
    }
  }
  if (error is FormatException || error is TypeError) {
    return ParseException(cause: error);
  }
  return NetworkException(cause: error);
}

/// 全应用唯一的 Dio 实例：统一超时与日志。
///
/// 需要特殊 baseUrl/header 的调用（如 LLM 接口）通过请求级
/// [Options] 覆盖，不要另建 Dio。
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': 'Mozilla/5.0 (compatible; InfoFlow/1.0)'},
  ));

  dio.interceptors.add(_LogInterceptor(ref));
  return dio;
});

class _LogInterceptor extends Interceptor {
  final Ref _ref;
  _LogInterceptor(this._ref);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _ref.read(loggerProvider).d(
          '← ${response.statusCode} ${response.requestOptions.uri}',
        );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _ref.read(loggerProvider).e(
          '✕ ${err.requestOptions.method} ${err.requestOptions.uri}',
          error: err.message,
        );
    handler.next(err);
  }
}
