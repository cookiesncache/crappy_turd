import 'package:shared_preferences/shared_preferences.dart';

/// Persists the session's high score across app restarts, under a single
/// [SharedPreferences] key.
///
/// Unlike the rest of `lib/game/`, this class legitimately depends on the
/// `shared_preferences` plugin rather than staying pure Dart -- reading and
/// writing durable storage is inherently a platform concern (see
/// `SoundManager`'s doc comment for the same justification for that class's
/// dependency on `audioplayers`).
///
/// Every plugin call is wrapped in a try/catch so a platform/environment
/// where `shared_preferences` genuinely isn't available -- or where the
/// read/write itself fails for some other reason -- can never crash the
/// app; the high score simply doesn't persist for that call instead.
class HighScoreStore {
  static const String _key = 'high_score';

  /// Returns the previously saved best score, or 0 if none has ever been
  /// saved, or if reading it fails for any reason.
  Future<int> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_key) ?? 0;
    } on Object catch (_) {
      // Deliberately broad: any failure here (missing platform channel,
      // corrupt storage, etc.) should degrade to "no saved score", never
      // crash. Matches SoundManager's pattern for its own plugin calls.
      return 0;
    }
  }

  /// Persists [value] as the new best score.
  Future<void> save(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, value);
    } on Object catch (_) {
      // Swallow: a failed write must never crash the game loop that
      // triggered it. Deliberately broad -- see [load].
    }
  }
}
