import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Owns playback of Crappy Turd's three short sound effects -- a comedic
/// fart on every flap, a cheerful "ding" on scoring, and a light "womp" on
/// death -- plus the [muted] switch that silences all three together.
///
/// Unlike the rest of `lib/game/`, this class legitimately depends on the
/// `audioplayers` plugin rather than staying pure Dart -- playing sound is
/// inherently a platform concern.
///
/// Tuned so a play call costs next to nothing on Android, where the
/// plugin's defaults made every flap hitch the game:
///
/// * **No audio focus.** By default every play requests Android audio
///   focus (and abandons it when the clip ends) -- a blocking system call
///   on the thread that also runs the game's frames, which also pauses
///   whatever music the player had going. [_audioContext] mixes with other
///   audio instead, which is what game sound effects should do anyway.
/// * **Low-latency mode** (Android's `SoundPool`): each clip is decoded
///   into memory once, and a play is a single cheap native call, instead
///   of driving a `MediaPlayer` through start/pause/seek every time.
/// * **Everything preloaded.** Each sound gets [_voicesPerSound] players,
///   all loaded at startup and reused round-robin, so a quick run of flaps
///   overlaps instead of cutting itself off, and no player is ever created
///   mid-game.
///
/// Low-latency mode sends no completion events, so a voice is rewound
/// with `stop()` right before each `resume()` rather than being recycled
/// when its clip finishes. The players use [ReleaseMode.stop] so that
/// `stop()` keeps the loaded clip instead of releasing it. On web the
/// player mode and audio context are no-ops and this is just a few reused
/// `<audio>` elements.
///
/// Every playback (and setup) call is wrapped in a try/catch so a
/// platform/environment where audio genuinely isn't available -- a plain
/// `flutter test` run with no real platform channels, or an unusual
/// browser permission state -- can never crash the app or throw an
/// uncaught exception up through the game loop; playback is silently
/// skipped instead.
class SoundManager {
  /// Starts loading all three sounds in the background.
  SoundManager() {
    _flap = _load('audio/flap.wav');
    _score = _load('audio/score.wav');
    _death = _load('audio/death.wav');
  }

  /// When true, every `play*` method below is a no-op. Off (sounds play)
  /// by default.
  bool muted = false;

  /// How many overlapping copies of one sound can play at once. The flap
  /// clip is 0.25 s long, so three covers even frantic tapping.
  static const int _voicesPerSound = 3;

  /// Sound effects play alongside the player's own music rather than
  /// taking audio focus from it (see the class doc).
  static final AudioContext _audioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  late final Future<_Voices?> _flap;
  late final Future<_Voices?> _score;
  late final Future<_Voices?> _death;

  /// Creates and fully loads [_voicesPerSound] players for the asset at
  /// `assets/$assetPath` (the leading `assets/` comes from `AudioCache`'s
  /// default prefix, so callers only pass the part below that). Returns
  /// null -- rather than letting the exception propagate -- if setup fails
  /// for any reason (no platform audio backend available, asset missing,
  /// etc.).
  static Future<_Voices?> _load(String assetPath) async {
    final players = <AudioPlayer>[];
    try {
      for (var i = 0; i < _voicesPerSound; i++) {
        final player = AudioPlayer();
        players.add(player);
        await player.setAudioContext(_audioContext);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(assetPath));
      }
      return _Voices(players);
    } on Object catch (_) {
      // Deliberately broad: any failure here (missing platform channel,
      // asset problem, etc.) should degrade to "no sound", never crash.
      for (final player in players) {
        unawaited(_disposeQuietly(player));
      }
      return null;
    }
  }

  static Future<void> _disposeQuietly(AudioPlayer player) async {
    try {
      await player.dispose();
    } on Object catch (_) {
      // Nothing meaningful to do if teardown itself fails.
    }
  }

  /// Plays the comedic flap fart. Called on every flap (title/playing/
  /// game-over restart taps alike).
  Future<void> playFlap() => _play(_flap);

  /// Plays the cheerful score "ding". Called once per tick in which at
  /// least one pipe was newly passed.
  Future<void> playScore() => _play(_score);

  /// Plays the light death "womp". Called once, at the moment of a fatal
  /// collision.
  Future<void> playDeath() => _play(_death);

  Future<void> _play(Future<_Voices?> voicesFuture) async {
    if (muted) {
      return;
    }
    try {
      final voices = await voicesFuture;
      await voices?.play();
    } on Object catch (_) {
      // Swallow: a failed/unavailable playback must never crash the game
      // loop that triggered it. Deliberately broad -- see [_load].
    }
  }

  /// Releases every player. Safe to call even if a sound never
  /// successfully loaded.
  Future<void> dispose() async {
    for (final voicesFuture in [_flap, _score, _death]) {
      final voices = await voicesFuture;
      if (voices == null) continue;
      for (final player in voices.players) {
        await _disposeQuietly(player);
      }
    }
  }
}

/// A fixed set of preloaded players for one sound, used round-robin.
class _Voices {
  _Voices(this.players);

  final List<AudioPlayer> players;
  int _next = 0;

  /// Rewinds the least-recently-used voice and starts it. The rewind is
  /// needed because low-latency mode never reports a clip as finished, so
  /// the player still counts as "playing" from its previous use.
  Future<void> play() async {
    final player = players[_next];
    _next = (_next + 1) % players.length;
    await player.stop();
    await player.resume();
  }
}
