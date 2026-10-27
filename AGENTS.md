# Happening

- Never ``git commit``. `git` commands are READ ONLY for you.

## APP

- The Flutter app lives in `happening_app/`.
- Dont build unless told so. Only type check.

### UI

- No UI library. Do not import `package:flutter/material.dart` or `package:flutter/cupertino.dart`; use `package:flutter/widgets.dart` only.
- The app root is a `WidgetsApp`, not `MaterialApp`.
- Design tokens (colors, text styles, spacing, radius) live in `happening_app/lib/theme/app_theme.dart`. Read them with `AppTheme.of(context)`. Do not hardcode colors or sizes in widgets; add a token instead.
- Reusable components live in `happening_app/lib/ui/`. Check there before building a new one, and put new shared components there.
