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
      puffs: _randomPuffs(),
    );
  }

  /// A fresh cumulus-style shape: a row of smaller puffs whose bottoms sit
  /// on one shared baseline (the flat underside real fair-weather clouds
  /// have), topped by two or three bigger puffs billowing up from the
  /// middle. Kept within about 1.15 cloud-radii of the centre
  /// horizontally, which `Cloud.isOffscreen` relies on.
  List<CloudPuff> _randomPuffs() {
    const baseline = 0.35;
    double jitter(double amount) => (_random.nextDouble() * 2 - 1) * amount;
    double between(double lo, double hi) =>
        lo + _random.nextDouble() * (hi - lo);

    final puffs = <CloudPuff>[];
    final baseCount = 4 + _random.nextInt(2);
    for (var i = 0; i < baseCount; i++) {
      final radius = between(0.26, 0.36);
      puffs.add(
        CloudPuff(
          -0.72 + 1.44 * i / (baseCount - 1) + jitter(0.05),
          baseline - radius + jitter(0.02),
          radius,
        ),
      );
    }
    final crownCount = 2 + _random.nextInt(2);
    final crownSpan = crownCount == 2 ? 0.3 : 0.4;
    for (var i = 0; i < crownCount; i++) {
      final radius = between(0.38, 0.55);
      puffs.add(
        CloudPuff(
          -crownSpan + 2 * crownSpan * i / (crownCount - 1) + jitter(0.08),
          baseline - radius - between(0.12, 0.32),
          radius,
        ),
      );
    }
    return puffs;
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
