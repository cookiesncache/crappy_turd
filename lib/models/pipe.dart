import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:crappy_turd/game/constants.dart';

/// A single scrolling pipe obstacle: two stacked bars with a vertical gap
/// for the turd to fly through. [x] is the pipe's horizontal position as a
/// fraction of screen HEIGHT (mutable — pipes move); [gapCenterY] is the
/// vertical centre of the gap as a fraction of screen height, fixed at
/// spawn time.
class Pipe {
  Pipe._({required this.x, required this.gapCenterY});

  /// Spawn a new pipe just off the right edge with a randomly placed gap.
  ///
  /// [x] is height-normalized (see the class doc comment), so unlike the
  /// old width-fraction unit system, the right edge itself is no longer a
  /// fixed x value -- it sits at `size.width / size.height`, which varies
  /// with aspect ratio. The new pipe spawns [GameConstants.pipeSpawnMargin]
  /// past that dynamic edge, which is why the real canvas [size] is
  /// required here.
  ///
  /// An optional [random] can be supplied so tests get deterministic gap
  /// placement; defaults to a fresh [math.Random].
  factory Pipe.spawn(Size size, [math.Random? random]) {
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
    final spawnX = size.width / size.height + GameConstants.pipeSpawnMargin;
    return Pipe._(x: spawnX, gapCenterY: gapCenterY);
  }

  /// Horizontal position, fraction of screen height.
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
