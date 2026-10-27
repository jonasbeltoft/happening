// Example code: a reference for the architecture. Never import it from real
// features; copy the pattern instead.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/result.dart';
import '../../../data/repositories/example_event/example_event_repository.dart';
import '../../../data/repositories/example_event/example_event_repository_fake.dart'; // TEMP: reset
import '../../../data/services/api/api_exception.dart';
import '../../../types/example_event.dart';
import '../../core/command.dart';

/// One row on the events screen, already worded for display.
@immutable
class ExampleEventRowState {
  const ExampleEventRowState({
    required this.id,
    required this.title,
    required this.meta,
    required this.needsAnswer,
    required this.answer,
  });

  final String id;
  final String title;

  /// e.g. "20:30 · 12 min walk · 80 kr", or "20:30 · no answer yet".
  final String meta;

  /// Unanswered: show the ember button and highlight [meta].
  final bool needsAnswer;

  /// The settled answer ("You're in"), or null when [needsAnswer].
  final String? answer;
}

class ExampleEventsViewModel extends ChangeNotifier {
  ExampleEventsViewModel({required this._events}) {
    _sub = _events.nearby.listen(_onEvents);
    load = Command0(_events.refreshNearby)..execute();
    answer = Command1(_answer);
  }

  final ExampleEventRepository _events;
  late final StreamSubscription<List<ExampleEvent>> _sub;

  /// Loads the list. Runs once on creation; call again to retry.
  late final Command0<void> load;

  /// Answers an event with (eventId, rsvp).
  late final Command1<void, (String, ExampleRsvp)> answer;

  List<ExampleEventRowState> _rows = const [];
  List<ExampleEventRowState> get rows => _rows;

  String _summary = '';

  /// e.g. "4 events near you, 2 of them tonight."
  String get summary => _summary;

  String? _pendingId;

  /// Whether an answer for [eventId] is being saved.
  bool isAnswering(String eventId) => answer.running && _pendingId == eventId;

  String? get loadError => switch (load.result) {
    Error(:final error) => _describe(error),
    _ => null,
  };

  String? get answerError => switch (answer.result) {
    Error(:final error) => "Couldn't save your answer. ${_describe(error)}",
    _ => null,
  };

  // TEMP: reset for trying answers again. Only works with fake data, and
  // breaks the rule that view models only know the repository interface.
  bool get canReset => _events is ExampleEventRepositoryFake;
  void reset() {
    if (_events case final ExampleEventRepositoryFake fake) fake.reset();
  }

  @override
  void dispose() {
    _sub.cancel();
    load.dispose();
    answer.dispose();
    super.dispose();
  }

  Future<Result<void>> _answer((String, ExampleRsvp) args) async {
    final (eventId, rsvp) = args;
    _pendingId = eventId;
    final result = await _events.setRsvp(eventId, rsvp);
    _pendingId = null;
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  void _onEvents(List<ExampleEvent> events) {
    final sorted = [...events]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    _rows = sorted.map(_toRow).toList();

    final now = DateTime.now();
    final tonight = events.where((e) => _isSameDay(e.startsAt, now)).length;
    final unanswered = events.where((e) => e.rsvp == ExampleRsvp.none).length;
    _summary = [
      '${_count(events.length, 'event')} near you, $tonight of them tonight.',
      if (unanswered > 0)
        '${_count(unanswered, 'event')} still waiting on an answer from you.',
    ].join(' ');

    notifyListeners();
  }

  static ExampleEventRowState _toRow(ExampleEvent event) {
    final needsAnswer = event.rsvp == ExampleRsvp.none;
    final time = _formatTime(event.startsAt);
    final meta = needsAnswer
        ? '$time · no answer yet'
        : [
            time,
            if (event.walkMinutes case final minutes?) '$minutes min walk',
            event.isFree ? 'free' : '${event.priceKr} kr',
          ].join(' · ');

    return ExampleEventRowState(
      id: event.id,
      title: event.title,
      meta: meta,
      needsAnswer: needsAnswer,
      answer: switch (event.rsvp) {
        ExampleRsvp.going => "You're in",
        ExampleRsvp.interested => 'Interested',
        ExampleRsvp.none => null,
      },
    );
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// "20:30" today, "Fri 19:00" on other days.
  static String _formatTime(DateTime time) {
    final clock =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return _isSameDay(time, DateTime.now())
        ? clock
        : '${_weekdays[time.weekday - 1]} $clock';
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _count(int n, String noun) =>
      '$n ${n == 1 ? noun : '${noun}s'}';

  static String _describe(Exception error) => switch (error) {
    OfflineException() => "You're offline.",
    RequestTimeoutException() => 'The server is slow to answer.',
    UnauthorizedException() => 'Please log in again.',
    _ => 'Something went wrong.',
  };
}
