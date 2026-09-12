import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/motion.dart';

/// A deterministic waveform.
///
/// Bars are derived from [seed] rather than sampled from the file, because the
/// project has no audio decoder — but the shape is stable per track, so the
/// same sound always draws the same wave. The portion before [progress] is
/// painted with the brand sweep, the rest stays faint.
class SoundWave extends StatelessWidget {
  const SoundWave({
    super.key,
    required this.seed,
    required this.progress,
    this.height = 54,
    this.barCount = 48,
    this.barWidth = 3,
    this.spacing = 2,
    this.onSeek,
    this.animateIn = true,
  });

  final int seed;

  /// 0..1 — how much of the wave is "played".
  final double progress;
  final double height;
  final int barCount;
  final double barWidth;
  final double spacing;

  /// When provided the wave becomes a scrubber.
  final ValueChanged<double>? onSeek;
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final content = CustomPaint(
      size: Size.infinite,
      painter: _WavePainter(
        seed: seed,
        progress: progress.clamp(0.0, 1.0),
        barCount: barCount,
        barWidth: barWidth,
        spacing: spacing,
        played: palette.brandGradient,
        rest: palette.textFaint.withValues(alpha: .35),
        capRadius: barWidth / 2,
      ),
    );

    final sized = SizedBox(height: height, width: double.infinity, child: content);

    Widget result = sized;
    if (onSeek != null) {
      result = LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onSeek!(
            (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
          ),
          onHorizontalDragUpdate: (d) => onSeek!(
            (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
          ),
          child: sized,
        ),
      );
    }

    if (!animateIn) return result;
    return StaggeredWaveIn(seed: seed, child: result);
  }
}

/// Grows the wave out of its centre line once, on mount.
class StaggeredWaveIn extends StatefulWidget {
  const StaggeredWaveIn({super.key, required this.child, this.seed = 0});

  final Widget child;
  final int seed;

  @override
  State<StaggeredWaveIn> createState() => _StaggeredWaveInState();
}

class _StaggeredWaveInState extends State<StaggeredWaveIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (motionEnabled(context)) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void didUpdateWidget(StaggeredWaveIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
      builder: (context, child) => ClipRect(
        child: Align(
          alignment: Alignment.center,
          heightFactor: _c.value.clamp(0.02, 1.0),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.seed,
    required this.progress,
    required this.barCount,
    required this.barWidth,
    required this.spacing,
    required this.played,
    required this.rest,
    required this.capRadius,
  });

  final int seed;
  final double progress;
  final int barCount;
  final double barWidth;
  final double spacing;
  final Gradient played;
  final Color rest;
  final double capRadius;

  /// Bar heights, 0..1, stable for a given seed.
  static List<double> _shape(int seed, int count) {
    final rng = math.Random(seed * 6151 + 7);
    return List<double>.generate(count, (i) {
      // A slow envelope keeps the wave from looking like noise, and the random
      // jitter on top keeps it from looking like a sine.
      final envelope =
          .45 + .55 * math.sin(i / count * math.pi * 1.4 + seed * .7);
      final jitter = rng.nextDouble();
      return (0.18 + envelope * .62 * (.55 + jitter * .75)).clamp(.08, 1.0);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final heights = _shape(seed, barCount);
    final slot = (barWidth + spacing);
    final totalWidth = slot * barCount;
    // Centre the wave if it is narrower than the canvas, compress the spacing
    // if it is wider — never let it overflow.
    final scale = totalWidth > size.width ? size.width / totalWidth : 1.0;
    final startX = (size.width - totalWidth * scale) / 2;
    final centerY = size.height / 2;
    final maxBarHeight = size.height;

    final playedPaint = Paint()
      ..shader = played.createShader(Offset.zero & size);
    final restPaint = Paint()..color = rest;

    for (var i = 0; i < barCount; i++) {
      final x = startX + i * slot * scale + (barWidth * scale) / 2;
      final h = (heights[i] * maxBarHeight).clamp(3.0, maxBarHeight);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, centerY),
          width: barWidth * scale,
          height: h,
        ),
        Radius.circular(capRadius),
      );
      final fraction = (i + 1) / barCount;
      canvas.drawRRect(rect, fraction <= progress ? playedPaint : restPaint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress ||
      old.seed != seed ||
      old.barCount != barCount ||
      old.barWidth != barWidth ||
      old.spacing != spacing ||
      old.played != played ||
      old.rest != rest;
}

/// A waveform with two draggable handles — the trim step of Add Sound.
///
/// Reports the selected range as two 0..1 fractions.
class WaveformTrim extends StatefulWidget {
  const WaveformTrim({
    super.key,
    required this.seed,
    required this.start,
    required this.end,
    required this.onChanged,
    this.height = 96,
  });

  final int seed;
  final double start;
  final double end;
  final void Function(double start, double end) onChanged;
  final double height;

  @override
  State<WaveformTrim> createState() => _WaveformTrimState();
}

class _WaveformTrimState extends State<WaveformTrim> {
  /// Which handle a drag in progress has grabbed.
  bool? _draggingStart;

  static const double _minSpan = .08;

  void _update(double fraction, double width) {
    final f = (fraction / width).clamp(0.0, 1.0);
    var start = widget.start;
    var end = widget.end;

    // Pick the nearer handle if the gesture started between them.
    final grabStart = _draggingStart ?? ((f - start).abs() <= (f - end).abs());
    _draggingStart = grabStart;

    if (grabStart) {
      start = f.clamp(0.0, end - _minSpan);
    } else {
      end = f.clamp(start + _minSpan, 1.0);
    }
    widget.onChanged(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            _draggingStart = null;
            _update(d.localPosition.dx, width);
          },
          onHorizontalDragUpdate: (d) => _update(d.localPosition.dx, width),
          onHorizontalDragEnd: (_) => _draggingStart = null,
          onTapDown: (d) {
            _draggingStart = null;
            _update(d.localPosition.dx, width);
          },
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrimPainter(
                seed: widget.seed,
                start: widget.start,
                end: widget.end,
                wave: palette.textFaint.withValues(alpha: .38),
                selection: palette.brandGradient,
                handle: palette.surface,
                handleEdge: palette.orange,
                window: palette.surfaceSunken.withValues(alpha: .0),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrimPainter extends CustomPainter {
  const _TrimPainter({
    required this.seed,
    required this.start,
    required this.end,
    required this.wave,
    required this.selection,
    required this.handle,
    required this.handleEdge,
    required this.window,
  });

  final int seed;
  final double start;
  final double end;
  final Color wave;
  final Gradient selection;
  final Color handle;
  final Color handleEdge;
  final Color window;

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 64;
    const barWidth = 3.0;
    const spacing = 2.0;
    final heights = _WavePainter._shape(seed, barCount);

    final slot = (barWidth + spacing);
    final totalWidth = slot * barCount;
    final scale = totalWidth > size.width ? size.width / totalWidth : 1.0;
    final startX = (size.width - totalWidth * scale) / 2;
    final centerY = size.height / 2;
    final maxH = size.height * .78;

    final selPaint = Paint()
      ..shader = selection.createShader(Offset.zero & size);
    final restPaint = Paint()..color = wave;

    for (var i = 0; i < barCount; i++) {
      final fraction = (i + .5) / barCount;
      final inSelection = fraction >= start && fraction <= end;
      final x = startX + i * slot * scale + (barWidth * scale) / 2;
      final h = (heights[i] * maxH).clamp(3.0, maxH);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, centerY),
          width: barWidth * scale,
          height: h,
        ),
        Radius.circular(barWidth),
      );
      canvas.drawRRect(rect, inSelection ? selPaint : restPaint);
    }

    // Shade the trimmed-away ends so the selection reads instantly.
    final leftW = start * size.width;
    final rightX = end * size.width;
    final shade = Paint()..color = window;
    if (leftW > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, leftW, size.height), shade);
    }
    if (rightX < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(rightX, 0, size.width - rightX, size.height),
        shade,
      );
    }

    _handle(canvas, size, start * size.width);
    _handle(canvas, size, end * size.width);
  }

  void _handle(Canvas canvas, Size size, double x) {
    const w = 5.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x.clamp(2, size.width - 2), size.height / 2),
        width: w,
        height: size.height,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, Paint()..color = handleEdge);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x.clamp(2, size.width - 2), size.height / 2),
          width: w * .4,
          height: size.height * .5,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = handle,
    );
  }

  @override
  bool shouldRepaint(_TrimPainter old) =>
      old.start != start || old.end != end || old.seed != seed;
}
