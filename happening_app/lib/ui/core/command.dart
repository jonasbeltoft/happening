import 'package:flutter/foundation.dart';

import '../../core/result.dart';

typedef CommandAction0<T> = Future<Result<T>> Function();
typedef CommandAction1<T, A> = Future<Result<T>> Function(A);

/// Wraps a user action so the UI can show running, error and done states
/// without tracking flags itself. Listen to it with a `ListenableBuilder`.
///
/// A command ignores new calls while it is running, which prevents double
/// submits from repeated taps.
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  Result<T>? _result;

  bool get running => _running;

  /// The last outcome, or null before the first run and while running.
  Result<T>? get result => _result;

  bool get error => _result is Error;
  bool get completed => _result is Ok;

  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(CommandAction0<T> action) async {
    if (_running) return;

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// A command without arguments.
class Command0<T> extends Command<T> {
  Command0(this._action);

  final CommandAction0<T> _action;

  Future<void> execute() => _execute(_action);
}

/// A command with one argument. Use a record for several values.
class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final CommandAction1<T, A> _action;

  Future<void> execute(A argument) => _execute(() => _action(argument));
}
