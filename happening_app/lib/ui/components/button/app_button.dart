import 'package:flutter/widgets.dart';

import '../../core/pressable.dart';
import '../../theme/app_theme.dart';

enum AppButtonVariant {
  /// Ember fill. One per view, for the decision the user hasn't made.
  primary,

  /// Outlined. For declining or secondary choices.
  secondary,
}

/// A 56px commit-bar button with an optional consequence line under the label.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.subLabel,
    this.variant = AppButtonVariant.primary,
  });

  final String label;

  /// e.g. "you'll be number 65" or "Tap to change".
  final String? subLabel;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final primary = variant == AppButtonVariant.primary;

    final decoration = primary
        ? BoxDecoration(
            color: theme.colors.ember,
            borderRadius: const BorderRadius.all(AppRadius.button),
            boxShadow: onPressed != null ? AppShadows.ember : null,
          )
        : BoxDecoration(
            borderRadius: const BorderRadius.all(AppRadius.button),
            border: Border.all(color: theme.colors.outline, width: 1.5),
          );

    final labelStyle = primary ? theme.text.button : theme.text.button.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
    final subStyle = primary
        ? theme.text.buttonSub.copyWith(color: theme.colors.graphite.withValues(alpha: 0.65))
        : theme.text.buttonSub;

    return Pressable(
      onPressed: onPressed,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: decoration,
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text(label, style: labelStyle, textAlign: .center, maxLines: 1),
            if (subLabel case final subLabel?)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(subLabel, style: subStyle, textAlign: .center, maxLines: 1),
              ),
          ],
        ),
      ),
    );
  }
}
