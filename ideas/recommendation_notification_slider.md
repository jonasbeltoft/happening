# Feature: Recommendation Notification Slider

## Summary
One slider in settings controls how many **event recommendation notifications** a user gets. Far left turns them off. Far right sends almost every nearby public event. The stops in between narrow the stream step by step, ending in a small set of highly personalized events picked by an ML model trained on the user's data.

The slider only governs *recommendations* (events the user hasn't been invited to). Direct invites from friends, and updates for events the user has joined, are not affected.

## Slider stops

The slider snaps to discrete stops (not a continuous value), so behavior is predictable and easy to explain in the UI.

Reading left to right, the volume grows. The right-hand side is broad, the middle-left is the most selective.

| Stop | Label (draft) | What the user gets |
|---|---|---|
| 0 | **Off** | No recommendation notifications at all. Recommendations still appear in the in-app feed. |
| 1 | **Only perfect matches** | Very few. Only events the ML model scores as an exceptionally strong fit for this user. |
| 2 | **Personal picks** | Events with a high personalization score: matches interests, past attendance, friends going, etc. |
| 3 | **Things you might like** | Events that loosely match preferences (category, time of day, distance), with light ML ranking. |
| 4 | **Everything nearby** | Almost all public events within the user's radius, minimal filtering (spam, duplicates, blocked hosts removed). |

Open question: four "on" stops versus three. Five total positions feels right on a phone, but this is easy to tune later.

## How each stop works

Every candidate event (public, nearby, not already joined or declined) gets a **relevance score from 0 to 1** from the recommender. Each stop is just a threshold on that score plus a frequency cap:

| Stop | Score threshold | Max notifications (draft) |
|---|---|---|
| Off | n/a | 0 |
| Only perfect matches | ≥ 0.9 | ~1 per week |
| Personal picks | ≥ 0.7 | ~3 per week |
| Things you might like | ≥ 0.4 | ~1 per day |
| Everything nearby | any (after safety filters) | batched, e.g. a daily digest beyond a few per day |

Keeping it as threshold + cap means the slider UI never changes when the model improves; only the scores get better.

Before there's enough data for ML (new users, early launch), the score can come from simple rules: matching categories, distance, time preferences, friends attending. The ML model replaces this later behind the same interface.

## Signals for personalization (ML input)
- Stated preferences from onboarding (categories, vibe, group size)
- Events joined, attended, hosted
- Events viewed, saved, dismissed, or ignored
- Notification feedback: opened, dismissed, "not interested"
- Friends' attendance
- Typical distance travelled and preferred days/times

Notification interactions should feed back into the model, so dismissals at a given stop tighten what that user sees.

## UX notes
- Show the current stop's label and a one-line description under the slider so the user knows what they're choosing.
- Optionally show an estimate like "about 2 a week near you" based on recent volume.
- Ask during onboarding with a sensible default (suggest **Personal picks**), and keep it in Settings › Notifications.
- If the OS notification permission is denied, show the slider disabled with a prompt to enable notifications.
- Distance radius is a separate setting; the slider controls selectivity, not range.

## Flutter implementation notes (for later)
- `Slider` with `divisions: 4` (min 0, max 4) gives discrete snapping out of the box; custom labels below it via a `Row`.
- Store the stop as an enum on the user profile server side, so the backend decides what to send (push via FCM for both iOS and Android).
- Selection logic lives on the server, not the client: the app only saves the stop.

## Open questions
- Exact number of stops and their labels.
- Whether "Everything nearby" should switch to a digest automatically in busy areas.
- Quiet hours: part of this feature or a separate setting?
- Should the slider also affect ranking in the in-app feed, or notifications only?
