import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_info.dart';
import '../theme/app_colors.dart';
import '../utils/motion.dart';
import '../utils/responsive.dart';
import '../widgets/animated_background.dart';
import '../widgets/equalizer_bars.dart';
import '../widgets/soft_card.dart';

/// The first thing the app shows.
///
/// One controller drives the staged entrance (rings, logo, wordmark, tagline,
/// loader) and a second, slower one drives the ambient halo that keeps the
/// screen alive after everything has landed.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  /// Called once the loader completes. The boot flow owns what happens next.
  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _total = Duration(milliseconds: 2700);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _total,
  );
  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  // Built once and kept as fields. Handing `AnimatedBuilder` a freshly created
  // `CurvedAnimation` on every build would make it tear down and re-attach its
  // listener each frame.
  late final Animation<double> _ringIn = _stage(0, .55);
  late final Animation<double> _logoIn = _stage(
    0,
    .5,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _logoFade = _stage(0, .3);
  late final Animation<double> _tagline = _stage(.52, .78);
  late final Animation<double> _loaderFade = _stage(.62, .9);
  late final Animation<double> _loaderValue = _stage(.6, 1);
  late final Animation<double> _hintFade = _stage(.8, 1);

  bool _started = false;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (!motionEnabled(context)) {
      // Reduce-motion users still get the splash, just without the theatre.
      _intro.value = 1;
      _halo.value = .5;
      _scheduleDone(const Duration(milliseconds: 900));
      return;
    }
    _intro.forward();
    _halo.repeat(reverse: true);
    _scheduleDone(_total + const Duration(milliseconds: 220));
  }

  void _scheduleDone(Duration after) {
    Future<void>.delayed(after, () {
      if (!mounted || _finished) return;
      _finished = true;
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _halo.dispose();
    super.dispose();
  }

  /// A staged slice of the intro controller, e.g. "between 30% and 65%".
  Animation<double> _stage(double begin, double end, {Curve? curve}) {
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(begin, end, curve: curve ?? Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final compact = Responsive.isCompact(context);
    final logoSize = compact ? 100.0 : 122.0;
    // The halo canvas is bigger than the logo so the expanding rings have room
    // to travel before they fade out.
    final haloSize = logoSize * 2.1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        intensity: 1.5,
        showGrid: true,
        child: SafeArea(
          child: ScrollablePage(
            center: true,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: compact ? 12 : 28),

              // ---------------------------------------------------- logo
              SizedBox(
                width: haloSize,
                height: haloSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _halo,
                      builder: (context, _) => CustomPaint(
                        size: Size.square(haloSize),
                        painter: _HaloPainter(
                          t: _halo.value,
                          color: palette.orange,
                          second: palette.blue,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _ringIn,
                      builder: (context, _) => CustomPaint(
                        size: Size.square(logoSize * 1.55),
                        painter: _AccentRingPainter(
                          progress: _ringIn.value,
                          gradient: palette.brandGradient,
                        ),
                      ),
                    ),
                    ScaleTransition(
                      scale: _logoIn,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: _LogoTile(size: logoSize, sweep: _intro),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: compact ? 10 : 18),

              // ------------------------------------------------- wordmark
              _Wordmark(animation: _intro),

              const SizedBox(height: 10),

              FadeTransition(
                opacity: _tagline,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    AppInfo.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                      letterSpacing: .3,
                    ),
                  ),
                ),
              ),

              SizedBox(height: compact ? 26 : 42),

              // --------------------------------------------------- loader
              FadeTransition(
                opacity: _loaderFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: compact ? 168 : 208,
                      child: AnimatedBuilder(
                        animation: _loaderValue,
                        builder: (context, _) =>
                            SlimProgressBar(value: _loaderValue.value, height: 4),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: _hintFade,
                      child: Text(
                        'PREPARING YOUR LIBRARY',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.textFaint,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: compact ? 12 : 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rounded app icon: brand sweep, a live equaliser inside, and a single
/// specular band that crosses it once.
class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.size, required this.sweep});

  final double size;
  final Animation<double> sweep;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: palette.brandGradient,
        borderRadius: BorderRadius.circular(size * .29),
        boxShadow: [
          BoxShadow(
            color: palette.orange.withValues(alpha: .38),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: palette.blue.withValues(alpha: .24),
            blurRadius: 60,
            offset: const Offset(0, 26),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .29),
        child: Stack(
          alignment: Alignment.center,
          children: [
            EqualizerBars(
              barCount: 5,
              height: size * .42,
              barWidth: size * .062,
              gap: size * .05,
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xCCFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            // Specular band, painted as a gradient whose alignment slides —
            // no layout maths, so it can never affect the tile's size.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: sweep,
                  builder: (context, _) {
                    final t = sweep.value;
                    // Fades in quickly, then out as the intro settles.
                    final fade = t < .55
                        ? (t / .25).clamp(0.0, 1.0)
                        : (1 - (t - .55) / .45).clamp(0.0, 1.0);
                    final pos = -1.6 + t * 3.4;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(pos - .4, -1),
                          end: Alignment(pos + .4, 1),
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: .34 * fade),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The wordmark, revealed one letter at a time.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const letters = AppInfo.wordmark;
    final style = theme.textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 7,
      fontSize: Responsive.isCompact(context) ? 28 : 36,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(letters.length, (i) {
        final start = (.30 + i * .045).clamp(0.0, .85);
        final curved = CurvedAnimation(
          parent: animation,
          curve: Interval(start, (start + .35).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic),
        );
        return AnimatedBuilder(
          animation: curved,
          builder: (context, child) => Opacity(
            opacity: curved.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - curved.value) * 22),
              child: Transform.scale(
                scale: .8 + .2 * curved.value,
                child: child,
              ),
            ),
          ),
          child: GradientText(letters[i], style: style),
        );
      }),
    );
  }
}

/// Rings that expand outward and fade, on a loop.
class _HaloPainter extends CustomPainter {
  const _HaloPainter({
    required this.t,
    required this.color,
    required this.second,
  });

  final double t;
  final Color color;
  final Color second;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    const rings = 3;

    for (var i = 0; i < rings; i++) {
      // Each ring runs the same cycle, offset by a third.
      final phase = (t + i / rings) % 1.0;
      final radius = maxRadius * (.42 + phase * .58);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Color.lerp(color, second, phase)!
              .withValues(alpha: (1 - phase) * .30),
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.t != t;
}

/// A single gradient arc that draws itself around the logo.
class _AccentRingPainter extends CustomPainter {
  const _AccentRingPainter({required this.progress, required this.gradient});

  final double progress;
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * .82 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AccentRingPainter old) =>
      old.progress != progress || old.gradient != gradient;
}
