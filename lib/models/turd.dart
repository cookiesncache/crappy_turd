import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';

/// The player's character: a turd pulled down by gravity and pushed up by
/// "flaps". [y] is the vertical centre as a fraction of screen height; the
/// horizontal position is fixed (see [GameConstants.turdX]).
class Turd {
  double y = GameConstants.startY;
  double velocity = 0;

  /// Lowest the centre may fall so the turd rests on top of the ground.
  static const double _floor =
      GameConstants.groundY - GameConstants.turdSize / 2;

  /// A gentle tilt (radians) driven by velocity: nose-up while flapping,
  /// nose-down while falling.
  double get tilt => (velocity * 0.55).clamp(-0.5, 1.1);

  /// Give the turd an upward kick.
  void flap() => velocity = GameConstants.flapVelocity;

  /// Idle animation for the title screen: gently bob around
  /// [GameConstants.startY] with
  /// velocity held at zero, so a later [flap] launches smoothly from
  /// wherever the bob currently sits rather than teleporting.
  void hover(double t) {
    y =
        GameConstants.startY +
        GameConstants.bobAmplitude * math.sin(t * GameConstants.bobSpeed);
    velocity = 0;
  }

  /// Advance the simulation by [dt] seconds.
  void update(double dt) {
    velocity += GameConstants.gravity * dt;
    y += velocity * dt;
    if (y > _floor) {
      y = _floor;
      velocity = 0;
    } else if (y < GameConstants.ceiling) {
      y = GameConstants.ceiling;
      velocity = 0;
    }
  }

  /// Return the turd to its starting state.
  void reset() {
    y = GameConstants.startY;
    velocity = 0;
  }
}
