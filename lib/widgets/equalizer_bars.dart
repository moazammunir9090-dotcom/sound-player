import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/motion.dart';

/// A cluster of bars that bounce while [playing].
///
/// Each bar runs at its own speed and phase, which is what stops the group
/// from reading as a single synchronised pulse — the trick that makes a fake
/// visualiser look like it is reacting to audio.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    this.barCount = 5,
    this.height = 30,
    this.barWidth = 4,
    this.gap = 3.5,
    this.playing = true,
    this.color,
    this.gradient,
    this.minFactor = .22,
  });

  final int barCount;
  final double height;
  final double barWidth;
  final double gap;
  final bool playing;
  final Color? color;
  final Gradient? gradient;

  /// Shortest a bar may become, as a fraction of [height].
  final double minFactor;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final shouldRun = widget.playing && motionEnabled(context);
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
    // An explicit colour wins over the brand sweep, so callers that just want
    // a flat tint do not have to also pass `gradient: null`.
    final paint = widget.gradient ??
        (widget.color == null ? palette.brandGradient : null);

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List<Widget>.generate(widget.barCount, (i) {
              final speed = 1 + (i % 3) * .45;
              final phase = i * 1.7;
              final wave = _c.value * 2 * math.pi * speed + phase;
              // Two summed sines give an irregular, non-repeating feel.
              final mixed =
                  (math.sin(wave) * .6 + math.sin(wave * 1.9 + 1.1) * .4);
              final factor = widget.playing
                  ? widget.minFactor +
                        (1 - widget.minFactor) * ((mixed + 1) / 2)
                  : widget.minFactor;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: widget.barWidth,
                  height: (widget.height * factor).clamp(3.0, widget.height),
                  decoration: BoxDecoration(
                    gradient: paint,
                    color: widget.color,
                    borderRadius: BorderRadius.circular(widget.barWidth),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// The three-bar "this track is playing" indicator used in list rows.
class NowPlayingBars extends StatelessWidget {
  const NowPlayingBars({
    super.key,
    required this.playing,
    this.size = 16,
    this.color,
  });

  final bool playing;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: EqualizerBars(
        barCount: 3,
        height: size,
        barWidth: size * .17,
        gap: size * .12,
        playing: playing,
        gradient: null,
        color: color ?? palette.orange,
        minFactor: .3,
      ),
    );
  }
}

/// A dot that breathes. Used to mark a live/now-playing state without
/// stealing attention.
class PulsingDot extends StatefulWidget {
  const PulsingDot({
    super.key,
    this.size = 8,
    this.color,
    this.spread = 3,
  });

  final double size;
  final Color? color;

  /// How far the halo expands, as a multiple of [size].
  final double spread;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldRun = motionEnabled(context);
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
    final color = widget.color ?? context.palette.orange;
    final box = widget.size * widget.spread;

    return SizedBox.square(
      dimension: box,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: .6 + t * .9,
                child: Container(
                  width: box,
                  height: box,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: .35 * (1 - t)),
                  ),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Wraps a control with a slow, barely-there breathing scale.
///
/// Applied to the play button so the primary action on the player screen is
/// never fully static, even when paused.
class Breathing extends StatefulWidget {
  const Breathing({
    super.key,
    required this.child,
    this.amplitude = .035,
    this.period = const Duration(milliseconds: 2600),
    this.active = true,
  });

  final Widget child;
  final double amplitude;
  final Duration period;
  final bool active;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldRun = widget.active && motionEnabled(context);
    if (shouldRun && !_running) {
      _running = true;
      _c.repeat(reverse: true);
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
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 1 + Curves.easeInOut.transform(_c.value) * widget.amplitude,
        child: child,
      ),
      child: widget.child,
    );
  }
}
