/// Tunable physics & layout constants for Crappy Turd.
///
/// Spatial values are fractions of the screen so the game scales across any
/// device; velocities are in screen-heights per second and gravity in
/// screen-heights per second squared. Tune these live with hot reload.
abstract final class GameConstants {
  /// Fraction of screen height where the ground begins.
  static const double groundY = 0.82;

  /// Turd height as a fraction of screen height.
  static const double turdSize = 0.13;

  /// The turd's fixed horizontal position (fraction of screen width).
  static const double turdX = 0.30;

  /// Downward acceleration.
  static const double gravity = 2.8;

  /// Upward velocity applied on a flap.
  static const double flapVelocity = -0.85;

  /// The turd's starting vertical position (centre, fraction of height).
  static const double startY = 0.42;

  /// Highest the turd's centre may rise (fraction of height).
  static const double ceiling = 0.06;

  /// How far the turd bobs up/down (fraction of height) while on the title
  /// screen.
  static const double bobAmplitude = 0.02;

  /// Angular speed (radians/sec) of the title-screen bob.
  static const double bobSpeed = 2.4;

  /// How long the title overlay takes to fade out once play starts.
  static const Duration titleFadeDuration = Duration(milliseconds: 300);
}
