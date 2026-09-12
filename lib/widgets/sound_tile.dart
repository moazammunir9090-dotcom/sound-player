import 'package:flutter/material.dart';

import '../models/sound_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'album_art.dart';
import 'equalizer_bars.dart';
import 'press_scale.dart';
import 'staggered_entrance.dart';

/// A heart that pops when toggled.
///
/// The scale overshoot comes from [Curves.easeOutBack] rather than an elastic
/// curve, which reads as a deliberate snap instead of a wobble.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    this.onTap,
    this.size = 20,
    this.buttonSize = 38,
    this.showBackground = true,
  });

  final bool isFavorite;
  final VoidCallback? onTap;
  final double size;
  final double buttonSize;
  final bool showBackground;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 1,
  );

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
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
    final palette = context.palette;

    final heart = AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_c.value.clamp(0.0, 1.0));
        return Transform.scale(scale: .72 + .28 * t, child: child);
      },
      child: Icon(
        widget.isFavorite
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        size: widget.size,
        color: widget.isFavorite ? palette.orangeInk : palette.textFaint,
      ),
    );

    if (!widget.showBackground) {
      return PressScale(
        onTap: widget.onTap,
        scale: .85,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: heart,
        ),
      );
    }

    return PressScale(
      onTap: widget.onTap,
      scale: .88,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: widget.buttonSize,
        height: widget.buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isFavorite
              ? palette.orangeWash
              : palette.surfaceAlt,
          border: Border.all(
            color: widget.isFavorite
                ? palette.orange.withValues(alpha: .35)
                : palette.divider,
          ),
        ),
        alignment: Alignment.center,
        child: heart,
      ),
    );
  }
}

/// A row in the library list.
///
/// The three trailing affordances (playing indicator / favourite / duration)
/// swap places with an [AnimatedSwitcher] so the row never changes width when
/// the playing track changes.
class SoundTile extends StatelessWidget {
  const SoundTile({
    super.key,
    required this.sound,
    this.isPlaying = false,
    this.isCurrent = false,
    this.onTap,
    this.onFavorite,
    this.onMore,
    this.showArtwork = true,
    this.dense = false,
  });

  final SoundItem sound;
  final bool isPlaying;
  final bool isCurrent;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onMore;
  final bool showArtwork;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final artSize = dense ? 42.0 : 52.0;

    return PressScale(
      onTap: onTap,
      scale: .985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 10 : 12,
          vertical: dense ? 8 : 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          color: isCurrent ? palette.orangeWash : Colors.transparent,
          border: Border.all(
            color: isCurrent
                ? palette.orange.withValues(alpha: .28)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            if (showArtwork) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  AlbumArt(
                    seed: sound.seed,
                    size: artSize,
                    radius: dense ? 12 : 15,
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 260),
                    opacity: isCurrent ? 1 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .42),
                        borderRadius: BorderRadius.circular(dense ? 12 : 15),
                      ),
                      child: SizedBox(
                        width: artSize,
                        height: artSize,
                        child: Center(
                          child: NowPlayingBars(
                            playing: isPlaying,
                            size: dense ? 14 : 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: dense ? 12 : 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sound.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? palette.orangeInk : palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${sound.artist} · ${sound.collection}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (onFavorite != null)
              FavoriteButton(
                isFavorite: sound.isFavorite,
                onTap: onFavorite,
                size: dense ? 17 : 19,
                buttonSize: dense ? 32 : 36,
                showBackground: !dense,
              ),
            const SizedBox(width: 6),
            if (onMore != null)
              SoftIconButton(
                icon: Icons.more_horiz_rounded,
                onTap: onMore,
                size: dense ? 32 : 36,
                iconSize: dense ? 17 : 18,
                tooltip: 'More options',
              ),
            if (onMore == null)
              SizedBox(
                width: 46,
                child: Text(
                  sound.durationLabel,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textFaint,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tall card for the horizontal "recently added" rail.
class SoundCard extends StatelessWidget {
  const SoundCard({
    super.key,
    required this.sound,
    this.width = 158,
    this.onTap,
    this.isPlaying = false,
    this.isCurrent = false,
  });

  final SoundItem sound;
  final double width;
  final VoidCallback? onTap;
  final bool isPlaying;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return PressScale(
      onTap: onTap,
      scale: .96,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AlbumArt(
                  seed: sound.seed,
                  width: width,
                  height: width,
                  radius: AppTheme.radiusMd,
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    scale: isCurrent ? 1 : 0,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .92),
                      ),
                      child: Center(
                        child: NowPlayingBars(
                          playing: isPlaying,
                          size: 15,
                          color: palette.orangeDeep,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              sound.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isCurrent ? palette.orange : palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sound.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The empty-state used whenever a filter or search returns nothing.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return StaggeredEntrance(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: palette.washGradient,
                  border: Border.all(color: palette.divider),
                ),
                child: Icon(icon, size: 32, color: palette.orange),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textFaint,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
