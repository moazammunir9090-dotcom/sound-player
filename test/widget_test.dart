import 'package:animation/data/demo_library.dart';
import 'package:animation/models/sound_item.dart';
import 'package:animation/state/app_state.dart';
import 'package:animation/theme/app_colors.dart';
import 'package:animation/theme/app_theme.dart';
import 'package:animation/widgets/sound_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transport', () {
    late AppState state;

    setUp(() => state = AppState());
    // The transport runs a real Timer while playing, so every test has to stop
    // it or the suite keeps a live periodic callback.
    tearDown(() => state.dispose());

    test('starts idle with a populated library', () {
      expect(state.current, isNull);
      expect(state.isPlaying, isFalse);
      expect(state.sounds, isNotEmpty);
      expect(state.position.value, Duration.zero);
    });

    test('play selects the track and starts playback', () {
      final first = state.sounds.first;
      state.play(first);

      expect(state.currentId, first.id);
      expect(state.current?.title, first.title);
      expect(state.isPlaying, isTrue);
    });

    test('playing the current track toggles instead of restarting', () {
      final first = state.sounds.first;
      state.play(first);
      state.play(first);

      expect(state.isPlaying, isFalse);
      expect(state.currentId, first.id);
    });

    test('seekFraction clamps to the track bounds', () {
      final first = state.sounds.first;
      state.play(first);

      state.seekFraction(2);
      expect(state.position.value, first.duration);

      state.seekFraction(-1);
      expect(state.position.value, Duration.zero);
    });

    test('progress tracks the seek position', () {
      final first = state.sounds.first;
      state.play(first);
      state.seekFraction(.5);

      expect(state.progress, closeTo(.5, .001));
    });

    test('next advances and wraps around', () {
      state.play(state.sounds.first);
      state.next();
      expect(state.currentId, state.sounds[1].id);

      state.play(state.sounds.last);
      state.next();
      expect(state.currentId, state.sounds.first.id);
    });

    test('previous restarts the track unless we are near the start', () {
      state.play(state.sounds[1]);
      state.seekFraction(.5);
      state.previous();
      // Past three seconds it rewinds rather than skipping back.
      expect(state.currentId, state.sounds[1].id);
      expect(state.position.value, Duration.zero);

      state.previous();
      expect(state.currentId, state.sounds.first.id);
    });

    test('cycleRepeat walks off -> all -> one -> off', () {
      expect(state.repeat, LoopMode.off);
      state.cycleRepeat();
      expect(state.repeat, LoopMode.all);
      state.cycleRepeat();
      expect(state.repeat, LoopMode.one);
      state.cycleRepeat();
      expect(state.repeat, LoopMode.off);
    });
  });

  group('library', () {
    late AppState state;

    setUp(() => state = AppState());
    tearDown(() => state.dispose());

    test('toggleFavorite flips one sound only', () {
      // The seeded library ships a few favourites already, so pick one that
      // starts out un-favourited to keep the arithmetic honest.
      final target = state.sounds.firstWhere((s) => !s.isFavorite);
      final before = state.favorites.length;

      state.toggleFavorite(target.id);
      expect(state.favorites.length, before + 1);
      expect(state.favorites.any((s) => s.id == target.id), isTrue);

      state.toggleFavorite(target.id);
      expect(state.favorites.length, before);
      expect(state.favorites.any((s) => s.id == target.id), isFalse);
    });

    test('addSound puts the new sound at the front', () {
      final added = SoundItem(
        id: 'user-1',
        title: 'My recording',
        artist: 'Me',
        collection: 'Recordings',
        duration: const Duration(seconds: 42),
        seed: state.nextSeed,
        category: 'Ambient',
        isFavorite: false,
        source: SoundSource.recording,
        addedAt: DateTime(2024, 9, 1),
      );
      final before = state.sounds.length;

      state.addSound(added);
      expect(state.sounds.length, before + 1);
      expect(state.sounds.first.id, 'user-1');
    });

    test('removeSound drops it and stops the transport if it was playing', () {
      final first = state.sounds.first;
      state.play(first);
      state.removeSound(first.id);

      expect(state.sounds.any((s) => s.id == first.id), isFalse);
      expect(state.currentId, isNull);
      expect(state.isPlaying, isFalse);
    });

    test('visibleSounds honours the category filter', () {
      state.setCategory('Nature');
      expect(state.visibleSounds, isNotEmpty);
      expect(state.visibleSounds.every((s) => s.category == 'Nature'), isTrue);
    });

    test('visibleSounds honours the search query across title and artist', () {
      final target = state.sounds.first;
      state.search(target.title.substring(0, 3).toLowerCase());

      expect(state.visibleSounds, isNotEmpty);
      expect(state.visibleSounds.any((s) => s.id == target.id), isTrue);
    });

    test('a query that matches nothing empties the list', () {
      state.search('zzzz-no-such-sound');
      expect(state.visibleSounds, isEmpty);
    });

    test('resetToDefaults restores every preference', () {
      state.setThemeMode(ThemeMode.dark);
      state.setAccent(AccentPreset.azure);
      state.setRichMotion(false);
      state.setShowWaveform(false);
      state.setCrossfade(9);

      state.resetToDefaults();

      expect(state.themeMode, ThemeMode.system);
      expect(state.accent, AccentPreset.ember);
      expect(state.richMotion, isTrue);
      expect(state.showWaveform, isTrue);
      expect(state.crossfade, 4);
    });

    test('onboardingDone starts false and flips once', () {
      expect(state.onboardingDone, isFalse);
      state.completeOnboarding();
      expect(state.onboardingDone, isTrue);
    });
  });

  group('formatDuration', () {
    test('pads seconds and switches to hours when needed', () {
      expect(formatDuration(const Duration(seconds: 5)), '0:05');
      expect(formatDuration(const Duration(minutes: 3, seconds: 7)), '3:07');
      expect(formatDuration(const Duration(hours: 1, minutes: 2)), '1:02:00');
    });
  });

  group('SoundTile', () {
    // The motion helpers read AppScope, so even a leaf widget needs the scope
    // above it in the tree.
    Widget host(Widget child, AppState state) => AppScope(
      state: state,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );

    testWidgets('shows the title and reports a favourite tap', (tester) async {
      final state = AppState();
      addTearDown(state.dispose);
      final sound = DemoLibrary.sounds().first;
      var favourites = 0;

      await tester.pumpWidget(
        host(
          SoundTile(sound: sound, onFavorite: () => favourites++),
          state,
        ),
      );

      expect(find.text(sound.title), findsOneWidget);
      // The subtitle line pairs the artist with the collection.
      expect(
        find.text('${sound.artist} · ${sound.collection}'),
        findsOneWidget,
      );

      await tester.tap(find.byType(FavoriteButton));
      await tester.pump(const Duration(milliseconds: 450));

      expect(favourites, 1);
    });

    testWidgets('renders on a narrow phone without overflowing', (
      tester,
    ) async {
      final state = AppState();
      addTearDown(state.dispose);

      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(SoundTile(sound: DemoLibrary.sounds().first), state),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
