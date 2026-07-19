import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/trail_sample.dart';

/// Owns a short rolling window of the turd's recent (y, tilt) history, used
/// to paint a fading motion-trail behind it while playing. Pure Dart, no
/// widget/ticker dependency -- mirrors `PipeField`'s `update(dt)`/`reset()`
/// shape for a `List<T>` owner.
class TrailField {
  /// Samples, oldest first.
  final List<TrailSample> samples = [];

  /// Seconds since the last sample was actually recorded (as opposed to
  /// requested -- see [sample]). Starts high so the very first call after
  /// construction/reset always records immediately.
  double _sinceLastSample = GameConstants.trailSampleInterval;

  /// Age every sample by [dt] seconds and drop any older than
  /// [GameConstants.trailWindow].
  void update(double dt) {
    _sinceLastSample += dt;
    for (final s in samples) {
      s.age += dt;
    }
    samples.removeWhere((s) => s.age > GameConstants.trailWindow);
  }

  /// Record the turd's current [y]/[tilt] as a fresh (zero-age) sample --
  /// but only if at least [GameConstants.trailSampleInterval] seconds have
  /// passed since the last one actually recorded. The caller may call this
  /// every tick (as main.dart does); throttling which of those calls
  /// actually produce a ghost is this class's own job, so a dense ~60/sec
  /// call rate still yields a handful of sparse, distinct echoes rather
  /// than a smear of near-identical overlapping ghosts.
  void sample(double y, double tilt) {
    if (_sinceLastSample < GameConstants.trailSampleInterval) {
      return;
    }
    _sinceLastSample = 0;
    samples.add(TrailSample(y: y, tilt: tilt));
  }

  /// Clear all history (e.g. on restart from game-over).
  void reset() {
    samples.clear();
    _sinceLastSample = GameConstants.trailSampleInterval;
  }
}
