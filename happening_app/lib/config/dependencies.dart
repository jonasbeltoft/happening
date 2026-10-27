import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/event/event_repository.dart';
import '../data/repositories/event/event_repository_fake.dart';
import '../data/repositories/event/event_repository_remote.dart';
import '../data/services/api/api_client.dart';
import '../data/services/events_api_service.dart';
import '../data/services/websocket/websocket_client.dart';
import 'app_config.dart';

/// App-wide services and repositories, talking to the real server.
/// Pass `token:` to [ApiClient] and [WebSocketClient] once sign-in exists.
List<SingleChildWidget> get remoteProviders => [
  Provider(create: (_) => ApiClient(baseUrl: AppConfig.apiBaseUrl), dispose: (_, client) => client.close()),
  Provider(
    create: (_) => WebSocketClient(url: Uri.parse(AppConfig.webSocketUrl))..connect(),
    dispose: (_, webSocket) => webSocket.dispose(),
  ),
  Provider(create: (context) => EventsApiService(context.read())),
  Provider<EventRepository>(
    create: (context) => EventRepositoryRemote(api: context.read(), webSocket: context.read()),
    dispose: (_, repository) => repository.dispose(),
  ),
];

/// In-memory repositories; no server needed.
List<SingleChildWidget> get fakeProviders => [
  Provider<EventRepository>(create: (_) => EventRepositoryFake(), dispose: (_, repository) => repository.dispose()),
];
