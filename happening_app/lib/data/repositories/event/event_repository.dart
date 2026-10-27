import '../../../core/result.dart';
import '../../../types/event.dart';

/// Source of truth for events. View models depend on this interface, never on
/// an implementation, so the fake and the remote one are interchangeable.
abstract class EventRepository {
  /// Events near the user. Emits the cached list on listen (if loaded), then
  /// again whenever it changes: after [refreshNearby], an RSVP, or a WebSocket
  /// update from the server.
  Stream<List<Event>> get nearby;

  /// Loads [nearby] from the server.
  Future<Result<void>> refreshNearby();

  Future<Result<Event>> setRsvp(String eventId, Rsvp rsvp);

  void dispose();
}
