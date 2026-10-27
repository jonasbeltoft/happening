// Example code: a reference for the architecture. Never import it from real
// features; copy the pattern instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:happening_app/config/example_dependencies.dart';
import 'package:happening_app/main.dart';
import 'package:happening_app/ui/screens/example_events/example_events_screen.dart';
import 'package:happening_app/ui/screens/example_events/example_events_view_model.dart';

void main() {
  testWidgets('Example: shows nearby events and answers one', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: exampleFakeProviders,
        child: HappeningApp(
          // The view model lives as long as the screen and is disposed with it.
          home: ChangeNotifierProvider(
            create: (context) => ExampleEventsViewModel(events: context.read()),
            builder: (context, _) => ExampleEventsScreen(viewModel: context.read()),
          ),
        ),
      ),
    );

    expect(find.text('Loading events'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The list is scrollable, so only count rows that are built on screen.
    expect(find.text('Evening flea market'), findsOneWidget);
    final goingBefore = find.text("I'm going").evaluate().length;
    final inBefore = find.text("You're in").evaluate().length;
    expect(goingBefore, greaterThan(0));

    await tester.tap(find.text("I'm going").first);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text("I'm going"), findsNWidgets(goingBefore - 1));
    expect(find.text("You're in"), findsNWidgets(inBefore + 1));
  });
}
