import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happening_app/main.dart';
import 'package:happening_app/ui/screens/home/home_screen.dart';
import 'package:happening_app/ui/theme/app_theme.dart';

void main() {
  testWidgets('Starts on an empty chalk home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HappeningApp());

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(Text), findsNothing);

    final background = tester.widget<ColoredBox>(find.byType(ColoredBox).first);
    expect(background.color, AppColors.light.chalk);
  });
}
