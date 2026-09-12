import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_info.dart';
import '../theme/app_colors.dart';
import '../utils/motion.dart';
import '../utils/responsive.dart';
import '../widgets/album_art.dart';
import '../widgets/animated_background.dart';
import '../widgets/equalizer_bars.dart';
import '../widgets/press_scale.dart';
import '../widgets/progress_ring.dart';
import '../widgets/soft_card.dart';

/// The "next, next, next" introduction.
///
/// Three pages, each with a hand-composed illustration that reacts to how far
/// the user has swiped. Every page animates from a single value — the page
/// controller's fractional position — so a half-finished swipe leaves the
/// illustration half-way through its move rather than snapping.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Called when the user finishes the last page or taps Skip.
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pages = PageController();

  /// A slow loop that keeps the illustrations breathing while the user reads.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  int _index = 0;
  bool _started = false;

  static const List<_PageSpec> _specs = <_PageSpec>[
    _PageSpec(
      eyebrow: 'Your library',
      title: 'Every sound,\nin one place',
      body:
          'Import files, record a moment or paste a link. Sonora keeps the '
          'whole collection searchable and beautifully sorted.',
      icon: Icons.library_music_rounded,
    ),
    _PageSpec(
      eyebrow: 'Playback',
      title: 'Scrub, skip\nand repeat',
      body:
          'Drag the ring to find the exact moment. Shuffle the queue, loop a '
          'favourite, and watch the waveform follow along.',
      icon: Icons.graphic_eq_rounded,
    ),
    _PageSpec(
      eyebrow: 'Make it yours',
      title: 'Light, dark\nor in between',
      body:
          'Follow the system, or pick a side. Choose an accent, calm the '
          'motion, and Sonora settles in around you.',
      icon: Icons.tune_rounded,
    ),
  ];

  bool get _isLast => _index == _specs.length - 1;

  @override
  void initState() {
    super.initState();
    _pages.addListener(_onScroll);
  }

  void _onScroll() {
    final page = _pages.page?.round() ?? 0;
    if (page != _index && mounted) setState(() => _index = page);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (motionEnabled(context)) _ambient.repeat();
  }

  @override
  void dispose() {
    _pages.removeListener(_onScroll);
    _pages.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    _pages.nextPage(
      duration: motionEnabled(context)
          ? const Duration(milliseconds: 520)
          : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isExpanded(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        intensity: 1.15,
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                showSkip: !_isLast,
                onSkip: widget.onDone,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _specs.length,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, i) => AnimatedBuilder(
                    animation: _pages,
                    builder: (context, _) {
                      // -1 .. 1: how far this page is from being centred.
                      final raw = _pages.hasClients && _pages.position.haveDimensions
                          ? (_pages.page ?? 0) - i
                          : (i == 0 ? 0.0 : 1.0);
                      final delta = raw.clamp(-1.0, 1.0);
                      return _PageBody(
                        spec: _specs[i],
                        index: i,
                        delta: delta,
                        ambient: _ambient,
                        wide: wide,
                      );
                    },
                  ),
                ),
              ),
              _BottomBar(
                count: _specs.length,
                controller: _pages,
                index: _index,
                isLast: _isLast,
                onNext: _next,
              ),
              SizedBox(height: Responsive.adaptiveGap(context, fraction: .02)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageSpec {
  const _PageSpec({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
}

// ---------------------------------------------------------------- page body

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.spec,
    required this.index,
    required this.delta,
    required this.ambient,
    required this.wide,
  });

  final _PageSpec spec;
  final int index;
  final double delta;
  final Animation<double> ambient;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    // Content drifts and dims as its page leaves the centre.
    final visibility = (1 - delta.abs()).clamp(0.0, 1.0);

    final art = Opacity(
      opacity: visibility,
      child: Transform.translate(
        offset: Offset(delta * -54, 0),
        child: Transform.scale(
          scale: .86 + .14 * visibility,
          child: _Illustration(index: index, ambient: ambient),
        ),
      ),
    );

    final text = Opacity(
      // The copy trails the illustration slightly, which is what gives the
      // swipe its sense of depth.
      opacity: (1 - delta.abs() * 1.15).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(delta * -110, 0),
        child: _Copy(spec: spec),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide windows get the illustration beside the copy instead of above
        // it, so a landscape desktop never ends up with a tall thin column.
        final useRow = wide && constraints.maxWidth > 860;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.gutter(context),
            vertical: 8,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: useRow
                ? Row(
                    children: [
                      Expanded(child: Center(child: art)),
                      const SizedBox(width: 32),
                      Expanded(child: Center(child: text)),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // No Flexible here: inside a scroll view the column's
                      // height is unbounded, so a flex child would assert. The
                      // ConstrainedBox above supplies the centring instead.
                      Center(child: art),
                      SizedBox(
                        height: Responsive.adaptiveGap(
                          context,
                          fraction: .04,
                          min: 14,
                          max: 40,
                        ),
                      ),
                      text,
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({required this.spec});

  final _PageSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(
                icon: spec.icon,
                size: 32,
                iconSize: 16,
                radius: 10,
                color: palette.orange,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  spec.eyebrow.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.6,
                    color: palette.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            spec.title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: Responsive.isCompact(context) ? 30 : 38,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            spec.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: palette.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ illustrations

class _Illustration extends StatelessWidget {
  const _Illustration({required this.index, required this.ambient});

  final int index;
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, _) => switch (index) {
        0 => _DiscoverArt(t: ambient.value),
        1 => _PlaybackArt(t: ambient.value),
        _ => _PersonaliseArt(t: ambient.value),
      },
    );
  }
}

/// Page 1 — three covers fanning out of a stack, with category chips orbiting.
class _DiscoverArt extends StatelessWidget {
  const _DiscoverArt({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final float = math.sin(t * 2 * math.pi);
    final size = Responsive.isCompact(context) ? 118.0 : 142.0;

    return SizedBox(
      height: size * 2.05,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wide soft glow behind the stack.
          Container(
            width: size * 2.1,
            height: size * 1.5,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  palette.orange.withValues(alpha: .18 + .06 * float.abs()),
                  palette.orange.withValues(alpha: 0),
                ],
              ),
            ),
          ),

          // Back-left cover.
          Transform.translate(
            offset: Offset(-size * .62 + float * 3, 12),
            child: Transform.rotate(
              angle: -.17 + float * .012,
              child: _Shadowed(
                child: AlbumArt(seed: 4, size: size * .82, radius: 20),
              ),
            ),
          ),

          // Back-right cover.
          Transform.translate(
            offset: Offset(size * .62 - float * 3, 12),
            child: Transform.rotate(
              angle: .17 - float * .012,
              child: _Shadowed(
                child: AlbumArt(seed: 8, size: size * .82, radius: 20),
              ),
            ),
          ),

          // Front cover, floating.
          Transform.translate(
            offset: Offset(0, -float * 7),
            child: _Shadowed(
              strong: true,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AlbumArt(seed: 1, size: size, radius: 26),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .35),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Now playing',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating category chips.
          Positioned(
            top: 10 + float * 5,
            right: 0,
            child: _FloatingChip(
              label: 'Focus',
              icon: Icons.center_focus_strong_rounded,
            ),
          ),
          Positioned(
            bottom: 16 - float * 5,
            left: 0,
            child: _FloatingChip(
              label: 'Ambient',
              icon: Icons.waves_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 2 — a progress ring wrapping a spinning cover, over a live waveform.
class _PlaybackArt extends StatelessWidget {
  const _PlaybackArt({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final diameter = Responsive.isCompact(context) ? 208.0 : 248.0;
    // The ring sweeps back and forth so the illustration always has motion.
    final sweep = .18 + (.5 + .5 * math.sin(t * 2 * math.pi)) * .72;

    return SizedBox(
      height: diameter * 1.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressRing(
            size: diameter,
            progress: sweep,
            strokeWidth: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: t * 2 * math.pi,
                  child: AlbumArt(
                    seed: 2,
                    size: diameter * .5,
                    circle: true,
                    showWave: false,
                  ),
                ),
                SizedBox(height: diameter * .045),
                Container(
                  width: diameter * .17,
                  height: diameter * .17,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: palette.brandGradient,
                    boxShadow: palette.lift(blur: 18, y: 6, alpha: .3),
                  ),
                  child: const Icon(
                    Icons.pause_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: diameter * .06),
          EqualizerBars(
            barCount: 11,
            height: 34,
            barWidth: 4,
            gap: 4,
            minFactor: .18,
          ),
        ],
      ),
    );
  }
}

/// Page 3 — a light and a dark preview, with the theme switch sliding between.
class _PersonaliseArt extends StatelessWidget {
  const _PersonaliseArt({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final compact = Responsive.isCompact(context);
    final w = compact ? 116.0 : 138.0;
    final h = w * 1.62;
    // Eases between the two previews so the illustration always reads as
    // "choosing", never as "stuck".
    final blend = .5 + .5 * math.sin(t * 2 * math.pi - math.pi / 2);

    return SizedBox(
      height: h + 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Light preview, tilted away.
          Transform.translate(
            offset: Offset(-w * .46 - blend * 6, blend * 8),
            child: Transform.rotate(
              angle: -.09,
              child: _Shadowed(
                child: _MiniPreview(
                  width: w,
                  height: h,
                  dark: false,
                  accent: palette.orange,
                ),
              ),
            ),
          ),

          // Dark preview, tilted the other way.
          Transform.translate(
            offset: Offset(w * .46 + blend * 6, blend * 8),
            child: Transform.rotate(
              angle: .09,
              child: _Shadowed(
                child: _MiniPreview(
                  width: w,
                  height: h,
                  dark: true,
                  accent: palette.blue,
                ),
              ),
            ),
          ),

          // The switch itself, sitting on the seam.
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.divider),
                boxShadow: palette.lift(blur: 20, y: 8, alpha: .18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SwitchHalf(
                    icon: Icons.light_mode_rounded,
                    selected: blend < .5,
                    color: palette.orange,
                  ),
                  _SwitchHalf(
                    icon: Icons.dark_mode_rounded,
                    selected: blend >= .5,
                    color: palette.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchHalf extends StatelessWidget {
  const _SwitchHalf({
    required this.icon,
    required this.selected,
    required this.color,
  });

  final IconData icon;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: 42,
      height: 36,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : context.palette.textFaint,
      ),
    );
  }
}

/// A miniature phone-shaped UI used as the theme preview.
class _MiniPreview extends StatelessWidget {
  const _MiniPreview({
    required this.width,
    required this.height,
    required this.dark,
    required this.accent,
  });

  final double width;
  final double height;
  final bool dark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF0B0F19) : const Color(0xFFF7F8FC);
    final surface = dark ? const Color(0xFF161C2B) : Colors.white;
    final line = dark ? const Color(0xFF232B40) : const Color(0xFFE6EAF4);
    final strong = dark ? const Color(0xFFE8EEFB) : const Color(0xFF111827);

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? line : const Color(0xFFE2E6F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar.
          Row(
            children: [
              Container(width: 22, height: 4, decoration: _bar(strong, .8)),
              const Spacer(),
              Container(width: 10, height: 4, decoration: _bar(strong, .3)),
            ],
          ),
          const SizedBox(height: 12),
          // A small heading.
          Container(width: width * .55, height: 7, decoration: _bar(strong, .9)),
          const SizedBox(height: 6),
          Container(width: width * .34, height: 5, decoration: _bar(strong, .35)),
          const SizedBox(height: 14),
          // Cover. Flexible, not fixed: the mockup has to hold together at
          // every illustration size, and an `AspectRatio` inside a bound
          // shrinks to a square rather than overflowing the card.
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: .55)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Playback row.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 12, height: 12, decoration: _bar(strong, .3)),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 12, height: 12, decoration: _bar(strong, .3)),
            ],
          ),
          const SizedBox(height: 12),
          // A list stub.
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: line),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 4, decoration: _bar(strong, .55)),
                    const SizedBox(height: 4),
                    Container(
                      width: width * .3,
                      height: 4,
                      decoration: _bar(strong, .25),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _bar(Color color, double opacity) => BoxDecoration(
    color: color.withValues(alpha: opacity * (dark ? .75 : .55)),
    borderRadius: BorderRadius.circular(999),
  );
}

/// Wraps artwork in the app's ambient shadow.
class _Shadowed extends StatelessWidget {
  const _Shadowed({required this.child, this.strong = false});

  final Widget child;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: palette.lift(
          blur: strong ? 34 : 20,
          y: strong ? 16 : 9,
          alpha: context.isDark ? .4 : (strong ? .18 : .12),
        ),
      ),
      child: child,
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.divider),
        boxShadow: palette.lift(blur: 16, y: 6, alpha: .14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.orange),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: palette.textPrimary,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- chrome

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showSkip, required this.onSkip});

  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.gutter(context),
        10,
        Responsive.gutter(context) - 8,
        4,
      ),
      child: Row(
        children: [
          // A compact brand mark, so the introduction still feels like the app
          // that just launched.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: palette.orangeWash,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: palette.orange.withValues(alpha: .25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 14,
                  color: palette.orangeInk,
                ),
                const SizedBox(width: 6),
                Text(
                  AppInfo.wordmark,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.orangeInk,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Skip collapses rather than disappearing, so the bar never jumps.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 260),
            opacity: showSkip ? 1 : 0,
            child: IgnorePointer(
              ignoring: !showSkip,
              child: PressScale(
                onTap: onSkip,
                scale: .94,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'Skip',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.count,
    required this.controller,
    required this.index,
    required this.isLast,
    required this.onNext,
  });

  final int count;
  final PageController controller;
  final int index;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isCompact(context);
    final gutter = Responsive.gutter(context);

    final dots = _PageDots(
      count: count,
      controller: controller,
      index: index,
    );

    final button = BrandButton(
      label: isLast ? 'Get started' : 'Next',
      onTap: onNext,
      trailingArrow: !isLast,
      icon: isLast ? Icons.check_rounded : null,
      expand: compact,
      height: 54,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 6),
      child: compact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                dots,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: button),
              ],
            )
          : Row(
              children: [
                dots,
                const Spacer(),
                // Constrained so the CTA does not stretch across a 4K window.
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 190),
                  child: button,
                ),
              ],
            ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.controller,
    required this.index,
  });

  final int count;
  final PageController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients && controller.position.haveDimensions
            ? (controller.page ?? index.toDouble())
            : index.toDouble();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(count, (i) {
            // Distance from the current page drives both width and colour, so
            // the pill grows smoothly through a swipe instead of snapping.
            final distance = (page - i).abs().clamp(0.0, 1.0);
            final active = 1 - distance;
            final width = 10 + 20 * Curves.easeOut.transform(active);

            return Padding(
              padding: const EdgeInsets.only(right: 7),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: width,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: active > .5 ? palette.brandGradient : null,
                  color: active > .5
                      ? null
                      : palette.textFaint.withValues(alpha: .35),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
