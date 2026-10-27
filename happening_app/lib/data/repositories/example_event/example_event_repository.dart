// Example code: a reference for the architecture. Never import it from real
// features; copy the pattern instead.

import '../../../core/result.dart';
import '../../../types/example_event.dart';

/// Source of truth for events. View models depend on this interface, never on
/// an implementation, so the fake and the remote one are interchangeable.
abstract class ExampleEventRepository {
  /// Events near the user. Emits the cached list on listen (if loaded), then
  /// again whenever it changes: after [refreshNearby], an RSVP, or a WebSocket
  /// update from the server.
  Stream<List<ExampleEvent>> get nearby;

  /// Loads [nearby] from the server.
  Future<Result<void>> refreshNearby();

  Future<Result<ExampleEvent>> setRsvp(String eventId, ExampleRsvp rsvp);

  void dispose();
}
