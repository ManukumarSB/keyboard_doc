import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_dock/keyboard_dock.dart';

const _screen = Size(400, 800);
const _homeIndicator = 34.0;
const _keyboard = 300.0;
const _footerHeight = 50.0;

final _footerKey = GlobalKey();

void _setUpView(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = _screen
    ..viewPadding = const FakeViewPadding(bottom: _homeIndicator);
  addTearDown(tester.view.reset);
}

void _openKeyboard(WidgetTester tester) {
  tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
}

void _closeKeyboard(WidgetTester tester) {
  tester.view.viewInsets = FakeViewPadding.zero;
}

Widget _app({
  DockVisibility visibility = DockVisibility.always,
  bool? resizeToAvoidBottomInset,
  bool safeArea = true,
  Decoration? decoration,
}) {
  return MaterialApp(
    home: Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: KeyboardDock(
        visibility: visibility,
        safeArea: safeArea,
        decoration: decoration,
        footer: SizedBox(key: _footerKey, height: _footerHeight),
        child: const Placeholder(),
      ),
    ),
  );
}

Rect _footerRect(WidgetTester tester) => tester.getRect(find.byKey(_footerKey));

void main() {
  group('KeyboardDock', () {
    testWidgets('sits above the home indicator when keyboard is closed', (
      tester,
    ) async {
      _setUpView(tester);
      await tester.pumpWidget(_app());

      expect(_footerRect(tester).bottom, _screen.height - _homeIndicator);
    });

    testWidgets('ignores the home indicator when safeArea is false', (
      tester,
    ) async {
      _setUpView(tester);
      await tester.pumpWidget(_app(safeArea: false));

      expect(_footerRect(tester).bottom, _screen.height);
    });

    for (final resize in [true, false]) {
      testWidgets('sits right on top of the keyboard '
          '(resizeToAvoidBottomInset: $resize)', (tester) async {
        _setUpView(tester);
        await tester.pumpWidget(_app(resizeToAvoidBottomInset: resize));

        _openKeyboard(tester);
        await tester.pump();

        // No home-indicator gap stacked on top of the keyboard.
        expect(_footerRect(tester).bottom, _screen.height - _keyboard);
      });
    }

    testWidgets('child gets the space above the footer', (tester) async {
      _setUpView(tester);
      await tester.pumpWidget(_app());
      _openKeyboard(tester);
      await tester.pump();

      final child = tester.getRect(find.byType(Placeholder));
      expect(child.bottom, _footerRect(tester).top);
    });

    testWidgets('keeps the footer clear of the home indicator while the '
        'keyboard is still small', (tester) async {
      _setUpView(tester);
      await tester.pumpWidget(_app());

      // First frames of the keyboard animation.
      tester.view.viewInsets = const FakeViewPadding(bottom: 10);
      await tester.pump();

      expect(_footerRect(tester).bottom, _screen.height - _homeIndicator);
    });

    testWidgets('decoration reaches the bottom edge of the screen', (
      tester,
    ) async {
      _setUpView(tester);
      await tester.pumpWidget(
        _app(decoration: const BoxDecoration(color: Colors.red)),
      );

      final box = tester.getRect(
        find
            .ancestor(
              of: find.byKey(_footerKey),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(box.bottom, _screen.height);
    });

    testWidgets('whenKeyboardOpen shows the footer only with the keyboard', (
      tester,
    ) async {
      _setUpView(tester);
      await tester.pumpWidget(
        _app(visibility: DockVisibility.whenKeyboardOpen),
      );
      expect(find.byKey(_footerKey), findsNothing);

      _openKeyboard(tester);
      await tester.pumpAndSettle();
      expect(_footerRect(tester).bottom, _screen.height - _keyboard);

      _closeKeyboard(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(_footerKey), findsNothing);
    });

    testWidgets('whenKeyboardClosed hides the footer while typing', (
      tester,
    ) async {
      _setUpView(tester);
      await tester.pumpWidget(
        _app(visibility: DockVisibility.whenKeyboardClosed),
      );
      expect(find.byKey(_footerKey), findsOneWidget);

      _openKeyboard(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(_footerKey), findsNothing);

      // The content gets the full height above the keyboard back.
      final child = tester.getRect(find.byType(Placeholder));
      expect(child.bottom, _screen.height - _keyboard);
    });

    testWidgets('animates the footer in', (tester) async {
      _setUpView(tester);
      await tester.pumpWidget(
        _app(visibility: DockVisibility.whenKeyboardOpen),
      );

      _openKeyboard(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final height = tester
          .getSize(
            find
                .ancestor(
                  of: find.byKey(_footerKey),
                  matching: find.byType(ClipRect),
                )
                .first,
          )
          .height;
      expect(height, greaterThan(0));
      expect(height, lessThan(_footerHeight));
    });

    testWidgets('skips the animation when animations are disabled', (
      tester,
    ) async {
      _setUpView(tester);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _app(visibility: DockVisibility.whenKeyboardOpen),
        ),
      );

      _openKeyboard(tester);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(_footerKey), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('KeyboardVisibilityBuilder', () {
    testWidgets('sees the keyboard inside a resizing Scaffold', (tester) async {
      _setUpView(tester);
      final states = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardVisibilityBuilder(
              builder: (context, isKeyboardOpen, _) {
                states.add(isKeyboardOpen);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      _openKeyboard(tester);
      await tester.pump();
      _closeKeyboard(tester);
      await tester.pump();

      expect(states, [false, true, false]);
    });

    testWidgets('does not rebuild on every frame of the keyboard animation', (
      tester,
    ) async {
      _setUpView(tester);
      var builds = 0;

      await tester.pumpWidget(
        KeyboardVisibilityBuilder(
          builder: (context, isKeyboardOpen, _) {
            builds++;
            return const SizedBox();
          },
        ),
      );

      for (final inset in [50.0, 120.0, 200.0, 300.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump();
      }

      expect(builds, 2);
    });

    testWidgets('passes child through', (tester) async {
      const child = Text('hi', textDirection: TextDirection.ltr);
      Widget? received;

      await tester.pumpWidget(
        KeyboardVisibilityBuilder(
          child: child,
          builder: (context, isKeyboardOpen, child) {
            received = child;
            return child!;
          },
        ),
      );

      expect(received, same(child));
    });
  });
}
