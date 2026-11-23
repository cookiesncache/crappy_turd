import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';

/// A happy bunny hopping along the grass: pure ambient decoration, no
/// gameplay effect. It loops forever through one hop (airborne for
/// [GameConstants.bunnyHopTime]) and a short sit ([restTime]), travelling
/// [GameConstants.bunnyHopDistance] in [facing]'s direction per hop, while
/// the scrolling ground also carries it left.
class Bunny {
  Bunny({
    required this.x,
    required this.facing,
    required this.scale,
    required this.coat,
    required this.restTime,
  });

  /// Horizontal position of its feet, in screen-heights from the left edge
  /// (the same height-based units as `Pipe.x`, so it scrolls with the
  /// ground at the pipes' speed).
  double x;

  /// 1 when hopping right, -1 when hopping left.
  final int facing;

  /// Size multiplier.
  final double scale;

  /// Index into `Palette.bunnyCoats`.
  final int coat;

  /// How long it sits between hops, in seconds.
  final double restTime;

  /// Seconds into the current hop-then-sit cycle. Starts at 0, the moment
  /// of takeoff.
  double _t = 0;

  double get _cycle => GameConstants.bunnyHopTime + restTime;

  /// True while in the air.
  bool get airborne => _t < GameConstants.bunnyHopTime;

  /// How high its feet are off the grass, in screen-heights: a parabola
  /// through each hop, 0 while sitting.
  double get lift {
    if (!airborne) return 0;
    final p = _t / GameConstants.bunnyHopTime;
    return GameConstants.bunnyHopHeight * scale * 4 * p * (1 - p);
  }

  /// Vertical squash/stretch, for bounce: a little tall while airborne, a
  /// quick squash on landing that springs back over a tenth of a second,
  /// 1 otherwise.
  double get stretch {
    if (airborne) return 1.08;
    final sinceLanding = _t - GameConstants.bunnyHopTime;
    const recover = 0.12;
    if (sinceLanding < recover) {
      return 0.84 + 0.16 * math.sin(sinceLanding / recover * math.pi / 2);
    }
    return 1;
  }

  /// Advance by [dt] seconds. [groundSpeed] is how fast the ground is
  /// scrolling left, in screen-heights per second (0 when it's still).
  void update(double dt, double groundSpeed) {
    if (airborne) {
      x +=
          facing *
          GameConstants.bunnyHopDistance /
          GameConstants.bunnyHopTime *
          dt;
    }
    x -= groundSpeed * dt;
    _t = (_t + dt) % _cycle;
  }
}
