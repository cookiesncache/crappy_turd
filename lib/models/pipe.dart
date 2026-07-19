import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';

/// A single scrolling pipe obstacle: two stacked bars with a vertical gap
/// for the turd to fly through. [x] is the pipe's horizontal position as a
/// fraction of screen width (mutable — pipes move); [gapCenterY] is the
/// vertical centre of the gap as a fraction of screen height, fixed at
/// spawn time.
class Pipe {
  Pipe._({required this.x, required this.gapCenterY});

  /// Spawn a new pipe just off the right edge with a randomly placed gap.
  ///
  /// An optional [random] can be supplied so tests get deterministic gap
  /// placement; defaults to a fresh [math.Random].
  factory Pipe.spawn([math.Random? random]) {
    final rand = random ?? math.Random();
    const lo =
        GameConstants.ceiling +
        GameConstants.gapHeight / 2 +
        GameConstants.gapMargin;
    const hi =
        GameConstants.groundY -
        GameConstants.gapHeight / 2 -
        GameConstants.gapMargin;
    final gapCenterY = lo + rand.nextDouble() * (hi - lo);
    return Pipe._(x: GameConstants.pipeSpawnX, gapCenterY: gapCenterY);
  }

  /// Horizontal position, fraction of screen width.
  double x;

  /// Vertical centre of the gap, fraction of screen height.
  final double gapCenterY;

  /// Whether the turd has already flown past this pipe. Set by
  /// `countPipesPassed` (see `lib/game/scoring.dart`) so each pipe is only
  /// ever counted once toward the score.
  bool passed = false;

  /// True once the pipe has fully scrolled past the left edge.
  bool get isOffscreen => x < -GameConstants.pipeWidth;

  /// Advance the pipe by [dt] seconds.
  void update(double dt) {
    x -= GameConstants.pipeSpeed * dt;
  }
}
