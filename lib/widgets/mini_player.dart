import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'album_art.dart';
import 'animated_background.dart';
import 'equalizer_bars.dart';
import 'press_scale.dart';
import 'soft_card.dart';

/// The compact transport that floats above the bottom navigation.
///
/// Renders nothing when no track is loaded — the home shell animates it in and
/// out with a slide, so this widget only has to describe its *loaded* state.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.onOpen});

  /// Called when the surface is tapped; the home shell pushes the player.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final track = state.current;
    if (track == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final palette = context.palette;

    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress is its own listener so the 5 Hz position tick repaints a
          // 3 px bar instead of the whole shell.
          ValueListenableBuilder<Duration>(
            valueListenable: state.position,
            builder: (context, position, _) {
              final fraction = track.duration.inMilliseconds == 0
                  ? 0.0
                  : (position.inMilliseconds /
                            track.duration.inMilliseconds)
                        .clamp(0.0, 1.0);
              return SlimProgressBar(value: fraction, height: 3);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // The artwork and titles take the leftover width, so a long
              // title ellipsises instead of shouldering the transport buttons
              // off the side of a narrow phone.
              Expanded(
                child: PressScale(
                  onTap: onOpen,
                  scale: .94,
                  child: Row(
                    children: [
                      AlbumArt(seed: track.seed, size: 42, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: palette.textFaint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (state.isPlaying)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: EqualizerBars(
                    barCount: 4,
                    height: 20,
                    barWidth: 3,
                    gap: 3,
                  ),
                ),
              MiniTransportControls(onOpen: onOpen),
            ],
          ),
        ],
      ),
    );
  }
}

/// Play/pause plus skip, used by the mini player.
class MiniTransportControls extends StatelessWidget {
  const MiniTransportControls({super.key, this.onOpen, this.compact = false});

  final VoidCallback? onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = context.palette;
    final size = compact ? 36.0 : 40.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PressScale(
          onTap: () => state.previous(),
          scale: .88,
          tooltip: 'Previous',
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.skip_previous_rounded,
              size: compact ? 20 : 22,
              color: palette.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 2),
        PressScale(
          onTap: state.togglePlay,
          scale: .88,
          tooltip: state.isPlaying ? 'Pause' : 'Play',
          child: Container(
            width: size + 4,
            height: size + 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: palette.brandGradient,
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                key: ValueKey(state.isPlaying),
                size: compact ? 22 : 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        PressScale(
          onTap: () => state.next(),
          scale: .88,
          tooltip: 'Next',
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.skip_next_rounded,
              size: compact ? 20 : 22,
              color: palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
