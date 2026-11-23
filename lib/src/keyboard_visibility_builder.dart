import 'package:flutter/widgets.dart';

/// Signature for [KeyboardVisibilityBuilder.builder].
typedef KeyboardVisibilityWidgetBuilder =
    Widget Function(BuildContext context, bool isKeyboardOpen, Widget? child);

/// Rebuilds when the soft keyboard opens or closes.
///
/// ```dart
/// KeyboardVisibilityBuilder(
///   builder: (context, isKeyboardOpen, child) {
///     return isKeyboardOpen ? const SizedBox.shrink() : const Logo();
///   },
/// )
/// ```
///
/// The keyboard state is read from the [View], not from the nearest
/// [MediaQuery]. That matters because a `Scaffold` with
/// `resizeToAvoidBottomInset: true` (the default) zeroes out
/// `MediaQuery.viewInsets` for its body, so checking
/// `MediaQuery.viewInsetsOf(context).bottom > 0` there always says the
/// keyboard is closed.
///
/// Only rebuilds when the open/closed state flips, not on every frame of the
/// keyboard animation.
class KeyboardVisibilityBuilder extends StatefulWidget {
  /// Creates a widget that rebuilds when the keyboard opens or closes.
  const KeyboardVisibilityBuilder({
    super.key,
    required this.builder,
    this.child,
  });

  /// Called with the current keyboard state.
  final KeyboardVisibilityWidgetBuilder builder;

  /// Passed through to [builder] untouched. Use it for the part of the
  /// subtree that doesn't depend on the keyboard, so it isn't rebuilt.
  final Widget? child;

  @override
  State<KeyboardVisibilityBuilder> createState() =>
      _KeyboardVisibilityBuilderState();
}

class _KeyboardVisibilityBuilderState extends State<KeyboardVisibilityBuilder>
    with WidgetsBindingObserver {
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The widget may have moved to a different View (multi-window).
    _isOpen = _readKeyboardOpen();
  }

  @override
  void didChangeMetrics() {
    final isOpen = _readKeyboardOpen();
    if (isOpen != _isOpen) {
      setState(() => _isOpen = isOpen);
    }
  }

  bool _readKeyboardOpen() {
    final view = View.maybeOf(context);
    return view != null && view.viewInsets.bottom > 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isOpen, widget.child);
  }
}
