import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/demo_library.dart';
import '../models/sound_item.dart';
import '../theme/app_colors.dart';

/// The whole app's state: theme choice, the library, and a *simulated*
/// transport.
///
/// There is no audio engine here by design (the brief asks for a pure frontend
/// project), so playback is a [Timer] that advances a position. It behaves like
/// a real player from the UI's point of view — play/pause, seek, skip, auto
/// advance, repeat, shuffle — which is what makes the animations worth
/// watching.
///
/// The ticking position deliberately lives in a separate [ValueNotifier]
/// instead of on this [ChangeNotifier]: at 5 ticks a second, notifying every
/// listener would rebuild the entire tree. Widgets that draw the progress read
/// [position] directly and rebuild only themselves.
class AppState extends ChangeNotifier {
  AppState()
    : sounds = DemoLibrary.sounds(),
      _random = math.Random(7);

  static const Duration tick = Duration(milliseconds: 200);

  final math.Random _random;
  Timer? _timer;

  // ---------------------------------------------------------------- library

  List<SoundItem> sounds;

  /// Filter chip currently selected on Home.
  String selectedCategory = 'All';

  String searchQuery = '';

  List<SoundItem> get visibleSounds {
    final q = searchQuery.trim().toLowerCase();
    return sounds.where((s) {
      final matchesCategory =
          selectedCategory == 'All' || s.category == selectedCategory;
      if (!matchesCategory) return false;
      if (q.isEmpty) return true;
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.collection.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  List<SoundItem> get favorites =>
      sounds.where((s) => s.isFavorite).toList(growable: false);

  List<SoundItem> get recentlyAdded {
    final list = [...sounds];
    // Newest first by seed order for the seeded library; user additions get a
    // monotonically increasing seed so they surface at the front.
    list.sort((a, b) => b.seed.compareTo(a.seed));
    return list.take(6).toList(growable: false);
  }

  void setCategory(String category) {
    if (selectedCategory == category) return;
    selectedCategory = category;
    notifyListeners();
  }

  void search(String query) {
    if (searchQuery == query) return;
    searchQuery = query;
    notifyListeners();
  }

  void addSound(SoundItem item) {
    sounds = <SoundItem>[item, ...sounds];
    notifyListeners();
  }

  void removeSound(String id) {
    sounds = sounds.where((s) => s.id != id).toList(growable: false);
    if (currentId == id) _stop();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    sounds = sounds
        .map((s) => s.id == id ? s.copyWith(isFavorite: !s.isFavorite) : s)
        .toList(growable: false);
    notifyListeners();
  }

  /// Seed used for the next added sound's generated artwork.
  int get nextSeed =>
      sounds.fold<int>(0, (max, s) => math.max(max, s.seed)) + 1;

  // --------------------------------------------------------------- transport

  String? currentId;
  bool isPlaying = false;
  bool shuffle = false;
  LoopMode repeat = LoopMode.off;

  /// Read by progress widgets; ticked at [tick] while playing.
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  SoundItem? get current {
    final id = currentId;
    if (id == null) return null;
    for (final s in sounds) {
      if (s.id == id) return s;
    }
    return null;
  }

  double get progress {
    final track = current;
    if (track == null || track.duration.inMilliseconds == 0) return 0;
    return (position.value.inMilliseconds / track.duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  void play(SoundItem item, {bool restart = false}) {
    if (currentId == item.id && !restart) {
      togglePlay();
      return;
    }
    currentId = item.id;
    position.value = Duration.zero;
    isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  void togglePlay() {
    if (current == null) {
      if (sounds.isEmpty) return;
      play(sounds.first);
      return;
    }
    isPlaying = !isPlaying;
    if (isPlaying) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
    notifyListeners();
  }

  void seek(Duration to) {
    final track = current;
    if (track == null) return;
    position.value = Duration(
      milliseconds: to.inMilliseconds.clamp(0, track.duration.inMilliseconds),
    );
  }

  /// Seek by a fraction of the track — what the ring and slider drags speak in.
  void seekFraction(double fraction) {
    final track = current;
    if (track == null) return;
    seek(
      Duration(
        milliseconds:
            (track.duration.inMilliseconds * fraction.clamp(0.0, 1.0)).round(),
      ),
    );
  }

  void next({bool userInitiated = true}) {
    final list = _playOrder();
    if (list.isEmpty) return;
    final index = list.indexWhere((s) => s.id == currentId);
    if (index == -1) {
      play(list.first);
      return;
    }
    final isLast = index == list.length - 1;
    if (isLast && repeat == LoopMode.off && !userInitiated) {
      isPlaying = false;
      _timer?.cancel();
      notifyListeners();
      return;
    }
    play(list[(index + 1) % list.length]);
  }

  void previous() {
    final list = _playOrder();
    if (list.isEmpty) return;
    // Match every real player: restart the track unless we are near the start.
    if (position.value.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }
    final index = list.indexWhere((s) => s.id == currentId);
    if (index == -1) {
      play(list.first);
      return;
    }
    play(list[(index - 1 + list.length) % list.length]);
  }

  void setShuffle(bool value) {
    if (shuffle == value) return;
    shuffle = value;
    notifyListeners();
  }

  void setRepeat(LoopMode mode) {
    if (repeat == mode) return;
    repeat = mode;
    notifyListeners();
  }

  void cycleRepeat() {
    setRepeat(
      switch (repeat) {
        LoopMode.off => LoopMode.all,
        LoopMode.all => LoopMode.one,
        LoopMode.one => LoopMode.off,
      },
    );
  }

  List<SoundItem> _playOrder() {
    final list = [...sounds];
    if (shuffle) list.shuffle(_random);
    return list;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) {
      final track = current;
      if (track == null) return;
      final nextMs = position.value.inMilliseconds + tick.inMilliseconds;
      if (nextMs >= track.duration.inMilliseconds) {
        if (repeat == LoopMode.one) {
          position.value = Duration.zero;
        } else {
          next(userInitiated: false);
        }
      } else {
        position.value = Duration(milliseconds: nextMs);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    isPlaying = false;
    currentId = null;
    position.value = Duration.zero;
  }

  // ---------------------------------------------------------------- settings

  ThemeMode themeMode = ThemeMode.system;
  AccentPreset accent = AccentPreset.ember;

  /// Master switch for the decorative motion (background blobs, vinyl spin).
  /// Accessibility escape hatch, and it also makes the app usable on a slow
  /// remote desktop session.
  bool richMotion = true;
  bool haptics = true;
  bool autoplayNext = true;
  bool showWaveform = true;

  /// Crossfade length in seconds — a plain slider value in settings.
  double crossfade = 4;
  double playbackSpeed = 1;

  bool onboardingDone = false;

  void setThemeMode(ThemeMode mode) {
    if (themeMode == mode) return;
    themeMode = mode;
    notifyListeners();
  }

  void setAccent(AccentPreset preset) {
    if (accent == preset) return;
    accent = preset;
    notifyListeners();
  }

  void setRichMotion(bool value) {
    if (richMotion == value) return;
    richMotion = value;
    notifyListeners();
  }

  void setHaptics(bool value) {
    if (haptics == value) return;
    haptics = value;
    notifyListeners();
  }

  void setAutoplayNext(bool value) {
    if (autoplayNext == value) return;
    autoplayNext = value;
    notifyListeners();
  }

  void setShowWaveform(bool value) {
    if (showWaveform == value) return;
    showWaveform = value;
    notifyListeners();
  }

  void setCrossfade(double value) {
    if (crossfade == value) return;
    crossfade = value;
    notifyListeners();
  }

  void setPlaybackSpeed(double value) {
    if (playbackSpeed == value) return;
    playbackSpeed = value;
    notifyListeners();
  }

  void completeOnboarding() {
    if (onboardingDone) return;
    onboardingDone = true;
    notifyListeners();
  }

  /// Settings exposes this as "show the introduction again".
  void setOnboardingDone(bool value) {
    if (onboardingDone == value) return;
    onboardingDone = value;
    notifyListeners();
  }

  void resetToDefaults() {
    themeMode = ThemeMode.system;
    accent = AccentPreset.ember;
    richMotion = true;
    haptics = true;
    autoplayNext = true;
    showWaveform = true;
    crossfade = 4;
    playbackSpeed = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    position.dispose();
    super.dispose();
  }
}

enum LoopMode {
  off,
  all,
  one;

  String get label => switch (this) {
    LoopMode.off => 'Repeat off',
    LoopMode.all => 'Repeat all',
    LoopMode.one => 'Repeat one',
  };
}

/// Makes [AppState] available to the tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope?.notifier != null, 'AppScope is missing from the tree.');
    return scope!.notifier!;
  }

  /// Reads the state *without* subscribing — for callbacks and one-shot reads
  /// inside `initState`/`dispose`, where a dependency would be wrong.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope?.notifier != null, 'AppScope is missing from the tree.');
    return scope!.notifier!;
  }
}
