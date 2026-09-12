import 'package:flutter/material.dart';

import '../app_info.dart';
import '../routes/app_page_route.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/animated_background.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_controls.dart';
import '../widgets/soft_card.dart';

/// Appearance, playback and app preferences.
///
/// Works two ways: embedded as the third tab of the home shell (no scaffold,
/// no back button) or pushed as a standalone route. [embedded] is the only
/// difference between the two.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final body = SettingsView(embedded: embedded, onBack: onBack);
    if (embedded) return body;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(intensity: .8, child: body),
    );
  }
}

/// The settings body, on its own.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          if (!embedded)
            ScreenHeader(
              title: 'Settings',
              subtitle: 'Make Sonora feel like yours',
              onBack: onBack ?? () => Navigator.of(context).maybePop(),
            )
          else
            const ScreenHeader(
              title: 'Settings',
              subtitle: 'Appearance, playback and motion',
              dense: true,
            ),
          Expanded(
            child: ScrollablePage(
              center: false,
              maxWidth: Responsive.formWidth,
              children: [
                const _AppearanceSection(),
                const _PlaybackSection(),
                const _ExperienceSection(),
                const _DataSection(),
                const _AboutSection(),
                _ResetRow(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ sections

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = context.palette;

    return SettingsSection(
      title: 'Appearance',
      subtitle: 'Follows your system by default',
      index: 0,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedSelector<ThemeMode>(
                values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
                selected: state.themeMode,
                onChanged: state.setThemeMode,
                labelOf: (mode) => switch (mode) {
                  ThemeMode.system => 'System',
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                },
                iconOf: (mode) => switch (mode) {
                  ThemeMode.system => Icons.brightness_auto_rounded,
                  ThemeMode.light => Icons.light_mode_rounded,
                  ThemeMode.dark => Icons.dark_mode_rounded,
                },
              ),
              const SizedBox(height: 18),
              Text(
                'ACCENT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 14,
                children: [
                  for (final preset in AccentPreset.values)
                    AccentSwatch(
                      primary: preset.primary,
                      secondary: preset.secondary,
                      label: preset.label,
                      selected: state.accent == preset,
                      onTap: () => state.setAccent(preset),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'The accent tints progress rings, switches and highlights '
                'throughout the app.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textFaint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaybackSection extends StatelessWidget {
  const _PlaybackSection();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = context.palette;

    return SettingsSection(
      title: 'Playback',
      index: 1,
      children: [
        SettingsSliderRow(
          icon: Icons.compare_arrows_rounded,
          title: 'Crossfade',
          subtitle: 'Blend the end of one track into the next',
          value: state.crossfade,
          min: 0,
          max: 12,
          divisions: 12,
          accent: palette.blue,
          format: (v) => v == 0 ? 'Off' : '${v.round()}s',
          onChanged: state.setCrossfade,
        ),
        SettingsSliderRow(
          icon: Icons.speed_rounded,
          title: 'Playback speed',
          subtitle: 'Applies to the whole queue',
          value: state.playbackSpeed,
          min: .5,
          max: 2,
          divisions: 6,
          format: (v) => '${v.toStringAsFixed(2)}x',
          onChanged: state.setPlaybackSpeed,
        ),
        SettingsSwitchRow(
          icon: Icons.skip_next_rounded,
          title: 'Autoplay next',
          subtitle: 'Keep going when a track finishes',
          value: state.autoplayNext,
          accent: palette.blue,
          onChanged: state.setAutoplayNext,
        ),
        SettingsSwitchRow(
          icon: Icons.graphic_eq_rounded,
          title: 'Show waveform',
          subtitle: 'Draw the wave behind the seek bar',
          value: state.showWaveform,
          accent: palette.blue,
          onChanged: state.setShowWaveform,
        ),
      ],
    );
  }
}

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = context.palette;

    return SettingsSection(
      title: 'Experience',
      index: 2,
      children: [
        SettingsSwitchRow(
          icon: Icons.auto_awesome_rounded,
          title: 'Rich motion',
          subtitle: 'Background drift, spinning artwork, entrance cascades',
          value: state.richMotion,
          onChanged: state.setRichMotion,
        ),
        SettingsSwitchRow(
          icon: Icons.vibration_rounded,
          title: 'Haptics',
          subtitle: 'A short tick on important taps',
          value: state.haptics,
          accent: palette.blue,
          onChanged: state.setHaptics,
        ),
        SettingsSwitchRow(
          icon: Icons.animation_rounded,
          title: 'Show introduction again',
          subtitle: 'The onboarding tour plays on the next launch',
          // Inverted on purpose: the switch reads "show it again", the stored
          // flag reads "already seen".
          value: !state.onboardingDone,
          accent: palette.blue,
          onChanged: (showAgain) => state.setOnboardingDone(!showAgain),
        ),
      ],
    );
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = context.palette;
    final favorites = state.favorites.length;
    final totalMinutes = state.sounds.fold<int>(
      0,
      (sum, s) => sum + s.duration.inMinutes,
    );

    return SettingsSection(
      title: 'Library',
      index: 3,
      children: [
        ExpandableTile(
          icon: Icons.folder_open_rounded,
          title: 'Storage',
          subtitle: '${state.sounds.length} sounds on this device',
          accent: palette.blue,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DetailRow(
                label: 'Total sounds',
                value: '${state.sounds.length}',
                icon: Icons.library_music_rounded,
              ),
              DetailRow(
                label: 'Favourites',
                value: '$favorites',
                icon: Icons.favorite_rounded,
              ),
              DetailRow(
                label: 'Total runtime',
                value: '$totalMinutes min',
                icon: Icons.schedule_rounded,
              ),
              DetailRow(
                label: 'Album art',
                value: 'Generated',
                valueColor: palette.blue,
                icon: Icons.palette_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return SettingsSection(
      title: 'About',
      index: 4,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: palette.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            AppInfo.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.orangeWash,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'v${AppInfo.version}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: palette.orangeInk,
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppInfo.blurb,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textFaint,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResetRow extends StatelessWidget {
  const _ResetRow({required this.state});

  final AppState state;

  Future<void> _confirm(BuildContext context) async {
    final palette = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset preferences?'),
        content: const Text(
          'Theme, accent, playback and motion settings all return to their '
          'defaults. Your library is untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    state.resetToDefaults();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences reset to defaults')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: SoftCard(
        color: palette.danger.withValues(alpha: .06),
        borderColor: palette.danger.withValues(alpha: .22),
        onTap: () => _confirm(context),
        child: Row(
          children: [
            IconTile(
              icon: Icons.restart_alt_rounded,
              color: palette.danger,
              size: 42,
              iconSize: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reset preferences',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.danger,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Back to the factory look and feel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: palette.danger.withValues(alpha: .6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience for pushing settings from the player overflow menu.
Future<void> openSettings(BuildContext context) {
  return Navigator.of(context).push(
    AppPageRoute<void>(
      builder: (_) => const SettingsScreen(),
      transition: AppTransition.sharedAxis,
    ),
  );
}
