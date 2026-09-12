import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/motion.dart';

/// Wraps anything tappable in a subtle scale-down on press.
///
/// Every button in the app goes through this so the "press" feel is identical
/// everywhere, instead of each screen inventing its own.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = .95,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// How far to shrink while held. Large surfaces want a smaller value.
  final double scale;
  final bool enabled;
  final HitTestBehavior behavior;
  final String? tooltip;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  bool get _interactive => widget.enabled && widget.onTap != null;

  void _set(bool value) {
    if (!_interactive || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final canAnimate = motionEnabled(context);
    final child = GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: _interactive
          ? () {
              tapFeedback(context);
              widget.onTap!.call();
            }
          : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: AnimatedScale(
        scale: _down && canAnimate ? widget.scale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );

    if (widget.tooltip == null) return child;
    return Tooltip(message: widget.tooltip!, child: child);
  }
}

/// A circular icon button with the same press feel, an optional tinted
/// background, and an "active" state that fills with the accent colour.
class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.tooltip,
    this.active = false,
    this.activeColor,
    this.background,
    this.foreground,
    this.badge,
    this.gradientWhenActive = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool active;

  /// Colour used when [active] is true; defaults to the primary accent.
  final Color? activeColor;
  final Color? background;
  final Color? foreground;

  /// Fills with the orange -> blue sweep instead of a flat accent.
  final bool gradientWhenActive;

  /// Small dot drawn at the top-right — used for "changed from default" hints.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final accent = activeColor ?? scheme.primary;

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active && !gradientWhenActive
            ? accent
            : (background ?? palette.surfaceAlt),
        gradient: active && gradientWhenActive ? palette.brandGradient : null,
        border: Border.all(
          color: active ? Colors.transparent : palette.divider,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Icon(
          icon,
          key: ValueKey(icon),
          size: iconSize,
          color: active ? Colors.white : (foreground ?? palette.textPrimary),
        ),
      ),
    );

    return PressScale(
      onTap: onTap,
      scale: .9,
      enabled: onTap != null,
      tooltip: tooltip,
      child: badge == null
          ? button
          : Stack(
              clipBehavior: Clip.none,
              children: [
                button,
                Positioned(top: 1, right: 1, child: badge!),
              ],
            ),
    );
  }
}

/// A pill-shaped button used for category filters, with an animated fill.
class AnimatedPill extends StatelessWidget {
  const AnimatedPill({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    this.onTap,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = context.palette;

    return PressScale(
      onTap: onTap,
      scale: .95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 14 : 18,
          vertical: dense ? 9 : 11,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? scheme.primary : palette.surfaceAlt,
          border: Border.all(
            color: selected ? scheme.primary : palette.divider,
          ),
          boxShadow: selected
              ? palette.lift(blur: 14, y: 5, alpha: .18)
              : const <BoxShadow>[],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: dense ? 14 : 16,
                color: selected ? Colors.white : palette.textSecondary,
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : palette.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app's primary call to action: a filled button carrying the brand sweep.
///
/// It animates its own width when [loading] flips, which is what makes the
/// "Next" button on onboarding and "Save" on Add Sound feel alive.
class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.trailingArrow = false,
    this.loading = false,
    this.expand = false,
    this.enabled = true,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  /// Draws a right arrow that nudges forward while the button is idle.
  final bool trailingArrow;
  final bool loading;
  final bool expand;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final isEnabled = enabled && !loading && onTap != null;

    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1 : .55,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          gradient: palette.brandGradient,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: palette.orange.withValues(alpha: .32),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ] else if (icon != null) ...[
              Icon(icon, size: 19, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
            ),
            if (trailingArrow && !loading) ...[
              const SizedBox(width: 10),
              const _NudgingArrow(),
            ],
          ],
        ),
      ),
    );

    return PressScale(
      onTap: isEnabled ? onTap : null,
      scale: .97,
      child: button,
    );
  }
}

/// Arrow that slides back and forth a few pixels — a small cue that there is
/// somewhere to go next.
class _NudgingArrow extends StatefulWidget {
  const _NudgingArrow();

  @override
  State<_NudgingArrow> createState() => _NudgingArrowState();
}

class _NudgingArrowState extends State<_NudgingArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
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
      builder: (context, child) => Transform.translate(
        offset: Offset(Curves.easeInOut.transform(_c.value) * 4, 0),
        child: child,
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}
