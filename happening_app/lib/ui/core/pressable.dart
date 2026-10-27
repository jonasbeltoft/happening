import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Tap handling shared by all buttons: semantics, a pressed fade, and a
/// dimmed disabled state when [onPressed] is null.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  /// How long a finger must rest before the fade starts, so a touch that
  /// turns into a scroll doesn't flicker.
  static const _pressDelay = Duration(milliseconds: 50);

  /// Duration of the fade and shrink, both in and out.
  static const _pressAnimation = Duration(milliseconds: 100);

  bool _pressed = false;
  Offset? _downAt;

  /// Pending start of the fade.
  Timer? _pressTimer;

  /// Ends the brief fade shown for a tap quicker than [_pressDelay].
  Timer? _flashTimer;

  void _setPressed(bool value) {
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  // The fade is driven by raw pointer events rather than the tap recognizer,
  // which inside a scrollable waits ~100ms before reporting tap down.
  void _onDown(PointerDownEvent event) {
    _downAt = event.position;
    _flashTimer?.cancel();
    _pressTimer?.cancel();
    _pressTimer = Timer(_pressDelay, () {
      _pressTimer = null;
      _setPressed(true);
    });
  }

  // Moving past the touch slop means a scroll, not a tap.
  void _onMove(PointerMoveEvent event) {
    final downAt = _downAt;
    if (downAt != null && (event.position - downAt).distance > kTouchSlop) {
      _cancel();
    }
  }

  void _onUp(PointerUpEvent event) {
    _downAt = null;
    if (_pressTimer case final timer?) {
      // Released before the fade started: still show it briefly.
      timer.cancel();
      _pressTimer = null;
      _setPressed(true);
      _flashTimer = Timer(_pressDelay, () => _setPressed(false));
    } else {
      _setPressed(false);
    }
  }

  void _cancel() {
    _downAt = null;
    _pressTimer?.cancel();
    _pressTimer = null;
    _setPressed(false);
  }

  @override
  void dispose() {
    _pressTimer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: enabled ? _onDown : null,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: (_) => _cancel(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          // Gestures are detected outside the scale, so the hit area stays
          // full size while the button shrinks.
          child: AnimatedScale(
            duration: _pressAnimation,
            scale: _pressed ? 0.96 : 1,
            child: AnimatedOpacity(
              duration: _pressAnimation,
              opacity: !enabled ? 0.4 : (_pressed ? 0.65 : 1),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
