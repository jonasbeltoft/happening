import 'package:dio/dio.dart';

import '../../../core/result.dart';
import 'api_exception.dart';

/// Turns decoded JSON into a model. Throwing here (bad cast, missing field)
/// becomes a [BadResponseException].
typedef JsonDecoder<T> = T Function(Object? json);

/// Supplies the current access token, or null when signed out.
typedef TokenProvider = Future<String?> Function();

/// The only place that talks HTTP. Endpoint services call [get], [post], [put]
/// and [delete]; nothing else in the app imports dio.
///
/// Every call returns a [Result]. It never throws: transport errors, non-2xx
/// statuses and JSON that does not match the decoder all become an
/// [ApiException] inside [Error].
class ApiClient {
  ApiClient({required String baseUrl, TokenProvider? token, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          ) {
    if (token != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final value = await token();
            if (value != null) {
              options.headers['Authorization'] = 'Bearer $value';
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  final Dio _dio;

  Future<Result<T>> get<T>(
    String path,
    JsonDecoder<T> decode, {
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.get<Object?>(
      path,
      queryParameters: query,
      cancelToken: cancelToken,
    ),
    decode,
  );

  Future<Result<T>> post<T>(
    String path,
    Object? body,
    JsonDecoder<T> decode, {
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.post<Object?>(path, data: body, cancelToken: cancelToken),
    decode,
  );

  Future<Result<T>> put<T>(
    String path,
    Object? body,
    JsonDecoder<T> decode, {
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.put<Object?>(path, data: body, cancelToken: cancelToken),
    decode,
  );

  Future<Result<T>> delete<T>(
    String path,
    JsonDecoder<T> decode, {
    CancelToken? cancelToken,
  }) =>
      _send(() => _dio.delete<Object?>(path, cancelToken: cancelToken), decode);

  void close() => _dio.close();

  Future<Result<T>> _send<T>(
    Future<Response<Object?>> Function() request,
    JsonDecoder<T> decode,
  ) async {
    final Response<Object?> response;
    try {
      response = await request();
    } on DioException catch (e) {
      return Result.error(_toApiException(e));
    }

    try {
      return Result.ok(decode(response.data));
    } catch (e) {
      return Result.error(
        BadResponseException('${response.requestOptions.path}: $e'),
      );
    }
  }

  ApiException _toApiException(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const RequestTimeoutException(),
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => OfflineException(e.message ?? 'Offline'),
    DioExceptionType.cancel => const CancelledException(),
    DioExceptionType.badResponse when e.response?.statusCode == 401 =>
      const UnauthorizedException(),
    DioExceptionType.badResponse => ServerException(e.response?.statusCode),
    DioExceptionType.unknown => OfflineException(
      e.message ?? e.error.toString(),
    ),
  };
}
