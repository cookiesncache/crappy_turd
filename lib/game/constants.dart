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

  // --- M6: parallax clouds ---

  /// Cloud drift speed, in screen-widths per second (leftward). Much
  /// slower than [pipeSpeed] on purpose -- that gap is what reads as
  /// parallax (clouds sit "further back" than the pipes).
  static const double cloudSpeed = 0.03;

  /// Number of clouds drifting in the background at any one time.
  static const int cloudCount = 4;

  /// Highest a cloud may spawn (fraction of screen height) -- the "upper
  /// portion of the sky".
  static const double cloudMinY = 0.05;

  /// Lowest a cloud may spawn (fraction of screen height).
  static const double cloudMaxY = 0.30;

  /// Smallest a cloud's size-variation multiplier may be.
  static const double cloudMinScale = 0.7;

  /// Largest a cloud's size-variation multiplier may be.
  static const double cloudMaxScale = 1.4;

  /// A cloud cluster's typical full width at `scale == 1` (fraction of
  /// screen width). Used both to decide when a cloud has fully cleared the
  /// left edge (`Cloud.isOffscreen`) and where to wrap it back in just past
  /// the right edge (`CloudField`).
  static const double cloudWidth = 0.20;

  // --- M6: particle bursts ---

  /// Particles spawned by a single flap "poof".
  static const int flapParticleCount = 6;

  /// Rough speed scale (fraction-of-screen per second) for flap particles.
  static const double flapParticleSpeed = 0.35;

  /// How long a flap particle lives, in seconds.
  static const double flapParticleLife = 0.4;

  /// Render-size hint for flap particles (fraction of screen width).
  static const double flapParticleSize = 0.012;

  /// Particles spawned by a single death "splat"/poof-of-dust.
  static const int deathParticleCount = 14;

  /// Rough speed scale (fraction-of-screen per second) for death
  /// particles -- a bit faster than a flap poof, for a bigger burst.
  static const double deathParticleSpeed = 0.55;

  /// How long a death particle lives, in seconds.
  static const double deathParticleLife = 0.6;

  /// Render-size hint for death particles (fraction of screen width).
  static const double deathParticleSize = 0.016;

  // --- M6: screen shake ---

  /// How long the post-collision screen shake lasts.
  static const Duration shakeDuration = Duration(milliseconds: 300);

  /// Peak shake displacement, as a fraction of the relevant screen
  /// dimension. Feel-tunable.
  static const double shakeMagnitude = 0.02;

  /// Oscillation frequency (in radians per unit of the shake controller's
  /// 0..1 progress) driving the fast jitter -- high enough to read as a
  /// rattle rather than a slow sway.
  static const double shakeFrequency = 40;

  // --- M6: squash/stretch + eased tilt ---

  /// How quickly the displayed tilt eases toward its velocity-driven
  /// target (1/sec -- higher is snappier). Frame-rate independent
  /// exponential-decay ease, not a naive fixed-fraction-per-frame lerp.
  static const double tiltEaseRate = 12;

  /// How quickly a squash/stretch pulse decays back toward 0 (1/sec). A
  /// bit snappier than [tiltEaseRate] so the wobble settles quickly.
  static const double squashEaseRate = 9;

  /// Squash/stretch pulse applied on `Turd.flap` -- positive, stretches the
  /// turd taller/thinner briefly.
  static const double flapStretchAmount = 0.18;

  /// Squash/stretch pulse applied on impact -- squashes the turd
  /// shorter/wider briefly. Stored as a positive magnitude; applied as
  /// negative.
  static const double impactSquashAmount = 0.22;

  // --- M6: motion trail ---

  /// How many seconds of turd (y, tilt) history the motion trail retains.
  static const double trailWindow = 0.2;
}
