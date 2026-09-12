import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'press_scale.dart';
import 'staggered_entrance.dart';

/// The header used at the top of every screen.
///
/// Titles are left-aligned and large; the back affordance is a soft circle so
/// it reads the same on a phone and on a desktop window. Everything fades and
/// slides in together, which is what makes a pushed screen feel assembled
/// rather than dumped.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const <Widget>[],
    this.eyebrow,
    this.trailing,
    this.dense = false,
  });

  final String title;
  final String? subtitle;

  /// When non-null a back button is shown.
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Small line above the title, e.g. a time-of-day greeting.
  final String? eyebrow;

  /// Replaces the title area entirely — the home tab greets by name.
  final Widget? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return StaggeredEntrance(
      duration: const Duration(milliseconds: 420),
      offset: 14,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Responsive.gutter(context),
          dense ? 6 : 10,
          Responsive.gutter(context) - 6,
          dense ? 8 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (onBack != null) ...[
                  SoftIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: onBack,
                    size: 42,
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: trailing ??
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (eyebrow != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                eyebrow!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: palette.orange,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (dense
                                    ? theme.textTheme.headlineSmall
                                    : theme.textTheme.headlineMedium)
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.textFaint,
                                ),
                              ),
                            ),
                        ],
                      ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
