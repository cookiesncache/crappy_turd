import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/bunny.dart';
import 'package:crappy_turd/theme/palette.dart';

/// Owns the live bunnies and the randomised timer for the next one. Shaped
/// like `ShootingStarField`: bunnies spawn every so often (re-rolling the
/// wait after each), hop across, and are culled once they're off screen.
/// Session-long, like the clouds: a restart doesn't clear them.
class BunnyField {
  /// An optional [random] can be supplied so tests get deterministic spawn
  /// timing and bunnies; defaults to a fresh [math.Random].
  BunnyField([math.Random? random]) : _random = random ?? math.Random() {
    // The first one turns up a bit sooner than usual, so a player sees
    // one early on.
    _nextSpawnIn = _rollNextSpawnDelay() / 2;
  }

  final math.Random _random;

  /// Live bunnies, oldest first.
  final List<Bunny> bunnies = [];

  late double _nextSpawnIn;

  /// How far past either screen edge a bunny spawns and is culled, in
  /// screen-heights: comfortably more than the widest bunny, so one never
  /// pops in or out in view.
  static const double _margin =
      GameConstants.bunnySize * GameConstants.bunnyMaxScale * 1.5;

  double _rollNextSpawnDelay() =>
      GameConstants.bunnyIntervalMin +
      _random.nextDouble() *
          (GameConstants.bunnyIntervalMax - GameConstants.bunnyIntervalMin);

  /// Advance every bunny by [dt] seconds, cull any that have left the
  /// screen (whose real [size] is needed to know where the right edge
  /// is), and spawn a new one when the timer runs out. [groundSpeed] is
  /// how fast the ground is scrolling left, in screen-heights per second:
  /// the pipe speed while playing, 0 otherwise.
  void update(double dt, Size size, {required double groundSpeed}) {
    for (final bunny in bunnies) {
      bunny.update(dt, groundSpeed);
    }
    if (size.isEmpty) return;
    final right = size.width / size.height;
    bunnies.removeWhere(
      (b) => b.x < -_margin || b.x > right + _margin,
    );

    _nextSpawnIn -= dt;
    if (_nextSpawnIn > 0) return;
    _nextSpawnIn = _rollNextSpawnDelay();
    if (bunnies.length < GameConstants.bunnyMaxCount) {
      bunnies.add(_spawn(right, moving: groundSpeed > 0));
    }
  }

  /// While the ground scrolls it carries every bunny left, faster than a
  /// bunny can hop right, so each one has to come in from the right edge;
  /// one hopping right just lingers on screen longer. While the ground is
  /// still, a bunny comes in from either side, hopping inward.
  Bunny _spawn(double right, {required bool moving}) {
    final fromRight = moving || _random.nextBool();
    final int facing;
    if (moving) {
      facing = _random.nextBool() ? 1 : -1;
    } else {
      facing = fromRight ? -1 : 1;
    }
    return Bunny(
      x: fromRight ? right + _margin * 0.9 : -_margin * 0.9,
      facing: facing,
      scale:
          GameConstants.bunnyMinScale +
          _random.nextDouble() *
              (GameConstants.bunnyMaxScale - GameConstants.bunnyMinScale),
      coat: _random.nextInt(Palette.bunnyCoats.length),
      restTime:
          GameConstants.bunnyRestMin +
          _random.nextDouble() *
              (GameConstants.bunnyRestMax - GameConstants.bunnyRestMin),
    );
  }
}
