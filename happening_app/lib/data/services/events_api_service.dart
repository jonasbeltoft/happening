import '../../core/result.dart';
import '../dtos/event_dto.dart';
import 'api/api_client.dart';

/// Event endpoints. Stateless: one method per endpoint, no caching or mapping.
///
/// The paths are placeholders until the server API exists.
class EventsApiService {
  EventsApiService(this._client);

  final ApiClient _client;

  Future<Result<List<EventDto>>> listNearby() =>
      _client.get('/events', EventDto.listFromJson);

  Future<Result<EventDto>> getEvent(String id) =>
      _client.get('/events/$id', EventDto.fromJson);

  /// [rsvp] is `none`, `interested` or `going`. Returns the updated event.
  Future<Result<EventDto>> setRsvp(String id, String rsvp) =>
      _client.put('/events/$id/rsvp', {'rsvp': rsvp}, EventDto.fromJson);
}
