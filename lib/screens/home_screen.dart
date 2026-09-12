import 'package:flutter/material.dart';

import '../app_info.dart';
import '../data/demo_library.dart';
import '../models/sound_item.dart';
import '../routes/app_page_route.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/motion.dart';
import '../utils/responsive.dart';
import '../widgets/album_art.dart';
import '../widgets/animated_background.dart';
import '../widgets/mini_player.dart';
import '../widgets/press_scale.dart';
import '../widgets/search_field.dart';
import '../widgets/soft_card.dart';
import '../widgets/sound_tile.dart';
import '../widgets/staggered_entrance.dart';
import 'add_sound_screen.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

/// The app shell: three tabs, a mini player pinned above the navigation, and a
/// floating add button.
///
/// Navigation is a bottom bar on phones and a side rail once the window is
/// wide enough for one — the only structural difference between the two
/// layouts.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pages = PageController();

  int _tab = 0;

  static const List<_Destination> _destinations = <_Destination>[
    _Destination('Home', Icons.auto_awesome_mosaic_rounded),
    _Destination('Library', Icons.library_music_rounded),
    _Destination('Settings', Icons.tune_rounded),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (index == _tab) return;
    setState(() => _tab = index);
    _pages.animateToPage(
      index,
      duration: motionDuration(context, const Duration(milliseconds: 320)),
      curve: Curves.easeOutCubic,
    );
  }

  void _openPlayer() {
    Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => const PlayerScreen(),
        transition: AppTransition.slideUp,
      ),
    );
  }

  void _openAdd() {
    Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => const AddSoundScreen(),
        transition: AppTransition.slideUp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isExpanded(context);

    final content = Stack(
      children: [
        PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _HomeTab(),
            _LibraryTab(),
            SettingsView(embedded: true),
          ],
        ),
        Positioned(
          right: Responsive.gutter(context),
          bottom: 16,
          child: _AddButton(onTap: _openAdd),
        ),
      ],
    );

    final body = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SideRail(
                destinations: _destinations,
                index: _tab,
                onSelect: _go,
              ),
              VerticalDivider(width: 1, color: context.palette.divider),
              Expanded(child: content),
            ],
          )
        : Column(
            children: [
              Expanded(child: content),
              _BottomNav(
                destinations: _destinations,
                index: _tab,
                onSelect: _go,
              ),
            ],
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      // The mini player sits outside the page view so it survives a tab
      // switch without restarting its progress animation.
      body: AnimatedBackground(
        intensity: .75,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(child: body),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.gutter(context),
                ),
                child: MiniPlayer(onOpen: _openPlayer),
              ),
              SizedBox(height: wide ? 10 : 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon);

  final String label;
  final IconData icon;
}

// ------------------------------------------------------------------ chrome

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return PressScale(
      scale: .92,
      tooltip: 'Add a sound',
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: palette.brandGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: palette.orange.withValues(alpha: .38),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 7),
            Text(
              'Add',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.destinations,
    required this.index,
    required this.onSelect,
  });

  final List<_Destination> destinations;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.gutter(context),
        6,
        Responsive.gutter(context),
        10,
      ),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  selected: i == index,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    // Selected sits on a wash, so it uses the readable tint of the accent
    // rather than the accent itself — otherwise the label is the *least*
    // legible thing in the bar.
    final color = selected ? palette.orangeInk : palette.textFaint;

    return PressScale(
      onTap: onTap,
      scale: .94,
      tooltip: destination.label,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: selected ? 1.06 : 1,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            child: Icon(destination.icon, size: 21, color: color),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 240),
            style:
                theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ) ??
                const TextStyle(),
            child: Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.destinations,
    required this.index,
    required this.onSelect,
  });

  final List<_Destination> destinations;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return SizedBox(
      width: 108,
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: palette.brandGradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppInfo.wordmark,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < destinations.length; i++)
            _RailItem(
              destination: destinations[i],
              selected: i == index,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          PressScale(
            onTap: () => Navigator.of(context).push(
              AppPageRoute<void>(
                builder: (_) => const AddSoundScreen(),
                transition: AppTransition.slideUp,
              ),
            ),
            scale: .94,
            tooltip: 'Add a sound',
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: palette.brandGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Add',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.textFaint,
                    ),
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

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final color = selected ? palette.orangeInk : palette.textFaint;

    return PressScale(
      onTap: onTap,
      scale: .95,
      tooltip: destination.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? palette.orangeWash : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(destination.icon, size: 21, color: color),
              const SizedBox(height: 4),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- home tab

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = context.palette;
    final gutter = Responsive.gutter(context);
    final sounds = state.visibleSounds;
    final greeting = DemoLibrary.greetingFor(DateTime.now().hour);

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 96),
      children: [
        _GreetingHeader(greeting: greeting, count: state.sounds.length),
        const SizedBox(height: 16),
        SearchField(
          hint: 'Search your sounds',
          initialValue: state.searchQuery,
          onChanged: state.search,
        ),
        const SizedBox(height: 14),
        _CategoryRail(
          categories: DemoLibrary.categories,
          selected: state.selectedCategory,
          onSelect: state.setCategory,
        ),
        const SizedBox(height: 20),
        if (state.selectedCategory == 'All' && state.searchQuery.trim().isEmpty) ...[
          const SectionHeader(
            title: 'Recently added',
            subtitle: 'Fresh in your library',
          ),
          _RecentRail(sounds: state.recentlyAdded),
          const SizedBox(height: 22),
        ],
        SectionHeader(
          title: 'Your library',
          subtitle: sounds.isEmpty
              ? null
              : '${sounds.length} ${sounds.length == 1 ? 'sound' : 'sounds'}',
        ),
        if (sounds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Nothing matches',
              message: state.searchQuery.trim().isEmpty
                  ? 'This category is empty for now.'
                  : 'Try a different word, or clear the search.',
              action: TextButton(
                onPressed: () {
                  state.search('');
                  state.setCategory('All');
                },
                child: Text(
                  'Clear filters',
                  style: TextStyle(color: palette.orange),
                ),
              ),
            ),
          )
        else
          _SoundCollection(sounds: sounds, startIndex: 0),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting, required this.count});

  final String greeting;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final state = AppScope.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.orange,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready when you are',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count == 0
                    ? 'Your library is empty'
                    : '$count sounds, all offline',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textFaint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SoftIconButton(
          icon: state.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          gradientWhenActive: true,
          active: true,
          size: 50,
          iconSize: 24,
          tooltip: 'Shuffle everything',
          onTap: () {
            state.setShuffle(true);
            state.togglePlay();
          },
        ),
      ],
    );
  }
}

/// Horizontally scrolling category chips.
class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    // A fixed height keeps this rail from ever asking its parent for more
    // room than the list has to give.
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => Center(
          child: AnimatedPill(
            label: categories[i],
            selected: categories[i] == selected,
            onTap: () => onSelect(categories[i]),
          ),
        ),
      ),
    );
  }
}

/// The horizontal "recently added" rail.
class _RecentRail extends StatelessWidget {
  const _RecentRail({required this.sounds});

  final List<SoundItem> sounds;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (sounds.isEmpty) {
      return const EmptyState(
        icon: Icons.album_rounded,
        title: 'No sounds yet',
        message: 'Tap add to bring in your first sound.',
      );
    }

    return SizedBox(
      height: 216,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: sounds.length,
        separatorBuilder: (context, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => StaggeredEntrance(
          index: i,
          axis: Axis.horizontal,
          stepDelay: const Duration(milliseconds: 55),
          child: SoundCard(
            sound: sounds[i],
            isCurrent: state.currentId == sounds[i].id,
            isPlaying: state.isPlaying && state.currentId == sounds[i].id,
            onTap: () => state.play(sounds[i]),
          ),
        ),
      ),
    );
  }
}

/// Renders a set of sounds as a row list on phones and a wrap of cards once
/// there is room for more than one column.
class _SoundCollection extends StatelessWidget {
  const _SoundCollection({required this.sounds, this.startIndex = 0});

  final List<SoundItem> sounds;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final compact = Responsive.isCompact(context);

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < sounds.length; i++)
            StaggeredEntrance(
              index: startIndex + i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoundTile(
                  sound: sounds[i],
                  isCurrent: state.currentId == sounds[i].id,
                  isPlaying:
                      state.isPlaying && state.currentId == sounds[i].id,
                  onTap: () => state.play(sounds[i]),
                  onFavorite: () => state.toggleFavorite(sounds[i].id),
                  onMore: () => _showActions(context, sounds[i]),
                ),
              ),
            ),
        ],
      );
    }

    final columns = Responsive.columns(context, minTile: 240);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < sounds.length; i++)
              StaggeredEntrance(
                index: startIndex + i,
                child: SizedBox(
                  width: tileWidth,
                  child: SoundTile(
                    sound: sounds[i],
                    isCurrent: state.currentId == sounds[i].id,
                    isPlaying:
                        state.isPlaying && state.currentId == sounds[i].id,
                    onTap: () => state.play(sounds[i]),
                    onFavorite: () => state.toggleFavorite(sounds[i].id),
                    onMore: () => _showActions(context, sounds[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

void _showActions(BuildContext context, SoundItem sound) {
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
                AlbumArt(seed: sound.seed, size: 46, radius: 13),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sound.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(sheetContext).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sound.artist} · ${sound.durationLabel}',
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
          _ActionRow(
            icon: Icons.play_arrow_rounded,
            label: 'Play now',
            onTap: () {
              Navigator.of(sheetContext).pop();
              state.play(sound);
            },
          ),
          _ActionRow(
            icon: sound.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: sound.isFavorite
                ? 'Remove from favourites'
                : 'Add to favourites',
            onTap: () {
              state.toggleFavorite(sound.id);
              Navigator.of(sheetContext).pop();
            },
          ),
          _ActionRow(
            icon: Icons.queue_music_rounded,
            label: 'Play next',
            onTap: () {
              Navigator.of(sheetContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${sound.title} plays next'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          _ActionRow(
            icon: Icons.delete_outline_rounded,
            label: 'Remove from library',
            danger: true,
            onTap: () {
              state.removeSound(sound.id);
              Navigator.of(sheetContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${sound.title} removed'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = danger ? palette.danger : palette.textSecondary;

    return PressScale(
      onTap: onTap,
      scale: .99,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: danger ? color : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ library tab

class _LibraryTab extends StatefulWidget {
  const _LibraryTab();

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> {
  bool _favouritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final gutter = Responsive.gutter(context);

    final source = _favouritesOnly ? state.favorites : state.visibleSounds;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'YOUR COLLECTION',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.blue,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Library',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CountBadge(count: source.length),
          ],
        ),
        const SizedBox(height: 16),
        SearchField(
          hint: 'Filter by title, artist or album',
          initialValue: state.searchQuery,
          onChanged: state.search,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            children: [
              Center(
                child: AnimatedPill(
                  label: 'All',
                  icon: Icons.grid_view_rounded,
                  selected: !_favouritesOnly,
                  onTap: () => setState(() => _favouritesOnly = false),
                ),
              ),
              const SizedBox(width: 8),
              Center(
                child: AnimatedPill(
                  label: 'Favourites',
                  icon: Icons.favorite_rounded,
                  selected: _favouritesOnly,
                  onTap: () => setState(() => _favouritesOnly = true),
                ),
              ),
              const SizedBox(width: 8),
              for (final category in DemoLibrary.categories.skip(1)) ...[
                Center(
                  child: AnimatedPill(
                    label: category,
                    selected:
                        !_favouritesOnly &&
                        state.selectedCategory == category,
                    onTap: () {
                      setState(() => _favouritesOnly = false);
                      state.setCategory(
                        state.selectedCategory == category ? 'All' : category,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (source.isEmpty)
          EmptyState(
            icon: _favouritesOnly
                ? Icons.favorite_border_rounded
                : Icons.library_music_rounded,
            title: _favouritesOnly ? 'No favourites yet' : 'Nothing here',
            message: _favouritesOnly
                ? 'Tap the heart on a sound to keep it close.'
                : 'Add a sound, or clear the filters to see everything.',
          )
        else
          _SoundCollection(sounds: source),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.blueWash,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stacked_bar_chart_rounded, size: 14, color: palette.blue),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
