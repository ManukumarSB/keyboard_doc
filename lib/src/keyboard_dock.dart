import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'keyboard_visibility_builder.dart';

/// When [KeyboardDock] shows its footer.
enum DockVisibility {
  /// Footer is always shown. It sits at the bottom of the screen and moves
  /// up with the keyboard.
  always,

  /// Footer only appears while the keyboard is open. Good for a "Done" bar
  /// or formatting toolbar.
  whenKeyboardOpen,

  /// Footer hides while the keyboard is open, e.g. a bottom banner that
  /// would otherwise eat into the space left for the form.
  whenKeyboardClosed,
}

/// Lays out [child] with a [footer] docked to the bottom that stays on top of
/// the soft keyboard.
///
/// ```dart
/// Scaffold(
///   body: KeyboardDock(
///     footer: FilledButton(onPressed: submit, child: Text('Continue')),
///     padding: EdgeInsets.all(16),
///     child: ListView(children: fields),
///   ),
/// )
/// ```
///
/// [child] gets whatever height is left above the footer, so a scrollable
/// child keeps the focused text field visible on its own.
///
/// While the keyboard is closed the footer is padded by the bottom safe area
/// (the iPhone home indicator, Android gesture bar). While it's open that
/// padding goes away, because the keyboard already covers it. The transition
/// follows the keyboard animation frame by frame.
///
/// Works whether or not the surrounding `Scaffold` has
/// `resizeToAvoidBottomInset` turned on.
class KeyboardDock extends StatelessWidget {
  /// Creates a layout with [footer] docked above the keyboard.
  const KeyboardDock({
    super.key,
    required this.child,
    required this.footer,
    this.visibility = DockVisibility.always,
    this.padding = EdgeInsets.zero,
    this.decoration,
    this.safeArea = true,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOut,
  });

  /// The main content. Gets all the height not taken by the footer.
  final Widget child;

  /// The widget docked at the bottom, usually a button or input bar.
  final Widget footer;

  /// When to show [footer]. Defaults to [DockVisibility.always].
  final DockVisibility visibility;

  /// Space around [footer], inside [decoration].
  final EdgeInsetsGeometry padding;

  /// Painted behind the footer, including the safe-area strip under it, so a
  /// background color or top border reaches the bottom edge of the screen.
  final Decoration? decoration;

  /// Whether to keep the footer clear of the system's bottom and side
  /// insets (home indicator, display cutouts in landscape).
  final bool safeArea;

  /// How long the footer takes to appear or disappear when [visibility]
  /// isn't [DockVisibility.always]. Ignored when the platform asks to
  /// disable animations.
  final Duration duration;

  /// The curve used with [duration].
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    Widget dock = _DockFooter(
      padding: padding,
      decoration: decoration,
      safeArea: safeArea,
      child: footer,
    );

    if (visibility != DockVisibility.always) {
      dock = KeyboardVisibilityBuilder(
        child: dock,
        builder: (context, isKeyboardOpen, dock) {
          final show =
              isKeyboardOpen == (visibility == DockVisibility.whenKeyboardOpen);
          return _Reveal(
            visible: show,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : duration,
            curve: curve,
            child: dock!,
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        dock,
      ],
    );
  }
}

/// The footer plus its bottom inset. Kept separate so only this rebuilds on
/// each frame of the keyboard animation.
class _DockFooter extends StatelessWidget {
  const _DockFooter({
    required this.padding,
    required this.decoration,
    required this.safeArea,
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final Decoration? decoration;
  final bool safeArea;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Inside a resizing Scaffold both of these are already reduced by the
    // keyboard height, so the same formula holds either way.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final system = safeArea ? MediaQuery.viewPaddingOf(context) : null;
    final bottom = math.max(keyboard, system?.bottom ?? 0);

    Widget result = Padding(padding: padding, child: child);
    if (system != null) {
      result = Padding(
        padding: EdgeInsets.only(left: system.left, right: system.right),
        child: result,
      );
    }
    result = Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: result,
    );

    if (decoration != null) {
      result = DecoratedBox(decoration: decoration!, child: result);
    }
    return result;
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.visible,
    required this.duration,
    required this.curve,
    required this.child,
  });

  final bool visible;
  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.visible ? 1 : 0,
  );
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  @override
  void didUpdateWidget(_Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    _animation.curve = widget.curve;
    if (widget.visible != oldWidget.visible) {
      widget.visible ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Fully hidden: drop it from layout, focus and semantics.
        if (_controller.isDismissed) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _animation.value,
            child: FadeTransition(opacity: _animation, child: child),
          ),
        );
      },
    );
  }
}
