import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/trail_sample.dart';

/// Owns a short rolling window of the turd's recent (y, tilt) history, used
/// to paint a fading motion-trail behind it while playing. Pure Dart, no
/// widget/ticker dependency -- mirrors `PipeField`'s `update(dt)`/`reset()`
/// shape for a `List<T>` owner.
class TrailField {
  /// Samples, oldest first.
  final List<TrailSample> samples = [];

  /// Age every sample by [dt] seconds and drop any older than
  /// [GameConstants.trailWindow].
  void update(double dt) {
    for (final s in samples) {
      s.age += dt;
    }
    samples.removeWhere((s) => s.age > GameConstants.trailWindow);
  }

  /// Record the turd's current [y]/[tilt] as a fresh (zero-age) sample.
  void sample(double y, double tilt) {
    samples.add(TrailSample(y: y, tilt: tilt));
  }

  /// Clear all history (e.g. on restart from game-over).
  void reset() {
    samples.clear();
  }
}
