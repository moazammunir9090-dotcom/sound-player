import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Builds both [ThemeData]s from a single [AppPalette].
///
/// Type scale, radii, control sizes and component themes all live here so the
/// screens stay declarative — a screen describes *what* it is, not how round
/// its corners are.
abstract final class AppTheme {
  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 26;
  static const double radiusXl = 34;

  /// The signature sweep, exposed for widgets that need it without a context.
  static const LinearGradient brandSweep = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light({AccentPreset accent = AccentPreset.ember}) =>
      _build(AppPalette.light.withAccent(
        primary: accent.primary,
        secondary: accent.secondary,
      ));

  static ThemeData dark({AccentPreset accent = AccentPreset.ember}) =>
      _build(AppPalette.dark.withAccent(
        primary: accent.primary,
        secondary: accent.secondary,
      ));

  static ThemeData _build(AppPalette p) {
    final isDark = p.background.computeLuminance() < .2;

    final scheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: p.orange,
      onPrimary: Colors.white,
      primaryContainer: p.orangeWash,
      onPrimaryContainer: p.textPrimary,
      secondary: p.blue,
      onSecondary: Colors.white,
      secondaryContainer: p.blueWash,
      onSecondaryContainer: p.textPrimary,
      tertiary: p.blue,
      onTertiary: Colors.white,
      error: p.danger,
      onError: Colors.white,
      errorContainer: p.danger.withValues(alpha: .16),
      onErrorContainer: p.textPrimary,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh: p.surfaceAlt,
      surfaceContainerHighest: p.surfaceSunken,
      outline: p.textFaint,
      outlineVariant: p.divider,
      shadow: p.shadow,
      scrim: Colors.black,
      inverseSurface: isDark ? p.surfaceAlt : p.textPrimary,
      onInverseSurface: isDark ? p.textPrimary : p.surface,
      inversePrimary: p.orangeDeep,
    );

    final text = _textTheme(p);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[p],
      textTheme: text,
      primaryTextTheme: text,

      // The app paints its own headers; the AppBar is only ever a transparent
      // host for back buttons and titles.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
        iconTheme: IconThemeData(color: p.textPrimary, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: p.divider),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 1,
      ),

      iconTheme: IconThemeData(color: p.textPrimary, size: 22),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        showDragHandle: true,
        dragHandleColor: p.textFaint.withValues(alpha: .4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? p.surfaceSunken : p.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isDark ? p.textPrimary : p.surface,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: p.surfaceSunken,
          disabledForegroundColor: p.textFaint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.blue,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.divider),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.textPrimary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: p.textFaint),
        labelStyle: text.bodyMedium?.copyWith(color: p.textSecondary),
        floatingLabelStyle: text.bodySmall?.copyWith(
          color: p.orange,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
        border: _inputBorder(p.divider),
        enabledBorder: _inputBorder(p.divider),
        focusedBorder: _inputBorder(p.orange, width: 1.6),
        errorBorder: _inputBorder(p.danger),
        focusedErrorBorder: _inputBorder(p.danger, width: 1.6),
        errorStyle: text.bodySmall?.copyWith(color: p.danger),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: p.orange,
        inactiveTrackColor: p.surfaceSunken,
        secondaryActiveTrackColor: p.blue.withValues(alpha: .35),
        thumbColor: p.orange,
        overlayColor: p.orangeWash,
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        valueIndicatorColor: p.orange,
        valueIndicatorTextStyle: text.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.white
              : (isDark ? p.textFaint : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.orange : p.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.orange : p.divider,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceAlt,
        selectedColor: p.orangeWash,
        side: BorderSide(color: p.divider),
        labelStyle: text.labelMedium?.copyWith(color: p.textSecondary),
        secondaryLabelStyle: text.labelMedium?.copyWith(
          color: p.orange,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: p.textPrimary,
        unselectedLabelColor: p.textFaint,
        indicatorColor: p.orange,
        dividerColor: Colors.transparent,
        labelStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: text.labelMedium,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? p.surfaceSunken : p.textPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: text.bodySmall?.copyWith(
          color: isDark ? p.textPrimary : p.surface,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.orange,
        linearTrackColor: p.surfaceSunken,
        circularTrackColor: p.surfaceSunken,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// One type scale for the whole app. Sizes are deliberately a touch tight —
  /// the small end carries most of the UI, which is what keeps a dense player
  /// screen from ever needing to scroll on a phone.
  static TextTheme _textTheme(AppPalette p) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 52,
        height: 1.05,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
        color: p.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 40,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        color: p.textPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: p.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -.7,
        color: p.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
        color: p.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -.35,
        color: p.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -.2,
        color: p.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -.1,
        color: p.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15.5,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: p.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: p.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: p.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14.5,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: .1,
        color: p.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: .3,
        color: p.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: .8,
        color: p.textFaint,
      ),
    );
  }
}
