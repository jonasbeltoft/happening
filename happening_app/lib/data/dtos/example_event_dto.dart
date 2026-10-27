// Example code: a reference for the architecture. Never import it from real
// features; copy the pattern instead.

import 'package:flutter/foundation.dart';

/// An event exactly as the server sends it. Only the data layer sees this;
/// repositories map it to the app type `ExampleEvent` (lib/types).
@immutable
class ExampleEventDto {
  const ExampleEventDto({
    required this.id,
    required this.title,
    required this.venue,
    required this.startsAt,
    required this.endsAt,
    required this.walkMinutes,
    required this.priceKr,
    required this.goingCount,
    required this.friendsGoing,
    required this.rsvp,
  });

  /// Throws on a missing or mistyped field; `ApiClient` turns that into a
  /// `BadResponseException`.
  factory ExampleEventDto.fromJson(Object? json) {
    if (json is! Map<String, Object?>) throw FormatException('Expected an event object, got $json');
    return ExampleEventDto(
      id: json['id'] as String,
      title: json['title'] as String,
      venue: json['venue'] as String,
      startsAt: json['startsAt'] as String,
      endsAt: json['endsAt'] as String?,
      walkMinutes: json['walkMinutes'] as int?,
      priceKr: json['priceKr'] as int?,
      goingCount: json['goingCount'] as int,
      friendsGoing: json['friendsGoing'] as int,
      rsvp: json['rsvp'] as String,
    );
  }

  static List<ExampleEventDto> listFromJson(Object? json) {
    if (json is! List<Object?>) throw FormatException('Expected a list of events, got $json');
    return json.map(ExampleEventDto.fromJson).toList();
  }

  final String id;
  final String title;
  final String venue;

  /// ISO 8601.
  final String startsAt;
  final String? endsAt;
  final int? walkMinutes;

  /// Null when free.
  final int? priceKr;
  final int goingCount;
  final int friendsGoing;

  /// `none`, `interested` or `going`.
  final String rsvp;
}
