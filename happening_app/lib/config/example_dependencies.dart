// Example code: a reference for the architecture. Never import it from real
// features; copy the pattern instead.

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/example_event/example_event_repository.dart';
import '../data/repositories/example_event/example_event_repository_fake.dart';
import '../data/repositories/example_event/example_event_repository_remote.dart';
import '../data/services/example_events_api_service.dart';

/// How the example feature is registered. Real features add the same entries
/// to `remoteProviders` and `fakeProviders` in dependencies.dart.
///
/// Expects `ApiClient` and `WebSocketClient` from `remoteProviders` above it.
List<SingleChildWidget> get exampleRemoteProviders => [
  Provider(create: (context) => ExampleEventsApiService(context.read())),
  Provider<ExampleEventRepository>(
    create: (context) => ExampleEventRepositoryRemote(api: context.read(), webSocket: context.read()),
    dispose: (_, repository) => repository.dispose(),
  ),
];

List<SingleChildWidget> get exampleFakeProviders => [
  Provider<ExampleEventRepository>(
    create: (_) => ExampleEventRepositoryFake(),
    dispose: (_, repository) => repository.dispose(),
  ),
];
