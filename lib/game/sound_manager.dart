import 'package:audioplayers/audioplayers.dart';

/// Owns playback of Crappy Turd's three short sound effects -- a comedic
/// fart on every flap, a cheerful "ding" on scoring, and a light "womp" on
/// death -- plus the [muted] switch that silences all three together.
///
/// Unlike the rest of `lib/game/`, this class legitimately depends on the
/// `audioplayers` plugin rather than staying pure Dart -- playing sound is
/// inherently a platform concern.
///
/// Each sound gets its own persistent [AudioPool] rather than a fresh
/// `AudioPlayer` per play call. An `AudioPool` (see the installed
/// `audioplayers` 6.8.1 source under the pub cache --
/// `audioplayers-6.8.1/lib/src/audio_pool.dart` -- verified directly rather
/// than assumed) is the package's own purpose-built answer to "you for
/// example have extremely quick firing, repetitive or simultaneous
/// sounds": it pre-loads a small pool of `AudioPlayer`s with the asset
/// already set, so firing a play call reuses an already-loaded player
/// instead of paying asset-decode latency on every tap -- exactly what the
/// flap sound needs, since flaps can fire in rapid succession.
///
/// Deliberately left at the pool's default `PlayerMode.mediaPlayer` rather
/// than `PlayerMode.lowLatency`: `audioplayers_platform_interface`'s
/// `PlayerMode` doc comment notes the low-latency distinction "is only
/// relevant for Android", and, more importantly, `AudioPool.start` only
/// auto-recycles a finished player back into its pool via an
/// `onPlayerComplete` listener when NOT in low-latency mode -- low-latency
/// mode fires no completion events at all (per its own doc comment), so
/// the caller becomes responsible for manually timing and invoking the
/// returned stop function per play. For fire-and-forget clips under half a
/// second, the default mode's automatic cleanup is simpler and safer than
/// hand-rolling that bookkeeping for a marginal, Android-only latency
/// gain.
///
/// Every playback (and pool-creation) call is wrapped in a try/catch so a
/// platform/environment where audio genuinely isn't available -- a plain
/// `flutter test` run with no real platform channels, or an unusual
/// browser permission state -- can never crash the app or throw an
/// uncaught exception up through the game loop; playback is silently
/// skipped instead.
class SoundManager {
  SoundManager() {
    _flapPool = _createPool('audio/flap.wav');
    _scorePool = _createPool('audio/score.wav');
    _deathPool = _createPool('audio/death.wav');
  }

  /// When true, every `play*` method below is a no-op. Off (sounds play)
  /// by default.
  bool muted = false;

  late final Future<AudioPool?> _flapPool;
  late final Future<AudioPool?> _scorePool;
  late final Future<AudioPool?> _deathPool;

  /// Creates a pool of pre-loaded players for the asset at
  /// `assets/$assetPath` (the leading `assets/` comes from `AudioCache`'s
  /// default prefix, so callers only need to pass the part below that).
  ///
  /// A few players are allowed in the pool (rather than just one) so a
  /// rapid flurry of flaps can overlap slightly rather than cutting each
  /// other off. Returns null -- rather than letting the exception
  /// propagate -- if creation fails for any reason (no platform audio
  /// backend available, asset missing, etc.).
  static Future<AudioPool?> _createPool(String assetPath) async {
    try {
      return await AudioPool.createFromAsset(path: assetPath, maxPlayers: 3);
    } on Object catch (_) {
      // Deliberately broad: any failure here (missing platform channel,
      // asset problem, etc.) should degrade to "no sound", never crash.
      return null;
    }
  }

  /// Plays the comedic flap fart. Called on every flap (title/playing/
  /// game-over restart taps alike).
  Future<void> playFlap() => _play(_flapPool);

  /// Plays the cheerful score "ding". Called once per tick in which at
  /// least one pipe was newly passed.
  Future<void> playScore() => _play(_scorePool);

  /// Plays the light death "womp". Called once, at the moment of a fatal
  /// collision.
  Future<void> playDeath() => _play(_deathPool);

  Future<void> _play(Future<AudioPool?> poolFuture) async {
    if (muted) {
      return;
    }
    try {
      final pool = await poolFuture;
      await pool?.start();
    } on Object catch (_) {
      // Swallow: a failed/unavailable playback must never crash the game
      // loop that triggered it. Deliberately broad -- see [_createPool].
    }
  }

  /// Releases every pool's player resources. Safe to call even if a pool
  /// never successfully initialized.
  Future<void> dispose() async {
    for (final poolFuture in [_flapPool, _scorePool, _deathPool]) {
      try {
        final pool = await poolFuture;
        await pool?.dispose();
      } on Object catch (_) {
        // Nothing meaningful to do if teardown itself fails. Deliberately
        // broad -- see [_createPool].
      }
    }
  }
}
