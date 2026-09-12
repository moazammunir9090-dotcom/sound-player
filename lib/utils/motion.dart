import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';

/// Decides whether decorative motion should run.
///
/// Two things can switch it off: the platform's "reduce motion" accessibility
/// setting, and the in-app *Rich motion* toggle in Settings. Every animated
/// widget in the app asks this first, so one switch calms the whole UI.
bool motionEnabled(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return false;
  return AppScope.read(context).richMotion;
}

/// Convenience for the common "animate, or snap if motion is off" pattern.
Duration motionDuration(BuildContext context, Duration duration) =>
    motionEnabled(context) ? duration : Duration.zero;

/// Short haptic tick, gated by the Settings toggle.
///
/// [HapticFeedback] is already a silent no-op on Linux, Windows and web, so
/// desktop builds need no special casing.
void tapFeedback(BuildContext context, {bool strong = false}) {
  if (!AppScope.read(context).haptics) return;
  if (strong) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.selectionClick();
  }
}
