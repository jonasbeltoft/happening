/// Every way a server call can fail. [ApiClient] maps all transport and
/// parsing errors to one of these, so callers switch on a closed set.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  /// For logs, not for showing to the user.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No connection to the server.
final class OfflineException extends ApiException {
  const OfflineException([super.message = 'Could not reach the server']);
}

final class RequestTimeoutException extends ApiException {
  const RequestTimeoutException([super.message = 'The server took too long to answer']);
}

/// 401. The session is missing or expired.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Not signed in']);
}

/// Any other non-2xx status.
final class ServerException extends ApiException {
  const ServerException(this.statusCode, [super.message = 'The server returned an error']);

  final int? statusCode;
}

/// The response arrived but did not have the expected shape.
final class BadResponseException extends ApiException {
  const BadResponseException(super.message);
}

/// The request was cancelled through its `CancelToken`.
final class CancelledException extends ApiException {
  const CancelledException([super.message = 'Request cancelled']);
}
