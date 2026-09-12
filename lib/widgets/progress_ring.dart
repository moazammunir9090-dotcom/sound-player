import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The circular progress ring that surrounds the artwork on the player screen.
///
/// Two things make it worth writing by hand rather than using a
/// `CircularProgressIndicator`:
///
///  * it paints a *gradient* arc with a soft glow and a head dot, and
///  * it is directly draggable — grabbing anywhere on the ring scrubs the
///    track, which is the interaction the reference layout implies.
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.size,
    required this.child,
    this.strokeWidth = 6,
    this.onSeek,
    this.onSeekEnd,
    this.enabled = true,
    this.startAngle,
    this.gapFraction = .05,
  });

  /// 0..1 playback position.
  final double progress;

  /// Outer diameter, including the stroke.
  final double size;

  /// Content drawn inside the ring (the artwork).
  final Widget child;

  final double strokeWidth;

  /// Called with a 0..1 fraction while the user drags the ring.
  final ValueChanged<double>? onSeek;

  /// Called once the gesture finishes, with the final fraction. Lets the owner
  /// show the drag live and only commit the seek at the end, so an in-flight
  /// drag never fights the playback timer.
  final ValueChanged<double>? onSeekEnd;

  final bool enabled;

  /// Defaults to straight up.
  final double? startAngle;

  /// Fraction of the circle left open, so the ring reads as a gauge rather
  /// than a closed loop.
  final double gapFraction;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing> {
  bool _dragging = false;
  double? _dragProgress;

  double get _start => widget.startAngle ?? -math.pi / 2;

  double get _sweep => 2 * math.pi * (1 - widget.gapFraction);

  double get _shown => _dragProgress ?? widget.progress.clamp(0.0, 1.0);

  /// Maps a local pointer position onto a 0..1 position along the arc.
  void _handlePointer(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final v = local - center;
    var angle = math.atan2(v.dy, v.dx);
    // Normalise into [start, start + 2pi).
    var delta = angle - _start;
    while (delta < 0) {
      delta += 2 * math.pi;
    }
    final fraction = (delta / _sweep).clamp(0.0, 1.0);
    setState(() => _dragProgress = fraction);
    widget.onSeek?.call(fraction);
  }

  /// Ends a drag and reports the final fraction, if there was one.
  void _endGesture() {
    final value = _dragProgress;
    setState(() {
      _dragging = false;
      _dragProgress = null;
    });
    if (value != null) widget.onSeekEnd?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final diameter = widget.size;
    final inner = diameter - widget.strokeWidth * 2 - 14;

    final ring = SizedBox.square(
      dimension: diameter,
      child: CustomPaint(
        painter: _RingPainter(
          progress: _shown,
          strokeWidth: _dragging ? widget.strokeWidth * 1.5 : widget.strokeWidth,
          start: _start,
          sweep: _sweep,
          track: palette.surfaceSunken,
          glow: palette.orange.withValues(alpha: .45),
          gradient: SweepGradient(
            startAngle: _start,
            endAngle: _start + _sweep,
            colors: [palette.orange, palette.blue, palette.orange],
          ),
        ),
        child: Center(
          child: SizedBox.square(
            dimension: inner.clamp(0, diameter),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onSeek == null || !widget.enabled) return ring;

    return LayoutBuilder(
      builder: (context, _) {
        final size = Size.square(diameter);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _handlePointer(d.localPosition, size),
          onPanUpdate: (d) => _handlePointer(d.localPosition, size),
          onPanEnd: (_) => _endGesture(),
          onPanCancel: _endGesture,
          onTapDown: (d) {
            setState(() => _dragging = true);
            _handlePointer(d.localPosition, size);
          },
          onTapUp: (_) => _endGesture(),
          child: ring,
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.start,
    required this.sweep,
    required this.track,
    required this.glow,
    required this.gradient,
  });

  final double progress;
  final double strokeWidth;
  final double start;
  final double sweep;
  final Color track;
  final Color glow;
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressSweep = sweep * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = track,
    );

    if (progress <= 0) return;

    final shader = gradient.createShader(rect);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    // Glow underneath, then the crisp arc on top.
    canvas.drawArc(
      rect,
      start,
      progressSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.9
        ..strokeCap = StrokeCap.round
        ..color = glow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawArc(rect, start, progressSweep, false, arcPaint);

    // Head dot — makes the draggable affordance obvious.
    final headAngle = start + progressSweep;
    final head = center + Offset(math.cos(headAngle), math.sin(headAngle)) * radius;
    canvas.drawCircle(
      head,
      strokeWidth * 1.15,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      head,
      strokeWidth * .62,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.start != start ||
      old.sweep != sweep ||
      old.track != track ||
      old.glow != glow;
}
