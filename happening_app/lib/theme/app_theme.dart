import 'package:flutter/widgets.dart';

// Tokens follow design/Main_Design.html ("Chalk & Ember").

/// Color tokens. Add new tokens here rather than hardcoding colors in widgets.
///
/// Ember marks one thing per view: the decision the user hasn't made.
/// Graphite is ink, and at most one emphasised surface per screen.
@immutable
class AppColors {
  const AppColors({
    required this.ember,
    required this.emberInk,
    required this.emberLight,
    required this.emberTint,
    required this.graphite,
    required this.ink2,
    required this.muted,
    required this.faint,
    required this.chalk,
    required this.card,
    required this.canvas,
    required this.media,
    required this.onGraphite,
    required this.hairline,
    required this.outline,
  });

  /// Primary call to action and live dots.
  final Color ember;

  /// Ember-colored text on light backgrounds (e.g. "no answer yet").
  final Color emberInk;

  /// Eyebrows and highlights on graphite.
  final Color emberLight;

  /// Invite cards and "Going" badges.
  final Color emberTint;

  /// Primary ink and the contrast surface.
  final Color graphite;
  final Color ink2;
  final Color muted;
  final Color faint;

  /// Screen background.
  final Color chalk;
  final Color card;
  final Color canvas;

  /// Image and map placeholders.
  final Color media;

  /// Text on graphite surfaces.
  final Color onGraphite;

  /// Dividers and row borders.
  final Color hairline;

  /// Secondary button border.
  final Color outline;

  static const light = AppColors(
    ember: Color(0xFFFF7E00),
    emberInk: Color(0xFFD34F00),
    emberLight: Color(0xFFFCBA70),
    emberTint: Color(0xFFFFF1E4),
    graphite: Color(0xFF17181B),
    ink2: Color(0xFF5B5D62),
    muted: Color(0xFF85878E),
    faint: Color(0xFFA9ABB1),
    chalk: Color(0xFFFAF8F4),
    card: Color(0xFFFFFFFF),
    canvas: Color(0xFFE8E4DC),
    media: Color(0xFFE3DED4),
    onGraphite: Color(0xFFF7F5F1),
    hairline: Color(0x1417181B),
    outline: Color(0x3317181B),
  );
}

/// Font families, bundled in assets/fonts and registered in pubspec.yaml.
abstract final class AppFonts {
  /// Screen titles, section heads, numerals and the wordmark.
  static const serif = 'Instrument Serif';

  /// Everything else.
  static const sans = 'Archivo';
}

/// Text style tokens, already colored.
///
/// Eyebrows are uppercase in the design; call `.toUpperCase()` on the string,
/// since Flutter has no text-transform.
@immutable
class AppTextStyles {
  AppTextStyles(AppColors colors)
    : wordmark = TextStyle(
        fontFamily: AppFonts.serif,
        fontStyle: FontStyle.italic,
        fontSize: 54,
        height: 1,
        letterSpacing: -0.54,
        color: colors.graphite,
      ),
      screenTitle = TextStyle(fontFamily: AppFonts.serif, fontSize: 30, height: 1, color: colors.graphite),
      sectionHead = TextStyle(fontFamily: AppFonts.serif, fontSize: 21, height: 1.1, color: colors.graphite),
      numeral = TextStyle(fontFamily: AppFonts.serif, fontSize: 30, height: 1, color: colors.graphite),
      pitch = TextStyle(
        fontFamily: AppFonts.serif,
        fontStyle: FontStyle.italic,
        fontSize: 21,
        height: 1.3,
        color: colors.graphite,
      ),
      cardTitle = TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 19,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: colors.graphite,
      ),
      rowTitle = TextStyle(fontFamily: AppFonts.sans, fontSize: 15, fontWeight: FontWeight.w600, color: colors.graphite),
      body = TextStyle(fontFamily: AppFonts.sans, fontSize: 13.5, height: 1.5, color: colors.ink2),
      meta = TextStyle(fontFamily: AppFonts.sans, fontSize: 12.5, fontWeight: FontWeight.w500, color: colors.muted),
      eyebrow = TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.47,
        color: colors.muted,
      ),
      button = TextStyle(fontFamily: AppFonts.sans, fontSize: 15.5, fontWeight: FontWeight.w700, color: colors.graphite),
      buttonSub = TextStyle(fontFamily: AppFonts.sans, fontSize: 11.5, fontWeight: FontWeight.w500, color: colors.muted);

  /// Italic serif, splash only.
  final TextStyle wordmark;

  /// 30–32 in the design.
  final TextStyle screenTitle;
  final TextStyle sectionHead;

  /// Counts, walk minutes and dates when the number is the point.
  final TextStyle numeral;

  /// The organizer's one-line quote on an event page.
  final TextStyle pitch;
  final TextStyle cardTitle;
  final TextStyle rowTitle;
  final TextStyle body;
  final TextStyle meta;
  final TextStyle eyebrow;
  final TextStyle button;

  /// The quiet consequence line under a button label.
  final TextStyle buttonSub;
}

/// Spacing scale in logical pixels.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Horizontal screen padding.
  static const double gutter = 22;
}

/// Corner radius scale.
abstract final class AppRadius {
  static const pill = Radius.circular(10);
  static const tile = Radius.circular(12);
  static const button = Radius.circular(16);
  static const row = Radius.circular(16);
  static const card = Radius.circular(20);
  static const sheet = Radius.circular(28);
}

/// The three elevations. Shadows are short and vertical.
abstract final class AppShadows {
  static const _hairline = BoxShadow(color: Color(0x0F17181B), offset: Offset(0, 1), blurRadius: 2);

  static const row = [_hairline];

  static const card = [
    _hairline,
    BoxShadow(color: Color(0x5917181B), offset: Offset(0, 6), blurRadius: 14, spreadRadius: -10),
  ];

  /// Hero cards and sheets.
  static const hero = [
    _hairline,
    BoxShadow(color: Color(0x6617181B), offset: Offset(0, 14), blurRadius: 30, spreadRadius: -18),
  ];

  /// Glow under the primary ember button.
  static const ember = [
    BoxShadow(color: Color(0xBFFF7E00), offset: Offset(0, 10), blurRadius: 24, spreadRadius: -10),
  ];
}

@immutable
class AppTheme {
  AppTheme(this.colors) : text = AppTextStyles(colors);

  final AppColors colors;
  final AppTextStyles text;

  static final light = AppTheme(AppColors.light);

  static AppTheme of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'No AppThemeScope found in context');
    return scope!.theme;
  }
}

/// Provides [AppTheme] to the subtree, plus a matching default text style.
class AppThemeScope extends InheritedWidget {
  AppThemeScope({super.key, required this.theme, required Widget child})
    : super(child: DefaultTextStyle(style: theme.text.body, child: child));

  final AppTheme theme;

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) => theme != oldWidget.theme;
}
