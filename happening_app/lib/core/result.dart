/// The outcome of an operation that can fail, so callers must handle failure.
///
/// Services and repositories return this instead of throwing. Unwrap with an
/// exhaustive `switch`:
///
/// ```dart
/// switch (result) {
///   case Ok(:final value): ...
///   case Error(:final error): ...
/// }
/// ```
///
/// Follows https://docs.flutter.dev/app-architecture/design-patterns/result
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok._;
  const factory Result.error(Exception error) = Error._;
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

final class Error<T> extends Result<T> {
  const Error._(this.error);

  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}
