import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final loggerProvider = Provider<Logger>((ref) => Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
));

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.infoflow.app'),
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.addAll([
    _AuthInterceptor(ref),
    _LogInterceptor(ref),
    _ErrorInterceptor(ref),
  ]);

  return dio;
});

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(Ref ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

class _LogInterceptor extends Interceptor {
  final Ref _ref;
  _LogInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _ref.read(loggerProvider).d(
      '→ ${options.method} ${options.uri}',
      error: 'Headers: ${options.headers}',
    );
    handler.next(options);
  }

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

class _ErrorInterceptor extends Interceptor {
  _ErrorInterceptor(Ref ref);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.next(DioException(
          requestOptions: err.requestOptions,
          error: '连接超时，请检查网络',
          type: err.type,
        ));
        break;
      case DioExceptionType.connectionError:
        handler.next(DioException(
          requestOptions: err.requestOptions,
          error: '网络连接失败，请检查网络设置',
          type: err.type,
        ));
        break;
      default:
        handler.next(err);
    }
  }
}

/// 统一 API 结果封装
sealed class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? code;
  const ApiFailure(this.message, {this.code});
}

/// 将 Dio 请求转换为 ApiResult
Future<ApiResult<T>> safeApiCall<T>(Future<Response> Function() call, T Function(dynamic json) fromJson) async {
  try {
    final response = await call();
    final data = fromJson(response.data);
    return ApiSuccess(data);
  } on DioException catch (e) {
    final message = e.error is String ? e.error as String : e.message ?? '请求失败';
    return ApiFailure(message, code: e.response?.statusCode);
  } catch (e) {
    return ApiFailure(e.toString());
  }
}
