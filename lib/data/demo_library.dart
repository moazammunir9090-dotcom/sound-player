import '../models/sound_item.dart';

/// Seed content for the library.
///
/// Everything the app shows at first launch comes from here — there is no
/// backend, so this list *is* the database until the user adds their own.
abstract final class DemoLibrary {
  static const List<String> categories = <String>[
    'All',
    'Focus',
    'Ambient',
    'Beats',
    'Nature',
    'Sleep',
    'Podcast',
  ];

  static List<SoundItem> sounds() => <SoundItem>[
    const SoundItem(
      id: 's1',
      title: 'Midnight Drive',
      artist: 'Neon Cartel',
      collection: 'After Hours',
      duration: Duration(minutes: 3, seconds: 42),
      seed: 0,
      category: 'Beats',
      isFavorite: true,
    ),
    const SoundItem(
      id: 's2',
      title: 'Coastal Fog',
      artist: 'Hana Ito',
      collection: 'Slow Mornings',
      duration: Duration(minutes: 5, seconds: 18),
      seed: 1,
      category: 'Ambient',
    ),
    const SoundItem(
      id: 's3',
      title: 'Deep Work Loop',
      artist: 'Studio Kin',
      collection: 'Focus Engine',
      duration: Duration(minutes: 8, seconds: 4),
      seed: 2,
      category: 'Focus',
      isFavorite: true,
    ),
    const SoundItem(
      id: 's4',
      title: 'Rain on Tin',
      artist: 'Field Notes',
      collection: 'Weather Diary',
      duration: Duration(minutes: 12, seconds: 30),
      seed: 3,
      category: 'Nature',
    ),
    const SoundItem(
      id: 's5',
      title: 'Paper Lanterns',
      artist: 'Yuki Sora',
      collection: 'Night Market',
      duration: Duration(minutes: 4, seconds: 9),
      seed: 4,
      category: 'Sleep',
    ),
    const SoundItem(
      id: 's6',
      title: 'The Long Build',
      artist: 'Ship It Weekly',
      collection: 'Season 4',
      duration: Duration(minutes: 42, seconds: 15),
      seed: 5,
      category: 'Podcast',
    ),
    const SoundItem(
      id: 's7',
      title: 'Ember Glow',
      artist: 'Low Tide',
      collection: 'After Hours',
      duration: Duration(minutes: 3, seconds: 55),
      seed: 6,
      category: 'Beats',
    ),
    const SoundItem(
      id: 's8',
      title: 'Blue Hour',
      artist: 'Hana Ito',
      collection: 'Slow Mornings',
      duration: Duration(minutes: 6, seconds: 21),
      seed: 7,
      category: 'Ambient',
      isFavorite: true,
    ),
    const SoundItem(
      id: 's9',
      title: 'Static Bloom',
      artist: 'Neon Cartel',
      collection: 'After Hours',
      duration: Duration(minutes: 4, seconds: 47),
      seed: 8,
      category: 'Beats',
    ),
    const SoundItem(
      id: 's10',
      title: 'Still Water',
      artist: 'Field Notes',
      collection: 'Weather Diary',
      duration: Duration(minutes: 9, seconds: 12),
      seed: 9,
      category: 'Nature',
    ),
  ];

  /// Time-of-day greeting for the home header.
  static String greetingFor(int hour) {
    if (hour < 5) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }
}
