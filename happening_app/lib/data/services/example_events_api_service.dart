// Example code: a reference for the architecture. Never import it from real
// features; copy the pattern instead.

import '../../core/result.dart';
import '../dtos/example_event_dto.dart';
import 'api/api_client.dart';

/// ExampleEvent endpoints. Stateless: one method per endpoint, no caching or mapping.
///
/// The paths are placeholders until the server API exists.
class ExampleEventsApiService {
  ExampleEventsApiService(this._client);

  final ApiClient _client;

  Future<Result<List<ExampleEventDto>>> listNearby() =>
      _client.get('/events', ExampleEventDto.listFromJson);

  Future<Result<ExampleEventDto>> getEvent(String id) =>
      _client.get('/events/$id', ExampleEventDto.fromJson);

  /// [rsvp] is `none`, `interested` or `going`. Returns the updated event.
  Future<Result<ExampleEventDto>> setRsvp(String id, String rsvp) =>
      _client.put('/events/$id/rsvp', {'rsvp': rsvp}, ExampleEventDto.fromJson);
}
