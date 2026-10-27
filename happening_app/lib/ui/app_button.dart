import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant {
  /// Ember fill. One per view, for the decision the user hasn't made.
  primary,

  /// Outlined. For declining or secondary choices.
  secondary,
}

/// A 56px commit-bar button with an optional consequence line under the label.
class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final enabled = widget.onPressed != null;
    final primary = widget.variant == AppButtonVariant.primary;

    final decoration = primary
        ? BoxDecoration(
            color: theme.colors.ember,
            borderRadius: const BorderRadius.all(AppRadius.button),
            boxShadow: enabled ? AppShadows.ember : null,
          )
        : BoxDecoration(
            borderRadius: const BorderRadius.all(AppRadius.button),
            border: Border.all(color: theme.colors.outline, width: 1.5),
          );

    final labelStyle = primary ? theme.text.button : theme.text.button.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600);
    final subStyle = primary
        ? theme.text.buttonSub.copyWith(color: theme.colors.graphite.withValues(alpha: 0.65))
        : theme.text.buttonSub.copyWith(fontSize: 11);

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: !enabled ? 0.4 : (_pressed ? 0.8 : 1),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: decoration,
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Text(widget.label, style: labelStyle, textAlign: .center, maxLines: 1),
                if (widget.subLabel case final subLabel?)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(subLabel, style: subStyle, textAlign: .center, maxLines: 1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
