import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/shooting_star.dart';

/// Owns the live list of shooting stars and their randomised spawn timer.
/// Closer in shape to `PipeField` than to `CloudField`/`StarField`: shooting
/// stars are created, age, and get culled -- they don't loop or sit static
/// forever.
///
/// Unlike `PipeField`'s fixed spawn interval, the "occasional"/organic feel
/// comes from re-randomising the delay until the NEXT spawn (within
/// [GameConstants.shootingStarIntervalMin]..
/// [GameConstants.shootingStarIntervalMax]) every time one actually spawns,
/// rather than ticking on a fixed period.
class ShootingStarField {
  /// An optional [random] can be supplied so tests get deterministic spawn
  /// timing/trajectories; defaults to a fresh [math.Random].
  ShootingStarField([math.Random? random]) : _random = random ?? math.Random() {
    _nextSpawnIn = _rollNextSpawnDelay();
  }

  final math.Random _random;

  /// Live shooting stars, ordered oldest (first spawned) first.
  final List<ShootingStar> shootingStars = [];

  /// Seconds remaining until the next spawn attempt. Re-rolled (see class
  /// doc) every time a shooting star actually spawns.
  late double _nextSpawnIn;

  double _rollNextSpawnDelay() =>
      GameConstants.shootingStarIntervalMin +
      _random.nextDouble() *
          (GameConstants.shootingStarIntervalMax -
              GameConstants.shootingStarIntervalMin);

  /// Advance every in-flight shooting star by [dt] seconds and cull any
  /// that have outlived their `maxLife` -- this always happens, regardless
  /// of [dayNightT], so a shooting star already streaking across the sky
  /// keeps moving/ageing/getting culled on its own schedule even if the
  /// cycle dips back toward day mid-flight.
  ///
  /// Only spawns a NEW shooting star while [dayNightT] is at or above
  /// [GameConstants.shootingStarVisibilityThreshold] -- see that constant's
  /// doc for why. While below the threshold, the spawn countdown simply
  /// holds where it is rather than continuing to run down, so whatever
  /// delay was left over from the last time it mattered is what remains the
  /// next time the sky darkens back up past the threshold.
  void update(double dt, double dayNightT) {
    for (final star in shootingStars) {
      star.update(dt);
    }
    shootingStars.removeWhere((star) => star.isDead);

    if (dayNightT < GameConstants.shootingStarVisibilityThreshold) {
      return;
    }

    _nextSpawnIn -= dt;
    // A `while`, not an `if`, mirroring `PipeField.update`: a single very
    // large `dt` (e.g. a frame hitch) could otherwise cross several spawn
    // delays at once and silently drop all but one.
    while (_nextSpawnIn <= 0) {
      shootingStars.add(_spawn());
      _nextSpawnIn += _rollNextSpawnDelay();
    }
  }

  /// Spawns just off the top-right of the sky and streaks down-left, the
  /// classic shooting-star trajectory, somewhere within the same upper-sky
  /// band the twinkling stars occupy.
  ShootingStar _spawn() {
    final y =
        GameConstants.starMinY +
        _random.nextDouble() *
            (GameConstants.starMaxY - GameConstants.starMinY);
    const speed = GameConstants.shootingStarSpeed;
    return ShootingStar(
      x: 1.05,
      y: y * 0.6,
      vx: -speed,
      vy: speed * 0.5,
      maxLife: GameConstants.shootingStarLife,
    );
  }
}
