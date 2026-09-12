import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_info.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'utils/responsive.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Phone targets get the full-bleed look the splash and player are designed
  // around; desktop ignores this.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const SonoraApp());
}

class SonoraApp extends StatefulWidget {
  const SonoraApp({super.key});

  @override
  State<SonoraApp> createState() => _SonoraAppState();
}

class _SonoraAppState extends State<SonoraApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AppScope deliberately sits *above* MaterialApp: pushed routes build their
    // transition with `motionEnabled(context)`, which reads the scope, and a
    // route's context is a descendant of the Navigator, not of `home:`.
    return AppScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) => MaterialApp(
          title: AppInfo.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(accent: _state.accent),
          darkTheme: AppTheme.dark(accent: _state.accent),
          themeMode: _state.themeMode,
          scrollBehavior: const _AppScrollBehavior(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: Responsive.clampedTextScaler(context),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const _BootFlow(),
        ),
      ),
    );
  }
}

/// Lets a mouse and trackpad drag scrollables, which they do not do by default
/// — without this, the Linux desktop build can only scroll with the wheel.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

enum BootPhase { splash, onboarding, home }

/// Splash → onboarding → shell, cross-faded rather than pushed, so the app
/// opens as one continuous piece of motion.
class _BootFlow extends StatefulWidget {
  const _BootFlow();

  @override
  State<_BootFlow> createState() => _BootFlowState();
}

class _BootFlowState extends State<_BootFlow> {
  BootPhase _phase = BootPhase.splash;

  @override
  void initState() {
    super.initState();
    // A returning reader who already dismissed the tour goes straight in.
    if (AppScope.read(context).onboardingDone) {
      _phase = BootPhase.home;
    }
  }

  void _to(BootPhase phase) {
    if (!mounted || _phase == phase) return;
    setState(() => _phase = phase);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 620),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .97, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: switch (_phase) {
        BootPhase.splash => SplashScreen(
          key: const ValueKey<String>('splash'),
          onDone: () => _to(BootPhase.onboarding),
        ),
        BootPhase.onboarding => OnboardingScreen(
          key: const ValueKey<String>('onboarding'),
          onDone: () {
            AppScope.read(context).completeOnboarding();
            _to(BootPhase.home);
          },
        ),
        BootPhase.home => const HomeScreen(key: ValueKey<String>('home')),
      },
    );
  }
}
