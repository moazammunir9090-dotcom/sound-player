import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/motion.dart';

/// Fades and lifts a child into place shortly after it is built.
///
/// Give a list of these an increasing [index] and it produces the staggered
/// cascade the home list and settings sections use. Motion is disabled it
/// renders at rest immediately rather than animating.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.stepDelay = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 460),
    this.offset = 22,
    this.scaleFrom = 1,
    this.axis = Axis.vertical,
  });

  final Widget child;
  final int index;

  /// Delay added per [index]. Index 0 starts immediately.
  final Duration stepDelay;
  final Duration duration;

  /// How far the child travels in, in logical pixels.
  final double offset;

  /// Optional starting scale, e.g. `.96` for a soft pop.
  final double scaleFrom;
  final Axis axis;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (!motionEnabled(context)) {
      _c.value = 1;
      return;
    }
    final delay = widget.stepDelay * widget.index;
    if (delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _c,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        final slide = (1 - t) * widget.offset;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: widget.axis == Axis.vertical
                ? Offset(0, slide)
                : Offset(slide, 0),
            child: widget.scaleFrom == 1
                ? child
                : Transform.scale(
                    scale: widget.scaleFrom + (1 - widget.scaleFrom) * t,
                    child: child,
                  ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A one-shot fade + slide for a single widget — same feel as
/// [StaggeredEntrance] without the index bookkeeping.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = 16,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return StaggeredEntrance(
      index: 1,
      stepDelay: delay,
      duration: duration,
      offset: offset,
      child: child,
    );
  }
}

/// Plays an entrance animation on every rebuild triggered by [listenTo], which
/// is how the player screen re-animates when the track changes.
class ReplayOnChange extends StatefulWidget {
  const ReplayOnChange({
    super.key,
    required this.value,
    required this.child,
    this.duration = const Duration(milliseconds: 520),
    this.offset = 18,
  });

  /// When this value changes, the animation replays from the start.
  final Object? value;
  final Widget child;
  final Duration duration;
  final double offset;

  @override
  State<ReplayOnChange> createState() => _ReplayOnChangeState();
}

class _ReplayOnChangeState extends State<ReplayOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void didUpdateWidget(ReplayOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!motionEnabled(context)) return widget.child;
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Draws attention to a value that just changed by flashing an accent wash
/// behind it, then settling back.
class FlashOnChange extends StatefulWidget {
  const FlashOnChange({
    super.key,
    required this.value,
    required this.child,
    this.color,
    this.borderRadius,
  });

  final Object? value;
  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;

  @override
  State<FlashOnChange> createState() => _FlashOnChangeState();
}

class _FlashOnChangeState extends State<FlashOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1, // at rest: no tint until a change actually happens
  );

  @override
  void didUpdateWidget(FlashOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(10),
            color: color.withValues(alpha: .16 * (1 - t)),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
