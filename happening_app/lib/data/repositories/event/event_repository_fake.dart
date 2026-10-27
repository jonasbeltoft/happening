import 'dart:async';

import '../../../core/result.dart';
import '../../../types/event.dart';
import 'event_repository.dart';

/// In-memory events for building screens without a server, and for tests.
class EventRepositoryFake implements EventRepository {
  EventRepositoryFake({this.latency = const Duration(milliseconds: 300)});

  /// Simulated network delay.
  final Duration latency;

  List<Event>? _nearby;
  final _nearbyController = StreamController<List<Event>>.broadcast();

  @override
  Stream<List<Event>> get nearby async* {
    if (_nearby case final events?) yield events;
    yield* _nearbyController.stream;
  }

  @override
  Future<Result<void>> refreshNearby() async {
    await Future<void>.delayed(latency);
    _emit(_nearby ?? _sample());
    return const Result.ok(null);
  }

  @override
  Future<Result<Event>> setRsvp(String eventId, Rsvp rsvp) async {
    await Future<void>.delayed(latency);
    final events = _nearby ?? const [];
    final index = events.indexWhere((e) => e.id == eventId);
    if (index == -1) return Result.error(Exception('No event $eventId'));

    final old = events[index];
    final delta =
        (rsvp == Rsvp.going ? 1 : 0) - (old.rsvp == Rsvp.going ? 1 : 0);
    final updated = old.copyWith(
      rsvp: rsvp,
      goingCount: old.goingCount + delta,
    );
    _emit([...events]..[index] = updated);
    return Result.ok(updated);
  }

  // TEMP: restores the sample data so answers can be tried again.
  void reset() => _emit(_sample());

  @override
  void dispose() => _nearbyController.close();

  void _emit(List<Event> events) {
    _nearby = List.unmodifiable(events);
    _nearbyController.add(_nearby!);
  }

  static List<Event> _sample() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      Event(
        id: 'vinyl-bakken',
        title: 'Vinyl night at Bakken',
        venue: 'Bakken, Kødbyen',
        startsAt: today.add(const Duration(hours: 20)),
        endsAt: today.add(const Duration(hours: 25)),
        walkMinutes: 12,
        priceKr: 80,
        goingCount: 64,
        friendsGoing: 3,
        rsvp: Rsvp.going,
      ),
      Event(
        id: 'harbour-swim',
        title: 'Harbour swim & sauna',
        venue: 'Islands Brygge',
        startsAt: today.add(const Duration(hours: 20, minutes: 30)),
        walkMinutes: 18,
        goingCount: 22,
        friendsGoing: 1,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'open-mic-absalon',
        title: 'Open mic, Absalon',
        venue: 'Absalon, Vesterbro',
        startsAt: today.add(const Duration(hours: 21)),
        walkMinutes: 9,
        goingCount: 41,
        friendsGoing: 0,
        rsvp: Rsvp.interested,
      ),
      Event(
        id: 'rooftop-dinner',
        title: 'Rooftop dinner, Nørrebro',
        venue: 'Jægersborggade',
        startsAt: today.add(const Duration(days: 3, hours: 19)),
        walkMinutes: 24,
        priceKr: 150,
        goingCount: 9,
        friendsGoing: 2,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'flea-market-ravnsborg',
        title: 'Evening flea market',
        venue: 'Ravnsborggade',
        startsAt: today.add(const Duration(hours: 17)),
        walkMinutes: 15,
        goingCount: 130,
        friendsGoing: 4,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'natural-wine-tasting',
        title: 'Natural wine tasting',
        venue: 'Ved Stranden 10',
        startsAt: today.add(const Duration(hours: 18)),
        walkMinutes: 7,
        priceKr: 175,
        goingCount: 18,
        friendsGoing: 1,
        rsvp: Rsvp.going,
      ),
      Event(
        id: 'pub-quiz-mikkeller',
        title: 'Pub quiz at Mikkeller',
        venue: 'Viktoriagade',
        startsAt: today.add(const Duration(hours: 19)),
        walkMinutes: 11,
        goingCount: 36,
        friendsGoing: 5,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'cinema-paradise',
        title: 'Outdoor cinema, Paradise Bio',
        venue: 'Kongens Have',
        startsAt: today.add(const Duration(hours: 19, minutes: 30)),
        walkMinutes: 20,
        priceKr: 60,
        goingCount: 210,
        friendsGoing: 2,
        rsvp: Rsvp.interested,
      ),
      Event(
        id: 'jazz-la-fontaine',
        title: 'Late jazz session',
        venue: 'La Fontaine',
        startsAt: today.add(const Duration(hours: 22)),
        walkMinutes: 6,
        priceKr: 50,
        goingCount: 27,
        friendsGoing: 0,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'techno-ksb',
        title: 'Techno night at KB18',
        venue: 'Kødboderne 18',
        startsAt: today.add(const Duration(hours: 23, minutes: 30)),
        walkMinutes: 13,
        priceKr: 120,
        goingCount: 340,
        friendsGoing: 6,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'morning-run-faelled',
        title: 'Morning run in Fælledparken',
        venue: 'Fælledparken',
        startsAt: today.add(const Duration(days: 1, hours: 7)),
        walkMinutes: 17,
        goingCount: 14,
        friendsGoing: 1,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'ceramics-workshop',
        title: 'Ceramics workshop',
        venue: 'Studio Nørrebro',
        startsAt: today.add(const Duration(days: 1, hours: 18)),
        walkMinutes: 22,
        priceKr: 250,
        goingCount: 8,
        friendsGoing: 0,
        rsvp: Rsvp.going,
      ),
      Event(
        id: 'board-games-bastard',
        title: 'Board games night',
        venue: 'Bastard Café',
        startsAt: today.add(const Duration(days: 1, hours: 19, minutes: 30)),
        walkMinutes: 5,
        goingCount: 45,
        friendsGoing: 3,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'street-food-reffen',
        title: 'Street food at Reffen',
        venue: 'Refshaleøen',
        startsAt: today.add(const Duration(days: 2, hours: 17)),
        walkMinutes: 35,
        goingCount: 520,
        friendsGoing: 7,
        rsvp: Rsvp.interested,
      ),
      Event(
        id: 'poetry-reading',
        title: 'Poetry reading',
        venue: 'Paludan Bogcafé',
        startsAt: today.add(const Duration(days: 2, hours: 20)),
        walkMinutes: 8,
        goingCount: 19,
        friendsGoing: 0,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'salsa-social',
        title: 'Salsa social, beginners welcome',
        venue: 'Huset',
        startsAt: today.add(const Duration(days: 4, hours: 20)),
        walkMinutes: 10,
        priceKr: 40,
        goingCount: 62,
        friendsGoing: 2,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'sunday-football',
        title: 'Sunday football, Fælleden',
        venue: 'Fælledparken',
        startsAt: today.add(const Duration(days: 5, hours: 11)),
        walkMinutes: 17,
        goingCount: 14,
        friendsGoing: 4,
        rsvp: Rsvp.none,
      ),
      Event(
        id: 'harbour-kayak',
        title: 'Harbour kayak tour',
        venue: 'Christianshavn',
        startsAt: today.add(const Duration(days: 5, hours: 14)),
        walkMinutes: 19,
        priceKr: 300,
        goingCount: 12,
        friendsGoing: 1,
        rsvp: Rsvp.going,
      ),
    ];
  }
}
