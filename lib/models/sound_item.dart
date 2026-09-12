import 'package:flutter/foundation.dart';

/// Where a sound came from. Drives the badge on the Add Sound review step.
enum SoundSource {
  file('From files', 'Imported from this device'),
  recording('Recorded', 'Captured with the microphone'),
  link('From a link', 'Pulled from a URL');

  const SoundSource(this.label, this.blurb);

  final String label;
  final String blurb;
}

/// A single track in the library.
///
/// There is no audio backend in this project — [duration] and the playback
/// position are simulated — but the model is shaped exactly like the real
/// thing so swapping in a player package later touches nothing else.
@immutable
class SoundItem {
  const SoundItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.collection,
    required this.duration,
    required this.seed,
    this.category = 'All',
    this.isFavorite = false,
    this.source = SoundSource.file,
    this.addedAt,
  });

  final String id;
  final String title;
  final String artist;

  /// Album or playlist name.
  final String collection;
  final Duration duration;

  /// Drives the procedurally generated artwork, so the library looks varied
  /// without shipping a single image asset.
  final int seed;

  final String category;
  final bool isFavorite;
  final SoundSource source;
  final DateTime? addedAt;

  String get durationLabel => formatDuration(duration);

  SoundItem copyWith({
    String? title,
    String? artist,
    String? collection,
    Duration? duration,
    int? seed,
    String? category,
    bool? isFavorite,
    SoundSource? source,
  }) {
    return SoundItem(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      collection: collection ?? this.collection,
      duration: duration ?? this.duration,
      seed: seed ?? this.seed,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      source: source ?? this.source,
      addedAt: addedAt,
    );
  }
}

/// `3:07` / `1:02:44` — used on every tile, so it lives with the model.
String formatDuration(Duration d) {
  final seconds = d.inSeconds.clamp(0, 359999);
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final mm = h > 0 ? m.toString().padLeft(2, '0') : m.toString();
  return h > 0
      ? '$h:$mm:${s.toString().padLeft(2, '0')}'
      : '$mm:${s.toString().padLeft(2, '0')}';
}
