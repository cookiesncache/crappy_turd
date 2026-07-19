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

  /// Pipe width as a fraction of screen width.
  static const double pipeWidth = 0.14;

  /// Vertical gap a pipe leaves for the turd to fly through (fraction of
  /// screen height).
  static const double gapHeight = 0.30;

  /// Minimum clearance kept between a pipe's gap and the ceiling/ground
  /// (fraction of screen height).
  static const double gapMargin = 0.05;

  /// Pipe scroll speed, in screen-widths per second (leftward).
  static const double pipeSpeed = 0.35;

  /// Seconds between pipe spawns.
  static const double spawnInterval = 1.7;

  /// Starting x for a newly spawned pipe, just off the right edge (fraction
  /// of screen width).
  static const double pipeSpawnX = 1.15;

  /// How long the title/game-over overlays take to cross-fade when the
  /// `AnimatedSwitcher` driving them swaps its child (e.g. title ->
  /// playing, or playing -> game-over). A single shared duration since one
  /// switcher now drives every overlay transition.
  static const Duration overlayFadeDuration = Duration(milliseconds: 300);
}
