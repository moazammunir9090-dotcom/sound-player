import 'package:flutter/material.dart';

/// Breakpoints and measurements shared by every screen.
///
/// The app targets phones, tablets and a desktop Linux window from one
/// codebase, so layout decisions read from here rather than from raw
/// `MediaQuery` calls scattered around the widgets.
enum ScreenSize {
  /// Phones in portrait, and narrow desktop windows.
  compact,

  /// Large phones, tablets in portrait.
  medium,

  /// Tablets in landscape, desktop.
  expanded,
}

abstract final class Responsive {
  static const double compactMax = 620;
  static const double mediumMax = 1024;

  /// Widest a single column of body copy should ever get before it becomes
  /// uncomfortable to read.
  static const double readable = 760;

  /// Cap for form-like screens (settings, add sound) so fields do not stretch
  /// across a 4K monitor.
  static const double formWidth = 680;

  static ScreenSize sizeOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < compactMax) return ScreenSize.compact;
    if (w < mediumMax) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static bool isCompact(BuildContext context) =>
      sizeOf(context) == ScreenSize.compact;

  static bool isExpanded(BuildContext context) =>
      sizeOf(context) == ScreenSize.expanded;

  /// True when the player should lay its artwork and controls side by side
  /// instead of stacked — landscape phones included.
  static bool useWidePlayer(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    return mq.width >= 900 && mq.width > mq.height * 1.05;
  }

  /// Horizontal page gutter. Grows with the window but never eats the content.
  static double gutter(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 14;
    if (w < compactMax) return 20;
    if (w < mediumMax) return 32;
    return 44;
  }

  /// How many list columns fit comfortably at the current width.
  static int columns(BuildContext context, {double minTile = 220}) {
    final w = MediaQuery.sizeOf(context).width;
    final usable = w - gutter(context) * 2;
    return (usable / minTile).floor().clamp(1, 4);
  }

  /// A vertical gap that scales with the available height, clamped so it stays
  /// sane on both a short landscape window and a tall phone.
  static double adaptiveGap(
    BuildContext context, {
    double fraction = .03,
    double min = 8,
    double max = 32,
  }) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * fraction).clamp(min, max);
  }

  /// Text scale is reader-controlled, but past ~1.3 the fixed-height chrome
  /// (bottom bars, player controls) starts to overflow. Clamp it globally from
  /// [AppShell] rather than fighting it in every widget.
  static TextScaler clampedTextScaler(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
}

/// Centers content and caps its width — the standard wrapper for desktop.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({
    super.key,
    required this.child,
    this.maxWidth = Responsive.readable,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Makes a screen body scrollable *and* keeps it vertically centred when there
/// is spare room.
///
/// This is the app's answer to "responsive without overflow": the column is
/// built at its natural height, given a floor of the viewport height, and any
/// overflow becomes a scroll instead of a yellow-and-black stripe.
class ScrollablePage extends StatelessWidget {
  const ScrollablePage({
    super.key,
    required this.children,
    this.padding,
    this.center = false,
    this.maxWidth,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  /// When true the column is vertically centred inside the viewport.
  final bool center;
  final double? maxWidth;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final gutter = Responsive.gutter(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap the content width first, then let the scroll view work against
        // the capped height. Constraints are shrunk by the padding so the
        // centring maths below is exact.
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: children,
        );

        final bounded = maxWidth == null
            ? content
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth!),
                  child: content,
                ),
              );

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding:
              padding ?? EdgeInsets.fromLTRB(gutter, 8, gutter, gutter + 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: center
                  ? (constraints.maxHeight - gutter - 16).clamp(
                      0.0,
                      double.infinity,
                    )
                  : 0,
            ),
            child: center
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: crossAxisAlignment,
                    children: [bounded],
                  )
                : bounded,
          ),
        );
      },
    );
  }
}
