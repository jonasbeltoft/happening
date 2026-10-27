// Example code: a reference for the architecture. Never import it from real
// features; copy the pattern instead.

import 'dart:async';

import '../../../core/result.dart';
import '../../../types/example_event.dart';
import '../../dtos/example_event_dto.dart';
import '../../services/example_events_api_service.dart';
import '../../services/websocket/websocket_client.dart';
import 'example_event_repository.dart';

/// Loads events over REST and keeps them current with WebSocket messages on
/// the `events` topic.
class ExampleEventRepositoryRemote implements ExampleEventRepository {
  ExampleEventRepositoryRemote({required this._api, required this._webSocket}) {
    // Updates sent while the socket was down are lost; refetch to catch up.
    _reconnectSub = _webSocket.reconnected.listen((_) {
      if (_nearbyController.hasListener) refreshNearby();
    });
  }

  static const _topic = 'events';

  final ExampleEventsApiService _api;
  final WebSocketClient _webSocket;

  List<ExampleEvent>? _nearby;
  late final StreamSubscription<void> _reconnectSub;
  StreamSubscription<WebSocketMessage>? _topicSub;

  // The WebSocket topic is only subscribed while someone is listening.
  late final _nearbyController = StreamController<List<ExampleEvent>>.broadcast(
    onListen: () =>
        _topicSub = _webSocket.topic(_topic).listen(_onWebSocketMessage),
    onCancel: () {
      _topicSub?.cancel();
      _topicSub = null;
    },
  );

  @override
  Stream<List<ExampleEvent>> get nearby async* {
    if (_nearby case final events?) yield events;
    yield* _nearbyController.stream;
  }

  @override
  Future<Result<void>> refreshNearby() async {
    switch (await _api.listNearby()) {
      case Ok(:final value):
        _emit(value.map(_fromDto).toList());
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  @override
  Future<Result<ExampleEvent>> setRsvp(String eventId, ExampleRsvp rsvp) async {
    switch (await _api.setRsvp(eventId, rsvp.name)) {
      case Ok(:final value):
        final event = _fromDto(value);
        _upsert(event);
        return Result.ok(event);
      case Error(:final error):
        return Result.error(error);
    }
  }

  @override
  void dispose() {
    _reconnectSub.cancel();
    _topicSub?.cancel();
    _nearbyController.close();
  }

  void _onWebSocketMessage(WebSocketMessage message) {
    try {
      switch (message.type) {
        case 'event.updated':
          _upsert(_fromDto(ExampleEventDto.fromJson(message.data)));
        case 'event.removed':
          final id = (message.data as Map<String, Object?>)['id'] as String;
          if (_nearby case final events?) {
            _emit(events.where((e) => e.id != id).toList());
          }
      }
    } catch (_) {
      // Ignore malformed pushes; the next refresh corrects the list.
    }
  }

  void _upsert(ExampleEvent event) {
    final events = _nearby;
    if (events == null) return;
    final index = events.indexWhere((e) => e.id == event.id);
    _emit(index == -1 ? [...events, event] : ([...events]..[index] = event));
  }

  void _emit(List<ExampleEvent> events) {
    _nearby = List.unmodifiable(events);
    _nearbyController.add(_nearby!);
  }

  static ExampleEvent _fromDto(ExampleEventDto dto) => ExampleEvent(
    id: dto.id,
    title: dto.title,
    venue: dto.venue,
    startsAt: DateTime.parse(dto.startsAt).toLocal(),
    endsAt: dto.endsAt == null ? null : DateTime.parse(dto.endsAt!).toLocal(),
    walkMinutes: dto.walkMinutes,
    priceKr: dto.priceKr,
    goingCount: dto.goingCount,
    friendsGoing: dto.friendsGoing,
    rsvp: ExampleRsvp.values.asNameMap()[dto.rsvp] ?? ExampleRsvp.none,
  );
}
