import 'package:flutter/widgets.dart';

import '../../core/pressable.dart';
import '../../theme/app_theme.dart';

/// The small ember button at the end of a row, for an unanswered decision
/// ("I'm going"). A settled state is plain text instead, never a pill.
class AppPillButton extends StatelessWidget {
  const AppPillButton({super.key, required this.label, required this.onPressed});

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Pressable(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colors.ember,
          borderRadius: const BorderRadius.all(AppRadius.pill),
          boxShadow: onPressed != null ? AppShadows.emberSmall : null,
        ),
        child: Text(label, style: theme.text.buttonSmall, maxLines: 1),
      ),
    );
  }
}
