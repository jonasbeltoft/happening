# Happening app

How this Flutter app is built. Follow these rules for every feature. The rules are the source of truth; any feature code in the repo is just an example of them.

Based on the [Flutter app architecture guide](https://docs.flutter.dev/app-architecture/guide), adapted as described below.

## Ground rules

- Type check with `flutter analyze`. Don't build or run unless told to. `flutter test` is fine when asked.
- No UI library: import only `package:flutter/widgets.dart` (plus `foundation.dart` / `services.dart`). Never import `material.dart` or `cupertino.dart`. The app root is a `WidgetsApp`.
- Design reference: `../design/Main_Design.html` ("Chalk & Ember"). Read it before building a screen.

## Folder map

Paths are relative to `lib/`. Folders marked *infra* are shared plumbing and stay; everything else is per feature.

```
core/                  infra: code shared by every layer (Result)
types/                 immutable app types, e.g. Event, Rsvp
config/                app_config.dart (dart-define settings), dependencies.dart (provider wiring)
data/
  dtos/                *Dto classes shaped like the server JSON
  services/
    api/               infra: ApiClient, ApiException
    websocket/         infra: WebSocketClient
    <x>_api_service.dart   one per server resource
  repositories/<x>/    x_repository.dart (abstract), x_repository_remote.dart, x_repository_fake.dart
ui/
  theme/               infra: app_theme.dart (all design tokens)
  core/                infra: non-visual UI logic (Pressable, Command)
  components/          reusable visible widgets; a file each, or a folder when it has variants
  screens/<screen>/    x_screen.dart + x_view_model.dart; sub-screens in subfolders
```

## Layers and data flow

```
Server ─► ApiClient / WebSocketClient ─► XApiService ─► XRepository ─► XViewModel ─► XScreen
                                          (DTOs)        (app types)    (display state) (widgets)
```

Data flows down; user actions flow up through view model commands into repositories.

| Layer | Does | Never |
|---|---|---|
| Service | One method per endpoint, returns `Future<Result<Dto>>`. Stateless. | Cache, map to app types, know about screens |
| Repository | Single source of truth for one data type. Maps DTO → app type, caches, applies WebSocket messages, refetches after reconnect. | Depend on another repository, return DTOs, throw |
| View model | One per screen. Turns app types into display-ready state (formatted strings, flags). Exposes actions as commands. | Touch services, HTTP, JSON or DTOs |
| Screen | Lays out the view model's state, forwards taps to commands. | Contain logic beyond show/hide, layout and animation |

Import direction:
- `core/` and `types/` import nothing from `data/` or `ui/`.
- `data/` never imports from `ui/`.
- `ui/` imports `core/`, `types/`, and repository interfaces from `data/` (only `ApiException` from services, for error wording).
- Only repositories use services. Only `ApiClient` imports dio. Only `WebSocketClient` imports `web_socket_channel`.
- When a screen needs two data types, the view model combines two repositories. Repositories never call each other.

## Errors: `Result`, never throw

- Services and repositories return `Result<T>` from `core/result.dart`. Unwrap with an exhaustive switch:
  ```dart
  switch (await _api.getThing(id)) {
    case Ok(:final value): ...
    case Error(:final error): ...
  }
  ```
- `ApiClient` turns every failure into an `ApiException` subtype: `OfflineException`, `RequestTimeoutException`, `UnauthorizedException`, `ServerException(statusCode)`, `BadResponseException`, `CancelledException`. A DTO decoder that throws (bad cast, missing field) becomes `BadResponseException` automatically.
- View models turn exceptions into user wording ("You're offline."). Never show `error.toString()`.

## Adding a feature

Work bottom-up. Use `Thing` as the stand-in name.

**1. App type** in `types/thing.dart`: immutable, `@immutable`, `const` constructor, `copyWith` for fields that change. Enums for closed sets.

**2. DTO** in `data/dtos/thing_dto.dart`: fields exactly as the server sends them (dates as `String`, enums as `String`).
```dart
factory ThingDto.fromJson(Object? json) {
  if (json is! Map<String, Object?>) throw FormatException('Expected a thing, got $json');
  return ThingDto(id: json['id'] as String, startsAt: json['startsAt'] as String, ...);
}
static List<ThingDto> listFromJson(Object? json) { /* check is List, map fromJson */ }
```

**3. Service** in `data/services/things_api_service.dart`:
```dart
class ThingsApiService {
  ThingsApiService(this._client);
  final ApiClient _client;

  Future<Result<List<ThingDto>>> list() => _client.get('/things', ThingDto.listFromJson);
  Future<Result<ThingDto>> update(String id, String state) =>
      _client.put('/things/$id', {'state': state}, ThingDto.fromJson);
}
```

**4. Repository** in `data/repositories/thing/`:
- `thing_repository.dart`: abstract class. Reads are a `Stream` of app types, writes are methods returning `Result`, plus `dispose()`.
  ```dart
  abstract class ThingRepository {
    Stream<List<Thing>> get things;        // cached value on listen (if loaded), then every change
    Future<Result<void>> refresh();
    Future<Result<Thing>> update(String id, ThingState state);
    void dispose();
  }
  ```
- `thing_repository_remote.dart`: holds the cache (`List<Thing>?`) and a broadcast `StreamController`.
  - `get things async* { if (_cache case final c?) yield c; yield* _controller.stream; }`
  - Subscribe to the WebSocket topic in the controller's `onListen`, cancel in `onCancel`.
  - Listen to `webSocket.reconnected` and call `refresh()` while there are listeners.
  - After a write, upsert the returned item into the cache and emit, so every screen updates.
  - Map with a private `static Thing _fromDto(ThingDto dto)`. Parse dates with `.toLocal()`, map enum strings with `Values.asNameMap()[s] ?? fallback`.
  - Wrap WebSocket message handling in try/catch and ignore malformed pushes.
- `thing_repository_fake.dart`: same interface, in-memory sample data, a `latency` constructor parameter (default 300 ms). Used when `FAKE_DATA=true` (the default) and in tests.

**5. Register** in `config/dependencies.dart`: the service and remote repository in `remoteProviders`, the fake in `fakeProviders`. Repositories are registered as the abstract type with `dispose`:
```dart
Provider<ThingRepository>(create: (context) => ThingRepositoryRemote(api: context.read(), webSocket: context.read()),
    dispose: (_, r) => r.dispose()),
```

**6. View model** in `ui/screens/things/things_view_model.dart`:
```dart
class ThingsViewModel extends ChangeNotifier {
  ThingsViewModel({required this._things}) {
    _sub = _things.things.listen(_onThings);
    load = Command0(_things.refresh)..execute();
    update = Command1(_update);
  }

  final ThingRepository _things;
  late final StreamSubscription<List<Thing>> _sub;
  late final Command0<void> load;
  late final Command1<void, (String, ThingState)> update;   // records for several arguments

  List<ThingRowState> _rows = const [];
  List<ThingRowState> get rows => _rows;

  void _onThings(List<Thing> things) { _rows = things.map(_toRow).toList(); notifyListeners(); }

  @override
  void dispose() { _sub.cancel(); load.dispose(); update.dispose(); super.dispose(); }
}
```
- Expose display-ready state: small immutable `XRowState` classes with already-formatted strings and flags. The screen never formats dates, counts or prices.
- Every user action is a `Command0` / `Command1` (`ui/core/command.dart`). They track `running`, `result`, `error`, `completed` and ignore taps while running.
- Derive error text from `command.result` with a switch on `ApiException` subtypes.

**7. Screen** in `ui/screens/things/things_screen.dart`: a `StatelessWidget` taking `viewModel` in its constructor. Wrap content in `ListenableBuilder(listenable: Listenable.merge([viewModel, viewModel.load, ...]))`. Handle three states: loading (`load.running` with no data), error with a "Try again" button calling `load.execute`, and content. Widgets used only by this screen are private classes (`_ThingRow`) in the screen folder.

**8. Route**: the view model is created next to its screen with `ChangeNotifierProvider(create: (context) => ThingsViewModel(things: context.read()), builder: (context, _) => ThingsScreen(viewModel: context.read()))`, so it is disposed with the screen.

**9. Test** in `test/`: a widget test that pumps `MultiProvider(providers: fakeProviders, child: const HappeningApp())`, advances past the fake latency with `tester.pump(const Duration(seconds: 1))` then `pumpAndSettle()`, and asserts on visible text. Unit-test `ApiClient` with an injected `Dio` and `WebSocketClient` with an injected `connect` function.

## WebSocket

- One `WebSocketClient` for the whole app. Never open sockets elsewhere, and never in `build()`.
- Repositories subscribe with `webSocket.topic('things')`; the server subscription stays open while anything listens.
- Messages missed while disconnected are lost, so repositories refetch over REST on `reconnected`.
- Writes (RSVP, posting) go over REST, not the socket; the socket is for server pushes.
- Wire protocol (JSON text frames), the server must match:
  - client → server: `{"type":"auth","token":"…"}`, `{"type":"subscribe","topic":"…"}`, `{"type":"unsubscribe","topic":"…"}`, `{"type":"ping"}`
  - server → client: `{"topic":"…","type":"thing.updated","data":{…}}`, `{"type":"pong"}`
  - Message types are `<thing>.<event>`, e.g. `event.updated`, `event.removed`.

## UI rules

- **Tokens only.** Colors, text styles, spacing, radii and shadows come from `AppTheme.of(context)` and the `AppSpacing`, `AppRadius` and `AppShadows` constants in `ui/theme/app_theme.dart`. Never hardcode a color or font size in a widget; add a token. Fonts (Archivo, Instrument Serif) are bundled in `assets/fonts`.
- **Type sizes follow Apple, not the mock.** `Main_Design.html` draws text at its on-device size, and it is 2 to 4pt below platform guidance. The tokens use Apple's Dynamic Type defaults instead, keeping the design's proportions: screen title 34, section head 22, card title 20, row title 17, button 17, body 16, pill button 15, meta 14, eyebrow and button sub-line 12, never below 11. When building from the mock, map its sizes to the most relevant token; don't copy pixel sizes. Commit-bar buttons are 56px tall, so a label and sub-line must still fit.
- **Components** live in `ui/components/`. Check there before building something new. A component used by two screens moves there. One file per component, or a folder when it has variants (`components/button/` holds `AppButton` and `AppPillButton`).
- **Tappable things** build on `Pressable` (`ui/core/pressable.dart`). It gives semantics, a pressed fade and a dimmed disabled state (`onPressed: null`).
- Eyebrow text is uppercase in the design: call `.toUpperCase()` on the string; Flutter has no text-transform.
- Screen padding is `AppSpacing.gutter` (22) horizontally. Scrolling content ends with a 24px spacer.

## Design rules (from Main_Design.html)

- **Ember marks one thing per view**: the decision the user hasn't made. Graphite is ink, and at most one emphasized graphite surface per screen.
- **Only unmade decisions get button chrome.** A settled state is flat text ("You're in"), never a pill that looks pressable. An unanswered row's meta line says "no answer yet" in `emberInk`.
- **Commit bars:** 56px buttons, 10px gap. Primary on the right. Declining or secondary choices are outlined and narrower (104px). Two-line buttons put a bold verb over a quiet consequence ("you'll be number 65").
- **Shapes:** radii 10 pills/tiles, 12–14 small buttons, 16 rows and buttons, 18–20 cards, 26–28 sheets. Three elevations only: row, card, hero.
- **Type:** Instrument Serif for screen titles, section heads, the wordmark, pitch quotes, and numbers that are the point (counts, walk minutes). Archivo for everything else. Sentence case everywhere except eyebrows.
- **Copy:** no em dashes, no prime marks for minutes ("14 min", not 14′), no emoji. Every count states its unit in words.
- **Hit targets** are at least 44px; row buttons 36–40px tall. Meta lines don't wrap (`maxLines: 1`).
- **Horizontal shelves** bleed off the right edge instead of showing "+2". No visible scrollbars.
- **Icons** are SVG, never icon fonts.

## Naming

- Classes are named by role: `ThingsScreen`, `ThingsViewModel`, `ThingRepository` / `ThingRepositoryRemote` / `ThingRepositoryFake`, `ThingsApiService`, `ThingDto`. Display-state classes are `ThingRowState` and similar.
- "Model" never means a data type here: app types live in `types/`, server shapes are DTOs, and a view model is a screen's state and logic.
- Files are snake_case versions of the main class name.

## Code style

- Relative imports, grouped `dart:` / `package:` / relative, alphabetical within each group.
- Private named constructor parameters initialize fields directly: `ThingRepositoryRemote({required this._api, required this._webSocket})`.
- Use dot shorthands where the type is known (`crossAxisAlignment: .start`, `variant: .secondary`).
- Braces on every multi-line `if`.
- Doc comments (`///`) on public classes and on members whose purpose isn't obvious from the name. No comments that restate the code.
