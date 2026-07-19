import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/cloud.dart';

/// Owns the live list of background clouds. Unlike `PipeField`, this is a
/// purely ambient effect: clouds loop forever instead of despawning, so
/// [clouds] is always exactly [GameConstants.cloudCount] long -- an
/// offscreen cloud is wrapped back around to just past the right edge
/// (with a freshly randomised y/scale) rather than removed.
class CloudField {
  /// An optional [random] can be supplied so tests get deterministic
  /// spawn/wrap placement; defaults to a fresh [math.Random].
  CloudField([math.Random? random]) : _random = random ?? math.Random() {
    // Seed clouds spread across a slightly-wider-than-screen span (from
    // just off the left edge to just off the right) with varied x/y/scale,
    // so the sky doesn't look empty or uniform on first launch.
    const span = 1 + GameConstants.cloudWidth * 2;
    const step = span / GameConstants.cloudCount;
    for (var i = 0; i < GameConstants.cloudCount; i++) {
      final x =
          -GameConstants.cloudWidth + step * i + _random.nextDouble() * step;
      clouds.add(_spawn(x));
    }
  }

  final math.Random _random;

  /// Live clouds, always exactly [GameConstants.cloudCount] long.
  final List<Cloud> clouds = [];

  Cloud _spawn(double x) {
    return Cloud(
      x: x,
      y:
          GameConstants.cloudMinY +
          _random.nextDouble() *
              (GameConstants.cloudMaxY - GameConstants.cloudMinY),
      scale:
          GameConstants.cloudMinScale +
          _random.nextDouble() *
              (GameConstants.cloudMaxScale - GameConstants.cloudMinScale),
    );
  }

  /// Advance every cloud by [dt] seconds; any that have drifted fully
  /// offscreen wrap back around to just past the right edge with a fresh
  /// y/scale, rather than being removed.
  void update(double dt) {
    for (final cloud in clouds) {
      cloud.update(dt);
    }
    for (var i = 0; i < clouds.length; i++) {
      if (clouds[i].isOffscreen) {
        // Sized from cloudMaxScale, not the departing cloud's own scale --
        // _spawn rolls a fresh, independent scale for the replacement, so
        // the offset must guarantee clearance for the LARGEST a cloud can
        // possibly be, or a wide replacement could render partially
        // onscreen instead of appearing fully offscreen.
        clouds[i] = _spawn(
          1 + GameConstants.cloudWidth * GameConstants.cloudMaxScale,
        );
      }
    }
  }
}
