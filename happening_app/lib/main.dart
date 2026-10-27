import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/dependencies.dart';
import 'ui/screens/events/events_screen.dart';
import 'ui/screens/events/events_view_model.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: AppConfig.useFakeData ? fakeProviders : remoteProviders,
      child: const HappeningApp(),
    ),
  );
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
      // The view model lives as long as the screen and is disposed with it.
      home: ChangeNotifierProvider(
        create: (context) => EventsViewModel(events: context.read()),
        builder: (context, _) => EventsScreen(viewModel: context.read()),
      ),
    );
  }
}
