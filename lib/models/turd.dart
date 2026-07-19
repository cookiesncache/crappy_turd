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

  /// The tilt actually displayed (and collided with -- see
  /// `lib/game/collision.dart`), eased toward the velocity-driven target
  /// each frame in [update]/[hover] rather than snapping to it instantly.
  /// Starts level.
  double _displayTilt = 0;

  /// Squash/stretch pulse: positive stretches the turd taller/thinner (set
  /// by [flap]), negative squashes it shorter/wider (set by [impact]).
  /// Decays back toward 0 every [update]/[hover] call. RENDER-ONLY -- see
  /// [scaleX]/[scaleY].
  double _squashPulse = 0;

  /// The last absolute time (seconds) passed to [hover], used to derive a
  /// per-call `dt` for easing tilt/squash even though `hover`'s own
  /// parameter is an absolute elapsed time, not a delta. `null` until
  /// `hover` has been called at least once.
  double? _lastHoverT;

  /// A gentle tilt (radians), eased toward a velocity-driven target: nose-
  /// up while flapping, nose-down while falling. This is the value both
  /// rendered AND rotated by in `turdCollidesWithPipe` -- unlike
  /// [scaleX]/[scaleY], tilt has always been part of collision, so easing
  /// it here changes both together, on purpose.
  double get tilt => _displayTilt;

  /// Horizontal squash/stretch scale factor (1.0 = no squash/stretch).
  /// RENDER-ONLY -- deliberately not read by `lib/game/collision.dart`. See
  /// the comment there and in `lib/render/game_painter.dart`'s
  /// `_paintTurd`.
  double get scaleX => 1 - _squashPulse * 0.5;

  /// Vertical squash/stretch scale factor (1.0 = no squash/stretch).
  /// RENDER-ONLY -- see [scaleX].
  double get scaleY => 1 + _squashPulse;

  /// Give the turd an upward kick, and a brief comedic stretch.
  void flap() {
    velocity = GameConstants.flapVelocity;
    _squashPulse = GameConstants.flapStretchAmount;
  }

  /// A brief comedic squash, triggered at the exact moment of a fatal
  /// collision. RENDER-ONLY: by the time this is called, collision and
  /// scoring have already been decided, so this has zero effect on either.
  void impact() {
    _squashPulse = -GameConstants.impactSquashAmount;
  }

  /// Idle animation for the title screen: gently bob around
  /// [GameConstants.startY] with
  /// velocity held at zero, so a later [flap] launches smoothly from
  /// wherever the bob currently sits rather than teleporting.
  void hover(double t) {
    y =
        GameConstants.startY +
        GameConstants.bobAmplitude * math.sin(t * GameConstants.bobSpeed);
    velocity = 0;
    final dt = _lastHoverT == null ? 0.0 : t - _lastHoverT!;
    _lastHoverT = t;
    _easeTiltAndSquash(dt);
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
    _easeTiltAndSquash(dt);
  }

  /// Eases [_displayTilt] toward the current velocity-driven target and
  /// decays [_squashPulse] back toward 0, both via a frame-rate-independent
  /// exponential decay (unlike a naive fixed-fraction-per-frame lerp, this
  /// converges toward the same place regardless of how `dt` is chopped up).
  void _easeTiltAndSquash(double dt) {
    final target = (velocity * 0.55).clamp(-0.5, 1.1);
    _displayTilt +=
        (target - _displayTilt) *
        (1 - math.exp(-GameConstants.tiltEaseRate * dt));
    _squashPulse -=
        _squashPulse * (1 - math.exp(-GameConstants.squashEaseRate * dt));
  }

  /// Return the turd to its starting state.
  void reset() {
    y = GameConstants.startY;
    velocity = 0;
    _displayTilt = 0;
    _squashPulse = 0;
    _lastHoverT = null;
  }
}
