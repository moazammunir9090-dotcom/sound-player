import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'press_scale.dart';

/// The app's standard surface: a rounded panel with a hairline border and a
/// soft ambient shadow.
///
/// Cards are never `Card` widgets — a single widget means the border/shadow
/// rule for the whole app lives in one place, which is what keeps light and
/// dark looking deliberate rather than assembled.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppTheme.radiusLg,
    this.gradient,
    this.color,
    this.onTap,
    this.borderColor,
    this.elevated = true,
    this.scaleOnTap = .985,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Paints the brand sweep (or a custom gradient) behind the content.
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool elevated;
  final double scaleOnTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? palette.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border
            ? Border.all(color: borderColor ?? palette.divider)
            : null,
        boxShadow: elevated
            ? palette.lift(blur: 22, y: 8, alpha: context.isDark ? .28 : .07)
            : const <BoxShadow>[],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return PressScale(onTap: onTap, scale: scaleOnTap, child: content);
  }
}

/// A section title with an optional trailing action, used on every screen so
/// the vertical rhythm stays consistent.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            PressScale(
              onTap: onAction,
              scale: .94,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: palette.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
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

/// Text filled with the brand sweep. Used for the splash wordmark and the
/// "now playing" title accent.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final Gradient? gradient;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) =>
          (gradient ?? palette.brandGradient).createShader(rect),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

/// A label/value row inside a card — used heavily in Settings and in the Add
/// Sound review step.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.dense = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 7 : 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: palette.textFaint),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor ?? palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An icon in a rounded, tinted tile — the visual anchor for every settings
/// row and source card.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.color,
    this.size = 42,
    this.iconSize = 20,
    this.gradient = false,
    this.radius = 14,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;
  final bool gradient;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = color ?? palette.orange;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ? palette.brandGradient : null,
        color: gradient ? null : tint.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: gradient ? Colors.transparent : tint.withValues(alpha: .22),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: gradient ? Colors.white : tint,
      ),
    );
  }
}

/// A label with a small all-caps treatment, used above grouped fields.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Null-aware element: omitted entirely when there is no trailing.
          ?trailing,
        ],
      ),
    );
  }
}

/// A thin animated progress line. Used as the splash loader and as the
/// "playback buffered" bar behind the seek control.
class SlimProgressBar extends StatelessWidget {
  const SlimProgressBar({
    super.key,
    required this.value,
    this.height = 4,
    this.gradient,
    this.background,
    this.radius = 999,
  });

  final double value;
  final double height;
  final Gradient? gradient;
  final Color? background;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: background ?? palette.surfaceSunken,
              ),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  gradient: gradient ?? palette.brandGradient,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
