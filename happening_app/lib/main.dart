import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/dependencies.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  final providers = AppConfig.useFakeData ? fakeProviders : remoteProviders;
  // MultiProvider asserts a non-empty list.
  runApp(providers.isEmpty ? const HappeningApp() : MultiProvider(providers: providers, child: const HappeningApp()));
}

class HappeningApp extends StatelessWidget {
  const HappeningApp({super.key, this.home = const HomeScreen()});

  /// The first screen. Tests pass a different one.
  final Widget home;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light;

    return WidgetsApp(
      title: 'Happening',
      color: theme.colors.ember,
      debugShowCheckedModeBanner: false,
      pageRouteBuilder: <T>(settings, builder) =>
          PageRouteBuilder<T>(settings: settings, pageBuilder: (context, _, _) => builder(context)),
      builder: (context, child) => AppThemeScope(
        theme: theme,
        child: ColoredBox(color: theme.colors.chalk, child: child),
      ),
      home: home,
    );
  }
}
