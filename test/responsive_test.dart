import 'package:animation/screens/add_sound_screen.dart';
import 'package:animation/screens/home_screen.dart';
import 'package:animation/screens/onboarding_screen.dart';
import 'package:animation/screens/player_screen.dart';
import 'package:animation/screens/settings_screen.dart';
import 'package:animation/screens/splash_screen.dart';
import 'package:animation/state/app_state.dart';
import 'package:animation/theme/app_theme.dart';
import 'package:animation/widgets/press_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every screen, at every size the brief cares about.
///
/// A Flutter overflow does not throw — it paints a yellow-and-black stripe and
/// reports a `FlutterError` through the framework. `tester.takeException()`
/// surfaces exactly that, so this suite is the real guarantee that nothing
/// overflows on a narrow phone, a tablet, or a desktop window.
const Map<String, Size> _viewports = <String, Size>{
  'small phone': Size(320, 568),
  'phone': Size(390, 844),
  'phone landscape': Size(844, 390),
  'tablet': Size(834, 1112),
  'desktop': Size(1440, 900),
  'short desktop': Size(1280, 620),
};

/// Builds the screen under a themed MaterialApp with the app scope above it.
Widget _host(AppState state, Widget child) => AppScope(
  state: state,
  child: MaterialApp(theme: AppTheme.light(), home: child),
);

/// A state with a track selected but *not* playing, so no transport timer is
/// left running at the end of the test.
AppState _stateWithTrack() {
  final state = AppState();
  state.currentId = state.sounds.first.id;
  return state;
}

void _sizeTo(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void main() {
  for (final entry in _viewports.entries) {
    final name = entry.key;
    final size = entry.value;

    group(name, () {
      testWidgets('home screen lays out cleanly', (tester) async {
        _sizeTo(tester, size);
        final state = _stateWithTrack();
        addTearDown(state.dispose);

        await tester.pumpWidget(_host(state, const HomeScreen()));
        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull);
      });

      testWidgets('player screen lays out cleanly', (tester) async {
        _sizeTo(tester, size);
        final state = _stateWithTrack();
        addTearDown(state.dispose);

        await tester.pumpWidget(_host(state, const PlayerScreen()));
        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull);
      });

      testWidgets('settings screen lays out cleanly', (tester) async {
        _sizeTo(tester, size);
        final state = AppState();
        addTearDown(state.dispose);

        await tester.pumpWidget(_host(state, const SettingsScreen()));
        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull);
      });

      testWidgets('embedded settings lays out cleanly', (tester) async {
        _sizeTo(tester, size);
        final state = AppState();
        addTearDown(state.dispose);

        await tester.pumpWidget(
          _host(
            state,
            const Scaffold(body: SettingsView(embedded: true)),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull);
      });

      testWidgets('add sound screen lays out cleanly', (tester) async {
        _sizeTo(tester, size);
        final state = AppState();
        addTearDown(state.dispose);

        await tester.pumpWidget(_host(state, const AddSoundScreen()));
        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull);
      });

      testWidgets('splash screen lays out cleanly', (tester) async {
        _sizeTo(tester, size);
        final state = AppState();
        addTearDown(state.dispose);

        await tester.pumpWidget(
          _host(state, SplashScreen(onDone: () {})),
        );
        // The splash schedules its exit at ~2.9s; pump past it so the test does
        // not end with a pending timer.
        await tester.pump(const Duration(milliseconds: 3400));

        expect(tester.takeException(), isNull);
      });

      testWidgets('every onboarding page lays out cleanly', (tester) async {
        _sizeTo(tester, size);
        final state = AppState();
        addTearDown(state.dispose);

        await tester.pumpWidget(
          _host(state, OnboardingScreen(onDone: () {})),
        );
        await tester.pump(const Duration(milliseconds: 600));

        // The CTA reads "Next" until the last page, where it becomes the call
        // to action — so step through by tapping it rather than by index.
        for (var page = 0; page < 3; page++) {
          expect(tester.takeException(), isNull, reason: 'onboarding page $page');
          await tester.tap(find.byType(BrandButton));
          await tester.pump(const Duration(milliseconds: 800));
        }
        expect(tester.takeException(), isNull, reason: 'onboarding final page');
      });
    });
  }

  group('player tabs', () {
    testWidgets('every panel renders without overflowing', (tester) async {
      _sizeTo(tester, const Size(390, 844));
      final state = _stateWithTrack();
      addTearDown(state.dispose);

      await tester.pumpWidget(_host(state, const PlayerScreen()));
      await tester.pump(const Duration(milliseconds: 600));

      for (final label in const ['LYRICS', 'RELATED', 'UP NEXT']) {
        await tester.tap(find.text(label));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull, reason: 'panel $label');
      }
    });
  });

  group('home tabs', () {
    testWidgets('library and settings tabs render without overflowing', (
      tester,
    ) async {
      _sizeTo(tester, const Size(390, 844));
      final state = AppState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_host(state, const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 600));

      for (final label in const ['Library', 'Settings', 'Home']) {
        await tester.tap(find.text(label).last);
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull, reason: 'tab $label');
      }
    });

    testWidgets('a long track title ellipsises instead of overflowing', (
      tester,
    ) async {
      _sizeTo(tester, const Size(320, 568));
      final state = _stateWithTrack();
      addTearDown(state.dispose);

      state.currentId = state.sounds.first.id;
      await tester.pumpWidget(
        _host(
          state,
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: PlayerScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
    });
  });
}
