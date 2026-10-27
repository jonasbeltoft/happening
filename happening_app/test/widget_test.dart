import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:happening_app/config/dependencies.dart';
import 'package:happening_app/main.dart';

void main() {
  testWidgets('Shows nearby events and answers one', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(providers: fakeProviders, child: const HappeningApp()));

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
