import 'package:flutter_test/flutter_test.dart';

import 'package:happening_app/main.dart';
import 'package:happening_app/ui/app_button.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HappeningApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.widgetWithText(AppButton, 'Add one'));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
