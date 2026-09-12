import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/motion.dart';
import 'press_scale.dart';
import 'soft_card.dart';
import 'staggered_entrance.dart';

/// A titled group of settings rows inside one [SoftCard].
///
/// Children are separated by hairlines automatically, so a row never has to
/// know whether it is first, last, or in the middle.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.index = 0,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Position in the page, used to stagger the section's entrance.
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(height: 1, color: palette.divider));
      }
      rows.add(children[i]);
    }

    return StaggeredEntrance(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldLabel(title),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 4),
                child: Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textFaint,
                  ),
                ),
              ),
            SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon + title + subtitle on the left, [Switch] on the right.
///
/// The icon tile and the row background both animate on toggle, which gives a
/// settings list a sense of state without any extra chrome.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.accent,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final tint = accent ?? palette.orange;

    return PressScale(
      onTap: enabled ? () => onChanged(!value) : null,
      scale: .99,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          color: value ? tint.withValues(alpha: .07) : Colors.transparent,
        ),
        child: Row(
          children: [
            IconTile(
              icon: icon,
              color: value ? tint : palette.textFaint,
              size: 40,
              iconSize: 19,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textFaint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Track and thumb colours come from the theme so every switch in
            // the app toggles identically; only the icon tile carries the
            // per-row accent.
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// A slider row with a live value chip.
class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.format,
    this.subtitle,
    this.divisions,
    this.accent,
    this.label,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  /// Renders the current value, e.g. `4s` or `1.25x`.
  final String Function(double) format;
  final int? divisions;
  final Color? accent;

  /// Shown inside the value chip when the value is being dragged.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final tint = accent ?? palette.orange;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconTile(icon: icon, color: tint, size: 40, iconSize: 19),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
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
              const SizedBox(width: 10),
              // The chip flashes when the value changes, which makes a sliding
              // number legible at a glance.
              FlashOnChange(
                value: value,
                borderRadius: BorderRadius.circular(999),
                color: tint,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: palette.divider),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    format(value),
                    maxLines: 1,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: tint,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tint,
              thumbColor: tint,
              overlayColor: tint.withValues(alpha: .16),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              label: label ?? format(value),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// A segmented control with an indicator that slides between slots.
///
/// Written by hand rather than using `SegmentedButton` because the indicator
/// needs to *travel* — the movement is what tells the eye which option was
/// just chosen.
class SegmentedSelector<T> extends StatelessWidget {
  const SegmentedSelector({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.iconOf,
    this.height = 50,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final IconData? Function(T)? iconOf;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final index = values.indexOf(selected).clamp(0, values.length - 1);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: motionDuration(
                  context,
                  const Duration(milliseconds: 300),
                ),
                curve: Curves.easeOutCubic,
                left: index * slot + 4,
                top: 4,
                width: slot - 8,
                height: height - 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: palette.brandGradient,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: palette.lift(blur: 14, y: 5, alpha: .24),
                  ),
                ),
              ),
              Row(
                children: values.map((value) {
                  final isSelected = value == selected;
                  final icon = iconOf?.call(value);
                  return Expanded(
                    child: PressScale(
                      scale: .96,
                      onTap: () => onChanged(value),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(
                                icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : palette.textSecondary,
                              ),
                              const SizedBox(width: 7),
                            ],
                            Flexible(
                              child: Text(
                                labelOf(value),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : palette.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A row that expands to reveal more content, with a chevron that turns.
class ExpandableTile extends StatefulWidget {
  const ExpandableTile({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.accent,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final Color? accent;
  final bool initiallyExpanded;

  @override
  State<ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<ExpandableTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.initiallyExpanded ? 1 : 0,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    tapFeedback(context);
    if (_c.value > .5) {
      _c.reverse();
    } else {
      _c.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final tint = widget.accent ?? palette.blue;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PressScale(
              onTap: _toggle,
              scale: .99,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconTile(
                      icon: widget.icon,
                      color: tint,
                      size: 40,
                      iconSize: 19,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle!,
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
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: _c.value * .5,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: palette.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: Curves.easeOutCubic.transform(_c.value),
                child: Opacity(
                  opacity: _c.value.clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A circular accent swatch with an animated selection ring.
class AccentSwatch extends StatelessWidget {
  const AccentSwatch({
    super.key,
    required this.primary,
    required this.secondary,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final Color primary;
  final Color secondary;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return PressScale(
      onTap: onTap,
      scale: .9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 52,
            padding: EdgeInsets.all(selected ? 4 : 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? primary : palette.divider,
                width: selected ? 2.4 : 1,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selected ? 1 : 0,
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? palette.textPrimary : palette.textFaint,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}
