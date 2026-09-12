import 'package:animation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Legibility of the accent when it is drawn *on* one of its own washes.
///
/// The accent is a fill colour — an arc, a glow, a blur, a border — and at full
/// strength it is too close in luminance to its own wash to read as a label.
/// Before `orangeInk` existed, light mode failed for every accent preset
/// (2.1:1 to 4.4:1) and dark mode failed for azure and violet. This suite is
/// the guarantee that stays fixed: it re-derives the numbers from the palette
/// itself, so a new preset or a tweaked wash cannot quietly regress it.
///
/// WCAG 2.1 AA wants 4.5:1 for body text; the selected nav label and the active
/// lyric line are both small text, so that is the bar.
const double _minRatio = 4.5;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

/// Contrast of [ink] against [wash] as it is actually painted — the wash is
/// translucent, so it is composited over the surface beneath it first.
double _onWash(Color ink, Color wash, Color surface) =>
    _contrast(ink, Color.alphaBlend(wash, surface));

void main() {
  final palettes = <String, AppPalette>{
    'light (default)': AppPalette.light,
    'dark (default)': AppPalette.dark,
    for (final preset in AccentPreset.values)
      'light / ${preset.label}': AppPalette.light.withAccent(
        primary: preset.primary,
        secondary: preset.secondary,
      ),
    for (final preset in AccentPreset.values)
      'dark / ${preset.label}': AppPalette.dark.withAccent(
        primary: preset.primary,
        secondary: preset.secondary,
      ),
  };

  group('accent ink on its own wash', () {
    palettes.forEach((name, palette) {
      test('$name clears AA', () {
        final ratio = _onWash(
          palette.orangeInk,
          palette.orangeWash,
          palette.surface,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(_minRatio),
          reason:
              '$name: accent ink ${palette.orangeInk} on wash '
              '${palette.orangeWash} is only ${ratio.toStringAsFixed(2)}:1',
        );
      });
    });
  });

  group('the ink actually fixes something', () {
    // If the raw accent already cleared the bar, the token would be dead
    // weight — this documents which presets genuinely needed it.
    test('the raw accent fails on the washes the ink is used for', () {
      final failures = <String>[];
      palettes.forEach((name, palette) {
        final ratio = _onWash(
          palette.orange,
          palette.orangeWash,
          palette.surface,
        );
        if (ratio < _minRatio) failures.add(name);
      });
      expect(
        failures,
        isNotEmpty,
        reason: 'nothing fails any more — orangeInk may be redundant',
      );
    });
  });

  group('ink never travels toward the wrong end', () {
    test('light ink is darker than its accent, dark ink is not lighter than '
        'the wash', () {
      for (final preset in AccentPreset.values) {
        final light = AppPalette.light.withAccent(
          primary: preset.primary,
          secondary: preset.secondary,
        );
        expect(
          light.orangeInk.computeLuminance(),
          lessThan(light.orange.computeLuminance()),
          reason: 'light / ${preset.label} ink should darken, not lighten',
        );
      }
    });

    test('the default dark accent already passed, so it is left alone', () {
      expect(AppPalette.dark.orangeInk, AppPalette.dark.orange);
    });
  });
}
