import 'package:flutter/material.dart';

/// Every colour the app paints, for one brightness.
///
/// Screens never hard-code a [Color] — they read tokens through
/// `context.palette`. That keeps light and dark in lockstep and makes the
/// orange/blue brand a single-file change.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.orange,
    required this.orangeDeep,
    required this.orangeWash,
    required this.orangeInk,
    required this.blue,
    required this.blueDeep,
    required this.blueWash,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textFaint,
    required this.divider,
    required this.shadow,
    required this.success,
    required this.danger,
    required this.blobOne,
    required this.blobTwo,
  });

  /// Brand accent 1 — primary actions, "now playing" states, the warm half of
  /// the signature sweep.
  final Color orange;
  final Color orangeDeep;
  final Color orangeWash;

  /// [orange] adapted to be *read* on top of [orangeWash].
  ///
  /// The accent is tuned to be seen as a large filled shape — an arc, a glow, a
  /// button — and at full strength it sits too close in luminance to its own
  /// wash to work as a label or a small glyph. Measured against the wash, light
  /// mode lands between 2.1:1 and 4.4:1 for every preset, and dark mode fails
  /// for azure (2.9:1) and violet (3.4:1). Use this token for anything drawn
  /// *on* a wash; keep [orange] for fills, borders and gradients.
  final Color orangeInk;

  /// Brand accent 2 — progress, selection, the cool half of the sweep.
  final Color blue;
  final Color blueDeep;
  final Color blueWash;

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceSunken;

  final Color textPrimary;
  final Color textSecondary;
  final Color textFaint;

  final Color divider;
  final Color shadow;
  final Color success;
  final Color danger;

  /// Two low-opacity washes for the animated background blobs.
  final Color blobOne;
  final Color blobTwo;

  /// The app's signature orange -> blue sweep.
  LinearGradient get brandGradient => LinearGradient(
    colors: [orange, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// A softer sweep used for washes behind artwork and headers.
  LinearGradient get washGradient => LinearGradient(
    colors: [orangeWash, blueWash],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// A card is lifted off the background by a hairline border in dark mode and
  /// a soft ambient shadow in light mode. These two helpers keep that rule in
  /// one place instead of repeated at every call site.
  List<BoxShadow> lift({double blur = 24, double y = 10, double alpha = .10}) {
    return [
      BoxShadow(
        color: shadow.withValues(alpha: alpha),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
    ];
  }

  static const AppPalette light = AppPalette(
    orange: Color(0xFFF97316),
    orangeDeep: Color(0xFFEA580C),
    orangeWash: Color(0x1FF97316),
    orangeInk: Color(0xFFA7521C),
    blue: Color(0xFF2563EB),
    blueDeep: Color(0xFF1D4ED8),
    blueWash: Color(0x1F2563EB),
    background: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFF2F9),
    surfaceSunken: Color(0xFFE6EAF4),
    textPrimary: Color(0xFF0E1526),
    textSecondary: Color(0xFF5B6784),
    textFaint: Color(0xFF98A2B8),
    divider: Color(0x14202B45),
    shadow: Color(0xFF0E1526),
    success: Color(0xFF16A34A),
    danger: Color(0xFFDC2626),
    blobOne: Color(0x33F97316),
    blobTwo: Color(0x2E2563EB),
  );

  static const AppPalette dark = AppPalette(
    orange: Color(0xFFFF8A3D),
    orangeDeep: Color(0xFFF97316),
    orangeWash: Color(0x2EFF8A3D),
    orangeInk: Color(0xFFFF8A3D),
    blue: Color(0xFF5B9CFF),
    blueDeep: Color(0xFF3B82F6),
    blueWash: Color(0x2E5B9CFF),
    background: Color(0xFF080B14),
    surface: Color(0xFF121826),
    surfaceAlt: Color(0xFF1A2133),
    surfaceSunken: Color(0xFF232B40),
    textPrimary: Color(0xFFF1F5FE),
    textSecondary: Color(0xFF9AA6C2),
    textFaint: Color(0xFF6B7793),
    divider: Color(0x1FFFFFFF),
    shadow: Color(0xFF000000),
    success: Color(0xFF34D399),
    danger: Color(0xFFF87171),
    blobOne: Color(0x40FF8A3D),
    blobTwo: Color(0x3D5B9CFF),
  );

  /// Re-colours the brand accents while keeping the current brightness. The
  /// settings screen uses this to offer accent variants without shipping a
  /// second full palette for each one.
  AppPalette withAccent({required Color primary, required Color secondary}) {
    final isDark = background.computeLuminance() < .2;
    final washAlpha = isDark ? .18 : .12;
    return copyWith(
      orange: primary,
      orangeDeep: _darken(primary),
      orangeWash: primary.withValues(alpha: washAlpha),
      orangeInk: _inkOn(primary, primary.withValues(alpha: washAlpha)),
      blue: secondary,
      blueDeep: _darken(secondary),
      blueWash: secondary.withValues(alpha: washAlpha),
      blobOne: primary.withValues(alpha: isDark ? .25 : .20),
      blobTwo: secondary.withValues(alpha: isDark ? .24 : .18),
    );
  }

  /// The nearest tint of [accent] that clears 4.5:1 against [wash].
  ///
  /// Mixing toward the body text colour moves the accent away from the wash's
  /// luminance in whichever direction the current brightness needs — darker on
  /// a light wash, lighter on a dark one. Deriving it instead of listing it per
  /// preset means a new accent cannot ship an unreadable label.
  Color _inkOn(Color accent, Color wash) {
    final backdrop = Color.alphaBlend(wash, surface);
    for (var t = 0.0; t < 1; t += .05) {
      final candidate = Color.lerp(accent, textPrimary, t)!;
      if (_contrast(candidate, backdrop) >= 4.5) return candidate;
    }
    return textPrimary;
  }

  /// WCAG 2.1 contrast ratio, the same scale `_inkOn` targets.
  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + .05) / (lo + .05);
  }

  static Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - .10).clamp(0.0, 1.0)).toColor();
  }

  @override
  AppPalette copyWith({
    Color? orange,
    Color? orangeDeep,
    Color? orangeWash,
    Color? orangeInk,
    Color? blue,
    Color? blueDeep,
    Color? blueWash,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceSunken,
    Color? textPrimary,
    Color? textSecondary,
    Color? textFaint,
    Color? divider,
    Color? shadow,
    Color? success,
    Color? danger,
    Color? blobOne,
    Color? blobTwo,
  }) {
    return AppPalette(
      orange: orange ?? this.orange,
      orangeDeep: orangeDeep ?? this.orangeDeep,
      orangeWash: orangeWash ?? this.orangeWash,
      orangeInk: orangeInk ?? this.orangeInk,
      blue: blue ?? this.blue,
      blueDeep: blueDeep ?? this.blueDeep,
      blueWash: blueWash ?? this.blueWash,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textFaint: textFaint ?? this.textFaint,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      blobOne: blobOne ?? this.blobOne,
      blobTwo: blobTwo ?? this.blobTwo,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      orange: mix(orange, other.orange),
      orangeDeep: mix(orangeDeep, other.orangeDeep),
      orangeWash: mix(orangeWash, other.orangeWash),
      orangeInk: mix(orangeInk, other.orangeInk),
      blue: mix(blue, other.blue),
      blueDeep: mix(blueDeep, other.blueDeep),
      blueWash: mix(blueWash, other.blueWash),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      surfaceSunken: mix(surfaceSunken, other.surfaceSunken),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textFaint: mix(textFaint, other.textFaint),
      divider: mix(divider, other.divider),
      shadow: mix(shadow, other.shadow),
      success: mix(success, other.success),
      danger: mix(danger, other.danger),
      blobOne: mix(blobOne, other.blobOne),
      blobTwo: mix(blobTwo, other.blobTwo),
    );
  }
}

/// Accent presets offered in settings. All stay inside the orange/blue family
/// so the app never drifts off-brand.
enum AccentPreset {
  ember('Ember', Color(0xFFF97316), Color(0xFF2563EB)),
  azure('Azure', Color(0xFF2563EB), Color(0xFF06B6D4)),
  sunset('Sunset', Color(0xFFFB7185), Color(0xFFF97316)),
  violet('Violet', Color(0xFF8B5CF6), Color(0xFF2563EB));

  const AccentPreset(this.label, this.primary, this.secondary);

  final String label;
  final Color primary;
  final Color secondary;
}

/// Ergonomic token access: `context.palette.orange`.
extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
