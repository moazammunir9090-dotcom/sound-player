import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/motion.dart';

/// The soft, slowly drifting wash of orange and blue that sits behind every
/// screen.
///
/// Built from radial gradients rather than blurred circles: a radial gradient
/// already *is* a soft falloff, so this costs a fraction of an
/// `ImageFilter.blur` and stays smooth on a full-screen Linux window.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    this.child,
    this.intensity = 1,
    this.drift = true,
    this.showGrid = false,
  });

  final Widget? child;

  /// Scales the opacity of the blobs. `1` for normal screens, higher for the
  /// splash, lower for dense screens like Add Sound.
  final double intensity;

  /// When false the blobs are painted once, static. Used as a fallback when
  /// motion is switched off.
  final bool drift;

  /// Faint dotted grid — only the splash uses it.
  final bool showGrid;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldRun = widget.drift && motionEnabled(context);
    if (shouldRun && !_running) {
      _running = true;
      _c.repeat();
    } else if (!shouldRun && _running) {
      _running = false;
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ColoredBox(
      color: palette.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value * 2 * math.pi;
                return Stack(
                  children: [
                    _Blob(
                      color: palette.blobOne,
                      intensity: widget.intensity,
                      alignment: Alignment(
                        -.75 + math.sin(t) * .22,
                        -.90 + math.cos(t * .8) * .16,
                      ),
                      size: .95,
                    ),
                    _Blob(
                      color: palette.blobTwo,
                      intensity: widget.intensity,
                      alignment: Alignment(
                        .85 + math.cos(t * .7) * .20,
                        .80 + math.sin(t * .9) * .18,
                      ),
                      size: 1.05,
                    ),
                    _Blob(
                      color: palette.blobOne,
                      intensity: widget.intensity * .6,
                      alignment: Alignment(
                        -.20 + math.cos(t * .5) * .35,
                        .35 + math.sin(t * .6) * .28,
                      ),
                      size: .70,
                    ),
                  ],
                );
              },
            ),
          ),
          if (widget.showGrid)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DotGridPainter(
                    color: palette.textPrimary.withValues(alpha: .05),
                  ),
                ),
              ),
            ),
          if (widget.child != null) Positioned.fill(child: widget.child!),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.alignment,
    required this.size,
    required this.intensity,
  });

  final Color color;
  final Alignment alignment;

  /// Fraction of the shorter viewport edge.
  final double size;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final diameter = mq.shortestSide * size * 1.6;
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(
                    alpha: (color.a * intensity).clamp(0.0, 1.0),
                  ),
                  color.withValues(alpha: 0),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.color});

  final Color color;

  static const double _spacing = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const radius = 1.1;
    for (double y = _spacing / 2; y < size.height; y += _spacing) {
      for (double x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A translucent panel used for the player's floating control bar and the mini
/// player.
///
/// Deliberately *not* a `BackdropFilter`: over a low-contrast gradient wash a
/// blur is nearly invisible but costs a full-screen offscreen pass per frame.
/// A translucent surface reads the same and stays cheap on a large window.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 26,
    this.border = true,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool border;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = context.isDark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? palette.surface.withValues(alpha: isDark ? .82 : .90),
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: palette.divider) : null,
        boxShadow: palette.lift(blur: 28, y: 12, alpha: .16),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
