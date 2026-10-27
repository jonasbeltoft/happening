import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/services/api/api_client.dart';
import '../data/services/websocket/websocket_client.dart';
import 'app_config.dart';

/// App-wide services and repositories, talking to the real server. Add each
/// feature's API service and remote repository here.
/// Pass `token:` to [ApiClient] and [WebSocketClient] once sign-in exists.
List<SingleChildWidget> get remoteProviders => [
  Provider(create: (_) => ApiClient(baseUrl: AppConfig.apiBaseUrl), dispose: (_, client) => client.close()),
  Provider(
    create: (_) => WebSocketClient(url: Uri.parse(AppConfig.webSocketUrl))..connect(),
    dispose: (_, webSocket) => webSocket.dispose(),
  ),
];

/// In-memory repositories; no server needed. Add each feature's fake
/// repository here, registered as its abstract type.
List<SingleChildWidget> get fakeProviders => [];
