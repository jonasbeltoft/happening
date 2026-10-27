import 'package:flutter/widgets.dart';

import 'theme/app_theme.dart';
import 'ui/app_button.dart';

void main() {
  runApp(const HappeningApp());
}

class HappeningApp extends StatelessWidget {
  const HappeningApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light;

    return WidgetsApp(
      title: "It's Happening",
      color: theme.colors.ember,
      debugShowCheckedModeBanner: false,
      pageRouteBuilder: <T>(settings, builder) =>
          PageRouteBuilder<T>(settings: settings, pageBuilder: (context, _, _) => builder(context)),
      builder: (context, child) => AppThemeScope(
        theme: theme,
        child: ColoredBox(color: theme.colors.chalk, child: child),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 18, AppSpacing.gutter, AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text('Your week', style: theme.text.screenTitle),
            const SizedBox(height: 6),
            Text('Nothing planned yet', style: theme.text.meta),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Text('$_counter', style: theme.text.numeral),
                    const SizedBox(height: 5),
                    Text('taps so far', style: theme.text.meta),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 104,
                  child: AppButton(
                    label: 'Reset',
                    variant: .secondary,
                    onPressed: _counter == 0 ? null : () => setState(() => _counter = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Add one',
                    subLabel: 'you will be at ${_counter + 1}',
                    onPressed: () => setState(() => _counter++),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
