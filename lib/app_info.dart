/// Product identity in one place — referenced by the splash, the settings
/// About card and the window title.
abstract final class AppInfo {
  static const String name = 'Sonora';
  static const String wordmark = 'SONORA';
  static const String tagline = 'Sound, beautifully organised';
  static const String version = '1.0.0';
  static const String build = '2024.09';

  /// Shown on the About card. No backend, so this is honest about what the
  /// project is.
  static const String blurb =
      'A front-end sound player concept. Playback is simulated — no audio '
      'engine, no network calls, no account.';
}
