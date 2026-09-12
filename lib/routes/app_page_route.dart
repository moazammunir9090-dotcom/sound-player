import 'package:flutter/material.dart';

import '../utils/motion.dart';

/// Names for the [Hero] flights between the home list and the player.
///
/// Centralised so a tag collision between two lists (which would blow up at
/// runtime with a duplicate-tag assertion) is impossible to introduce by
/// accident.
abstract final class HeroTags {
  static String artwork(String id) => 'artwork-$id';
  static String title(String id) => 'title-$id';
  static String playButton(String id) => 'play-$id';
}

/// The screen-entry animations the app uses.
enum AppTransition {
  /// Horizontal push with a slight lift. The default for forward navigation.
  sharedAxis,

  /// Scale-and-fade from the centre. Used when the destination is a *mode*
  /// rather than a place — Add Sound, for example.
  fadeThrough,

  /// Rises from the bottom edge. Reads as "this is about to take over".
  slideUp,

  /// Cross-dissolve with no movement; the splash and onboarding hand-off.
  fade,
}

/// A [PageRoute] that carries one of the [AppTransition] animations.
///
/// `PageRouteBuilder` is the right base here rather than the platform default:
/// the app's motion language is its own, and it must be identical on Linux,
/// Android and iOS.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  // `transition` and `duration` are declared as plain parameters (not
  // `this.transition`) so the `transitionsBuilder` closure below can capture
  // them as locals — an initializer list may not touch `this`.
  AppPageRoute({
    required WidgetBuilder builder,
    AppTransition transition = AppTransition.sharedAxis,
    Duration duration = const Duration(milliseconds: 420),
    super.settings,
    super.fullscreenDialog,
  }) : transition = transition,
       duration = duration,
       super(
         transitionDuration: duration,
         reverseTransitionDuration: const Duration(milliseconds: 320),
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondary, child) {
           // Respect "reduce motion" / the Rich motion toggle: cross-fade only.
           if (!motionEnabled(context)) {
             return FadeTransition(opacity: animation, child: child);
           }
           switch (transition) {
             case AppTransition.sharedAxis:
               return _sharedAxis(animation, secondary, child);
             case AppTransition.fadeThrough:
               return _fadeThrough(animation, child);
             case AppTransition.slideUp:
               return _slideUp(animation, child);
             case AppTransition.fade:
               return FadeTransition(opacity: animation, child: child);
           }
         },
       );

  final AppTransition transition;
  final Duration duration;
}

Widget _sharedAxis(
  Animation<double> animation,
  Animation<double> secondary,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  // The outgoing page drifts a little the other way — that contrast is what
  // makes a push feel like depth rather than a swap.
  final exit = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-.04, 0),
  ).animate(
    CurvedAnimation(parent: secondary, curve: Curves.easeOutCubic),
  );

  return SlideTransition(
    position: exit,
    child: AnimatedBuilder(
      animation: curved,
      builder: (context, inner) {
        final t = curved.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset((1 - t) * 44, 0),
            child: Transform.scale(scale: .985 + .015 * t, child: inner),
          ),
        );
      },
      child: child,
    ),
  );
}

Widget _fadeThrough(Animation<double> animation, Widget child) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  );
  return AnimatedBuilder(
    animation: curved,
    builder: (context, inner) {
      final t = curved.value;
      return Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: .93 + .07 * t, child: inner),
      );
    },
    child: child,
  );
}

Widget _slideUp(Animation<double> animation, Widget child) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  return AnimatedBuilder(
    animation: curved,
    builder: (context, inner) {
      final t = curved.value;
      return Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 60),
          child: inner,
        ),
      );
    },
    child: child,
  );
}
