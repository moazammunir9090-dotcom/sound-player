import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sound_item.dart';
import '../routes/app_page_route.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/motion.dart';
import '../utils/responsive.dart';
import '../widgets/album_art.dart';
import '../widgets/animated_background.dart';
import '../widgets/equalizer_bars.dart';
import '../widgets/press_scale.dart';
import '../widgets/progress_ring.dart';
import '../widgets/soft_card.dart';
import '../widgets/sound_tile.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/waveform.dart';
import 'add_sound_screen.dart';
import 'settings_screen.dart';

/// The full-screen player.
///
/// Layout follows the reference: a progress ring around rotating artwork with
/// the play button riding its lower edge, a control row underneath, and a
/// three-way pill selector for the panel below. On a wide window the whole
/// thing splits into two columns instead of stacking.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  /// One slow revolution. Stopped rather than paused when playback pauses, so
  /// the artwork holds its angle instead of snapping back.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  bool _spinning = false;
  int _tab = 0;

  /// Set while the user drags the ring, so the ring shows the drag rather than
  /// fighting the timer for control of the thumb.
  double? _scrub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpin();
  }

  void _syncSpin() {
    final state = AppScope.of(context);
    final shouldSpin = state.isPlaying && motionEnabled(context);
    if (shouldSpin && !_spinning) {
      _spinning = true;
      _spin.repeat();
    } else if (!shouldSpin && _spinning) {
      _spinning = false;
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final track = state.current;

    // The player is only reachable with a track loaded, but the mini player
    // can clear the queue while this route is on screen.
    if (track == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBackground(
          intensity: .9,
          child: SafeArea(
            child: Column(
              children: [
                _PlayerTopBar(
                  eyebrow: 'Nothing playing',
                  onClose: () => Navigator.of(context).maybePop(),
                ),
                const Expanded(
                  child: Center(
                    child: EmptyState(
                      icon: Icons.music_off_rounded,
                      title: 'Nothing playing',
                      message: 'Pick something from your library to start.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final colors = albumColors(track.seed);
    final wide = Responsive.useWidePlayer(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AnimatedBackground(intensity: .55),
          // A tint pulled from the artwork, so the screen belongs to the track
          // that is playing rather than to the app chrome.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.75),
                    radius: 1.1,
                    colors: [
                      colors.first.withValues(alpha: .22),
                      colors.first.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _PlayerTopBar(
                  eyebrow: track.collection,
                  onClose: () => Navigator.of(context).maybePop(),
                  onMenu: () => _openMenu(context, track),
                ),
                Expanded(
                  child: wide
                      ? _WideLayout(
                          track: track,
                          spin: _spin,
                          scrub: _scrub,
                          onScrub: (v) => setState(() => _scrub = v),
                          onScrubEnd: (value) {
                            state.seekFraction(value);
                            setState(() => _scrub = null);
                          },
                          tab: _tab,
                          onTab: (i) => setState(() => _tab = i),
                        )
                      : _CompactLayout(
                          track: track,
                          spin: _spin,
                          scrub: _scrub,
                          onScrub: (v) => setState(() => _scrub = v),
                          onScrubEnd: (value) {
                            state.seekFraction(value);
                            setState(() => _scrub = null);
                          },
                          tab: _tab,
                          onTab: (i) => setState(() => _tab = i),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openMenu(BuildContext context, SoundItem track) {
    final state = AppScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  AlbumArt(seed: track.seed, size: 46, radius: 13),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _SheetAction(
              icon: track.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: track.isFavorite
                  ? 'Remove from favourites'
                  : 'Add to favourites',
              onTap: () {
                state.toggleFavorite(track.id);
                Navigator.of(sheetContext).pop();
              },
            ),
            _SheetAction(
              icon: Icons.playlist_add_rounded,
              label: 'Queue this next',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _toast(context, 'Queued after ${track.title}');
              },
            ),
            _SheetAction(
              icon: Icons.library_add_rounded,
              label: 'Add another sound',
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  AppPageRoute<void>(
                    builder: (_) => const AddSoundScreen(),
                    transition: AppTransition.slideUp,
                  ),
                );
              },
            ),
            _SheetAction(
              icon: Icons.tune_rounded,
              label: 'Player settings',
              onTap: () {
                Navigator.of(sheetContext).pop();
                openSettings(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

// --------------------------------------------------------------- top bar

class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({required this.eyebrow, this.onClose, this.onMenu});

  final String eyebrow;
  final VoidCallback? onClose;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.gutter(context) - 6,
        6,
        Responsive.gutter(context) - 6,
        4,
      ),
      child: Row(
        children: [
          SoftIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: onClose,
            size: 42,
            iconSize: 26,
            tooltip: 'Close player',
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NOW PLAYING',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.orange,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SoftIconButton(
            icon: Icons.more_horiz_rounded,
            onTap: onMenu,
            size: 42,
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ compact layout

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.track,
    required this.spin,
    required this.scrub,
    required this.onScrub,
    required this.onScrubEnd,
    required this.tab,
    required this.onTab,
  });

  final SoundItem track;
  final Animation<double> spin;
  final double? scrub;
  final ValueChanged<double> onScrub;
  final ValueChanged<double> onScrubEnd;
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = Responsive.gutter(context);
        // The ring gets whatever is left after the fixed chrome, but never
        // more than the window is tall — that is what keeps a short landscape
        // window from overflowing.
        final available = math.min(
          constraints.maxWidth - gutter * 2,
          constraints.maxHeight * .60,
        );
        final ring = available.clamp(180.0, 320.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TrackHeading(track: track),
              SizedBox(height: ring * .06),
              _ArtworkWithRing(
                track: track,
                spin: spin,
                size: ring,
                scrub: scrub,
                onScrub: onScrub,
                onScrubEnd: onScrubEnd,
              ),
              SizedBox(height: ring * .07),
              const _SeekRow(),
              const SizedBox(height: 6),
              const _TransportRow(),
              const SizedBox(height: 18),
              _PillTabs(index: tab, onChanged: onTab),
              const SizedBox(height: 14),
              _TabPanel(track: track, index: tab),
            ],
          ),
        );
      },
    );
  }
}

// --------------------------------------------------------------- wide layout

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.track,
    required this.spin,
    required this.scrub,
    required this.onScrub,
    required this.onScrubEnd,
    required this.tab,
    required this.onTab,
  });

  final SoundItem track;
  final Animation<double> spin;
  final double? scrub;
  final ValueChanged<double> onScrub;
  final ValueChanged<double> onScrubEnd;
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final gutter = Responsive.gutter(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 18),
      child: ReadableWidth(
        maxWidth: 1180,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final leftWidth = constraints.maxWidth * .46;
            final ring = math
                .min(leftWidth - 40, constraints.maxHeight * .82)
                .clamp(180.0, 380.0);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: _ArtworkWithRing(
                      track: track,
                      spin: spin,
                      size: ring,
                      scrub: scrub,
                      onScrub: onScrub,
                      onScrubEnd: onScrubEnd,
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TrackHeading(track: track, align: TextAlign.start),
                        const SizedBox(height: 20),
                        const _SeekRow(),
                        const _TransportRow(),
                        const SizedBox(height: 20),
                        _PillTabs(index: tab, onChanged: onTab),
                        const SizedBox(height: 14),
                        _TabPanel(track: track, index: tab),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- pieces

class _TrackHeading extends StatelessWidget {
  const _TrackHeading({
    required this.track,
    this.align = TextAlign.center,
  });

  final SoundItem track;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final centered = align == TextAlign.center;

    return ReplayOnChange(
      value: track.id,
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            track.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: centered
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (track.isFavorite) ...[
                Icon(Icons.favorite_rounded, size: 13, color: palette.orange),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textFaint,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The ring, the rotating cover inside it, and the play button riding the
/// ring's lower edge — the reference layout's signature detail.
class _ArtworkWithRing extends StatelessWidget {
  const _ArtworkWithRing({
    required this.track,
    required this.spin,
    required this.size,
    required this.scrub,
    required this.onScrub,
    required this.onScrubEnd,
  });

  final SoundItem track;
  final Animation<double> spin;
  final double size;
  final double? scrub;
  final ValueChanged<double> onScrub;
  final ValueChanged<double> onScrubEnd;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    // Extra room at the bottom for the play button that overhangs the ring.
    final overhang = size * .16;

    return SizedBox(
      height: size + overhang,
      width: size,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          ValueListenableBuilder<Duration>(
            valueListenable: state.position,
            builder: (context, position, _) {
              final fraction = track.duration.inMilliseconds == 0
                  ? 0.0
                  : (position.inMilliseconds /
                            track.duration.inMilliseconds)
                        .clamp(0.0, 1.0);
              return ProgressRing(
                size: size,
                progress: scrub ?? fraction,
                strokeWidth: size * .022,
                enabled: true,
                onSeek: onScrub,
                child: Padding(
                  padding: EdgeInsets.all(size * .055),
                  child: Hero(
                    tag: HeroTags.artwork(track.id),
                    child: RotationTransition(
                      turns: spin,
                      child: AlbumArt(
                        seed: track.seed,
                        size: size * .74,
                        circle: true,
                        showWave: false,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Play/pause, overlapping the bottom of the ring.
          Positioned(
            top: size - size * .088,
            child: _PlayButton(size: size * .195),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = context.palette;

    return Breathing(
      amplitude: state.isPlaying ? .045 : .02,
      child: PressScale(
        onTap: state.togglePlay,
        scale: .9,
        tooltip: state.isPlaying ? 'Pause' : 'Play',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: palette.brandGradient,
            boxShadow: [
              BoxShadow(
                color: palette.orange.withValues(alpha: .45),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: palette.blue.withValues(alpha: .25),
                blurRadius: 44,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(state.isPlaying),
              color: Colors.white,
              size: size * .48,
            ),
          ),
        ),
      ),
    );
  }
}

/// Elapsed / waveform / total.
class _SeekRow extends StatelessWidget {
  const _SeekRow();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final track = state.current;
    final theme = Theme.of(context);
    final palette = context.palette;
    if (track == null) return const SizedBox.shrink();

    final showWave = state.showWaveform;

    return ValueListenableBuilder<Duration>(
      valueListenable: state.position,
      builder: (context, position, _) {
        final fraction = track.duration.inMilliseconds == 0
            ? 0.0
            : (position.inMilliseconds / track.duration.inMilliseconds)
                  .clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showWave)
              SoundWave(
                seed: track.seed,
                progress: fraction,
                height: 46,
                barCount: 46,
                barWidth: 3,
                spacing: 2,
                animateIn: false,
                onSeek: state.seekFraction,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: SlimProgressBar(value: fraction, height: 6),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  formatDuration(position),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Text(
                  '-${formatDuration(track.duration - position)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textFaint,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Shuffle · previous · favourite · next · repeat, with a live equaliser in
/// the favourite slot while playing.
class _TransportRow extends StatelessWidget {
  const _TransportRow();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final track = state.current;
    final palette = context.palette;
    if (track == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SoftIconButton(
          icon: Icons.shuffle_rounded,
          active: state.shuffle,
          onTap: () => state.setShuffle(!state.shuffle),
          size: 44,
          tooltip: state.shuffle ? 'Shuffle on' : 'Shuffle off',
        ),
        SoftIconButton(
          icon: Icons.skip_previous_rounded,
          onTap: state.previous,
          size: 48,
          iconSize: 24,
          tooltip: 'Previous',
        ),
        // The favourite sits in a pill, as in the reference — and swaps to a
        // live equaliser while the track is playing.
        _FavouritePill(track: track),
        SoftIconButton(
          icon: Icons.skip_next_rounded,
          onTap: () => state.next(),
          size: 48,
          iconSize: 24,
          tooltip: 'Next',
        ),
        SoftIconButton(
          icon: switch (state.repeat) {
            LoopMode.off => Icons.repeat_rounded,
            LoopMode.all => Icons.repeat_on_rounded,
            LoopMode.one => Icons.repeat_one_on_rounded,
          },
          active: state.repeat != LoopMode.off,
          activeColor: palette.blue,
          onTap: state.cycleRepeat,
          size: 44,
          tooltip: state.repeat.label,
        ),
      ],
    );
  }
}

class _FavouritePill extends StatelessWidget {
  const _FavouritePill({required this.track});

  final SoundItem track;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = context.palette;
    final playing = state.isPlaying;

    return PressScale(
      onTap: () => state.toggleFavorite(track.id),
      scale: .9,
      tooltip: track.isFavorite
          ? 'Remove from favourites'
          : 'Add to favourites',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: 72,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: track.isFavorite ? palette.orangeWash : palette.surfaceAlt,
          border: Border.all(
            color: track.isFavorite
                ? palette.orange.withValues(alpha: .4)
                : palette.divider,
          ),
          boxShadow: track.isFavorite
              ? palette.lift(blur: 16, y: 6, alpha: .16)
              : const <BoxShadow>[],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: playing && track.isFavorite
                ? NowPlayingBars(
                    key: const ValueKey('bars'),
                    playing: true,
                    size: 20,
                    color: palette.orangeInk,
                  )
                : Icon(
                    track.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(track.isFavorite),
                    size: 20,
                    color: track.isFavorite
                        ? palette.orangeInk
                        : palette.textFaint,
                  ),
          ),
        ),
      ),
    );
  }
}

/// The three-way pill selector under the controls.
class _PillTabs extends StatelessWidget {
  const _PillTabs({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const List<String> _labels = <String>['Up next', 'Lyrics', 'Related'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / _labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: index * slot + 5,
                top: 5,
                width: slot - 10,
                height: 42,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: palette.lift(blur: 14, y: 5, alpha: .16),
                  ),
                ),
              ),
              Row(
                children: List<Widget>.generate(_labels.length, (i) {
                  final selected = i == index;
                  return Expanded(
                    child: PressScale(
                      scale: .96,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 240),
                          style:
                              (selected
                                      ? theme.textTheme.labelMedium?.copyWith(
                                          color: palette.orange,
                                          fontWeight: FontWeight.w800,
                                        )
                                      : theme.textTheme.labelMedium?.copyWith(
                                          color: palette.textFaint,
                                          fontWeight: FontWeight.w600,
                                        )) ??
                              const TextStyle(),
                          child: Text(
                            _labels[i].toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Up next / Lyrics / Related, with a fixed height so the surrounding scroll
/// view never has to guess how tall the panel will be.
class _TabPanel extends StatelessWidget {
  const _TabPanel({required this.track, required this.index});

  final SoundItem track;
  final int index;

  static const double _height = 224;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: AnimatedSwitcher(
        duration: motionDuration(context, const Duration(milliseconds: 320)),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, .06),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: switch (index) {
          0 => _UpNextPanel(key: const ValueKey(0), track: track),
          1 => _LyricsPanel(key: const ValueKey(1), track: track),
          _ => _RelatedPanel(key: const ValueKey(2), track: track),
        },
      ),
    );
  }
}

class _UpNextPanel extends StatelessWidget {
  const _UpNextPanel({super.key, required this.track});

  final SoundItem track;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final queue = state.sounds.where((s) => s.id != track.id).toList();

    if (queue.isEmpty) {
      return const EmptyState(
        icon: Icons.queue_music_rounded,
        title: 'Queue is empty',
        message: 'Add more sounds to build a queue.',
      );
    }

    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      itemCount: queue.length,
      separatorBuilder: (context, _) => const SizedBox(height: 6),
      itemBuilder: (context, i) => StaggeredEntrance(
        index: i,
        stepDelay: const Duration(milliseconds: 45),
        child: PressScale(
          scale: .98,
          onTap: () => state.play(queue[i]),
          child: SoftCard(
            padding: const EdgeInsets.all(10),
            radius: AppTheme.radiusMd,
            elevated: false,
            child: Row(
              children: [
                AlbumArt(seed: queue[i].seed, size: 42, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        queue[i].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        queue[i].artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  queue[i].durationLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder lyrics that scroll their highlight with playback — enough to
/// show the interaction without pretending to ship real lyric data.
class _LyricsPanel extends StatelessWidget {
  const _LyricsPanel({super.key, required this.track});

  final SoundItem track;

  static const List<String> _lines = <String>[
    'City lights are bleeding through the glass',
    'Every mile is music on the dash',
    'Turn it up until the silence breaks',
    'We are the echo that the morning makes',
    'Hold the note a little longer now',
    'Let the low end carry us somehow',
    'Nothing waiting for us back at home',
    'Just the road and one more song to go',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;

    return ValueListenableBuilder<Duration>(
      valueListenable: state.position,
      builder: (context, position, _) {
        final fraction = track.duration.inMilliseconds == 0
            ? 0.0
            : (position.inMilliseconds / track.duration.inMilliseconds)
                  .clamp(0.0, 1.0);
        final active = (fraction * _lines.length)
            .floor()
            .clamp(0, _lines.length - 1);

        return ListView.separated(
          physics: const ClampingScrollPhysics(),
          itemCount: _lines.length,
          separatorBuilder: (context, _) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final isActive = i == active;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 14 : 8,
                vertical: isActive ? 10 : 6,
              ),
              decoration: BoxDecoration(
                color: isActive ? palette.orangeWash : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 320),
                style:
                    (isActive
                            ? theme.textTheme.titleSmall?.copyWith(
                                color: palette.orangeInk,
                                fontWeight: FontWeight.w800,
                              )
                            : theme.textTheme.bodyMedium?.copyWith(
                                color: palette.textFaint,
                              )) ??
                    const TextStyle(),
                child: Text(_lines[i], maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            );
          },
        );
      },
    );
  }
}

class _RelatedPanel extends StatelessWidget {
  const _RelatedPanel({super.key, required this.track});

  final SoundItem track;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    // Same category first, then anything else — a cheap stand-in for a
    // recommendation engine.
    final related = [...state.sounds]
      ..sort((a, b) {
        final aMatch = a.category == track.category ? 0 : 1;
        final bMatch = b.category == track.category ? 0 : 1;
        if (aMatch != bMatch) return aMatch - bMatch;
        return a.seed.compareTo(b.seed);
      });
    final list = related.where((s) => s.id != track.id).take(8).toList();

    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_awesome_rounded,
        title: 'Nothing to relate yet',
        message: 'Add a few more sounds and they will show up here.',
      );
    }

    return GridView.builder(
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 96,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .78,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) => StaggeredEntrance(
        index: i,
        stepDelay: const Duration(milliseconds: 45),
        child: PressScale(
          scale: .94,
          onTap: () => state.play(list[i]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AlbumArt(seed: list[i].seed, radius: 16),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                list[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.palette.textPrimary,
                  letterSpacing: .1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: .99,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 21, color: context.palette.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
