/// Build-time settings. Override with `--dart-define`, e.g.
/// `flutter run --dart-define=FAKE_DATA=false --dart-define=API_BASE_URL=https://api.example.com`.
///
/// On the Android emulator, the host machine's localhost is `10.0.2.2`.
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080/api');

  static const webSocketUrl = String.fromEnvironment('WEBSOCKET_URL', defaultValue: 'ws://localhost:8080/ws');

  /// Use in-memory fake repositories instead of the server.
  static const useFakeData = bool.fromEnvironment('FAKE_DATA', defaultValue: true);
}
