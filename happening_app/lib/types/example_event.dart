// Example code: a reference for the architecture. Never import it from real
// features; copy the pattern instead.

import 'package:flutter/foundation.dart';

/// The current user's answer to an event.
enum ExampleRsvp { none, interested, going }

/// An event as the app uses it. Immutable; change it with [copyWith].
@immutable
class ExampleEvent {
  const ExampleEvent({
    required this.id,
    required this.title,
    required this.venue,
    required this.startsAt,
    this.endsAt,
    this.walkMinutes,
    this.priceKr,
    required this.goingCount,
    required this.friendsGoing,
    required this.rsvp,
  });

  final String id;
  final String title;
  final String venue;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int? walkMinutes;

  /// Null when free.
  final int? priceKr;
  final int goingCount;
  final int friendsGoing;
  final ExampleRsvp rsvp;

  bool get isFree => priceKr == null;

  ExampleEvent copyWith({int? goingCount, int? friendsGoing, ExampleRsvp? rsvp}) => ExampleEvent(
    id: id,
    title: title,
    venue: venue,
    startsAt: startsAt,
    endsAt: endsAt,
    walkMinutes: walkMinutes,
    priceKr: priceKr,
    goingCount: goingCount ?? this.goingCount,
    friendsGoing: friendsGoing ?? this.friendsGoing,
    rsvp: rsvp ?? this.rsvp,
  );
}
