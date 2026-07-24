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

  /// Turd width as a fraction of screen WIDTH -- paired with [turdSize]
  /// (which stays a fraction of screen HEIGHT), so the turd's rendered
  /// width now genuinely scales with screen width instead of being
  /// re-derived from screen height, matching how `_PipeGeometry` in
  /// pipe_painter.dart already scales `pipeWidth` from `size.width` while
  /// the gap uses `size.height`.
  ///
  /// Before this constant existed, both axes of the turd's silhouette were
  /// driven by the single `turdSize * size.height` scalar, so on a
  /// narrow/tall viewport the turd's silhouette rendered disproportionately
  /// WIDE relative to the screen's actual width (and to the pipe's own,
  /// correctly width-scaled, gap) -- making the game measurably harder
  /// purely as a function of aspect ratio, not player skill (and easier on
  /// a wide/short viewport, where the opposite happened). See
  /// turd_painter.dart and lib/game/collision.dart.
  ///
  /// Was originally calibrated to exactly preserve pre-fix behaviour at
  /// `Size(400, 800)` (0.26 -- see git history), the aspect ratio
  /// test/collision_test.dart happened to already use. That reference
  /// turned out to be a poor proxy for how this game actually gets
  /// played/tested day to day: on a much wider desktop testing viewport,
  /// preserving the 400x800 reference made the turd's width nearly double
  /// (and the game noticeably harder) relative to what testing had always
  /// felt like, since the old bug had been making it artificially narrow
  /// there the whole time.
  ///
  /// Re-tuned by direct feel after that fix landed, rather than solving
  /// for exact equality at any one reference viewport. Also deliberately
  /// NOT pushed all the way down to fully match old desktop-viewport feel,
  /// since [turdWidthFraction] also governs the turd's visual width:height
  /// PROPORTIONS, not just hitbox difficulty -- going that far would make
  /// the mascot look noticeably thin/elongated on an actual narrow phone
  /// viewport, where width and height scale are meant to stay reasonably
  /// close (see [turdSize]). This value is a deliberate middle ground;
  /// expect it to keep moving as real playtesting feedback comes in.
  static const double turdWidthFraction = 0.20;

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
  /// Kept short and paired with [trailSampleInterval]/a low ghost opacity
  /// (see turd_painter.dart) so the trail reads as a few subtle echoes,
  /// not a distracting smear.
  static const double trailWindow = 0.12;

  /// Minimum seconds between recorded trail samples. Without this, a new
  /// sample every single tick (~60/sec) packed [trailWindow] full of
  /// near-identical, overlapping ghosts that read as a blur rather than a
  /// few distinct echoes.
  static const double trailSampleInterval = 0.045;

  // --- M9: day/night background ---

  /// Seconds of continuous play for the sky to shift from day to peak
  /// night, ONE-WAY (see `_GameScreenState._playTime` in main.dart and the
  /// looping triangle wave in `lib/game/day_night.dart`). The sky doesn't
  /// stop at peak night -- it shifts back to day over the next
  /// [dayNightCycleDuration] seconds and repeats indefinitely, so a full
  /// day->night->day loop takes `2 * dayNightCycleDuration` seconds. This
  /// constant is deliberately the one-way duration, not the round-trip
  /// period -- don't redefine it as the latter. Purely cosmetic -- doesn't
  /// affect physics, pipes, or scoring. Resets to day on every restart, and
  /// freezes wherever it was the moment a run ends, same as everything else
  /// on the frozen game-over scene.
  static const double dayNightCycleDuration = 45;

  /// Day/night amount (see `lib/game/day_night.dart`) above which the
  /// rainbow is fully faded out, as a fraction of the way to peak night --
  /// chosen well below `1.0` so the rainbow fades out quickly at the start
  /// of dusk and, symmetrically (since it's applied to `dayNightT` itself,
  /// which rises then falls), doesn't fade back in until deep into the
  /// return leg toward day -- rather than lingering faintly visible against
  /// an already-darkening sky the whole way through.
  static const double rainbowFadeThreshold = 0.3;

  // Twinkling stars (see lib/models/star.dart, lib/game/star_field.dart).

  /// Number of stars in the fixed background star field -- enough to read
  /// as a starry night sky without looking cluttered against the rainbow
  /// and pipes.
  static const int starCount = 40;

  /// Highest a star may spawn (fraction of screen height) -- near the very
  /// top of the sky.
  static const double starMinY = 0.04;

  /// Lowest a star may spawn (fraction of screen height) -- close to
  /// `GameConstants.groundY`, so stars disperse evenly all the way down
  /// toward the horizon instead of stopping at an arbitrary cutoff partway
  /// down the sky. Safe to extend this close to the ground now that stars
  /// and the rainbow never overlap in time (see [starVisibilityThreshold]
  /// vs [rainbowFadeThreshold]): by the time stars are visible at all, the
  /// rainbow has already fully faded out.
  static const double starMaxY = 0.78;

  /// Smallest a star's render-size hint may be (fraction of screen width) --
  /// its RESTING size before the twinkle size-pulse (see
  /// [starTwinkleMinScale]/[starTwinkleMaxScale]) scales it up or down.
  static const double starMinSize = 0.0015;

  /// Largest a star's render-size hint may be (fraction of screen width).
  static const double starMaxSize = 0.0035;

  /// Slowest a star's twinkle oscillation may run (radians/sec) -- a full
  /// brighten-dim cycle takes roughly 21 seconds at this, the slowest end
  /// of the range, for a gentle, unhurried shimmer rather than a lively
  /// fast twinkle.
  static const double starTwinkleSpeedMin = 0.3;

  /// Fastest a star's twinkle oscillation may run (radians/sec) -- paired
  /// with [starTwinkleSpeedMin] and each star's own random phase offset
  /// (`Star.twinklePhase`) so a whole field of stars never brighten/dim in
  /// lockstep. Even at this, the fastest end of the range, a full cycle
  /// still takes over 6 seconds.
  static const double starTwinkleSpeedMax = 1;

  /// Smallest a star's SIZE multiplier gets at the dimmest point of its
  /// twinkle (relative to its own resting [starMinSize]/[starMaxSize]) --
  /// paired with [starTwinkleMaxScale] so a star doesn't just dim while
  /// twinkling, it visibly shrinks too.
  static const double starTwinkleMinScale = 0.5;

  /// Largest a star's SIZE multiplier gets at the brightest point of its
  /// twinkle -- deliberately above `1.0` so a star visibly GROWS past its
  /// own resting size at peak brightness, not merely back to it.
  static const double starTwinkleMaxScale = 1.4;

  /// Day/night amount (see `lib/game/day_night.dart`) below which the star
  /// field is fully invisible, as a fraction of the way to peak night --
  /// chosen so stars don't start fading in until dusk is already
  /// well-progressed, and (symmetrically, since it's applied to `dayNightT`
  /// itself) fade back out again as soon as the return leg toward day
  /// passes the same point, rather than lingering visible for most of the
  /// trip back. Shares its value with [shootingStarVisibilityThreshold] on
  /// purpose: shooting stars streaking across a sky with no visible
  /// background stars yet would look wrong, so the two fade in together.
  static const double starVisibilityThreshold = 0.5;

  // Shooting stars (see lib/models/shooting_star.dart,
  // lib/game/shooting_star_field.dart).

  /// Shortest gap (seconds) before a new shooting star may spawn. The
  /// actual next-spawn delay is re-randomised within this..
  /// [shootingStarIntervalMax] every time one actually spawns, rather than
  /// ticking on a fixed period, so shooting stars read as occasional and
  /// organic instead of metronomic.
  static const double shootingStarIntervalMin = 4;

  /// Longest gap (seconds) before a new shooting star may spawn.
  static const double shootingStarIntervalMax = 12;

  /// How fast a shooting star streaks across the sky, in screen-widths per
  /// second -- much faster than [cloudSpeed] or [pipeSpeed] since it should
  /// read as a quick, eye-catching streak rather than a slow drift. Fast
  /// enough that, combined with [shootingStarLife], a streak crosses very
  /// nearly the whole screen before it dies rather than fading out
  /// partway across.
  static const double shootingStarSpeed = 1.4;

  /// Length of a shooting star's fading trail, as a fraction of screen
  /// width -- long enough to read clearly as a bold streak rather than a
  /// short dash, short enough to stay a brief flourish rather than a line
  /// across the whole sky.
  static const double shootingStarStreakLength = 0.18;

  /// Stroke width of a shooting star's trail, as a fraction of screen
  /// width -- thick enough to read as a bold, eye-catching streak rather
  /// than a thin scratch.
  static const double shootingStarStrokeWidth = 0.005;

  /// How long a shooting star stays alive after spawning, in seconds --
  /// short, since it's meant to read as a quick streak, not a lingering
  /// object.
  static const double shootingStarLife = 0.8;

  /// Minimum day/night amount (see `lib/game/day_night.dart` --
  /// `0.0` = day, `1.0` = peak night) required for a NEW shooting star to
  /// spawn. Chosen as "at least half-way toward night": a shooting star
  /// streaking across a still-bright blue day sky would read as a visual
  /// bug rather than a feature, so streaks are held back until the sky has
  /// visibly darkened toward twilight. This threshold only gates NEW
  /// spawns -- a shooting star already in flight keeps moving/ageing/
  /// getting culled on its own schedule even if the cycle dips back below
  /// this threshold before it finishes (see `ShootingStarField.update`).
  /// Deliberately the same value as [starVisibilityThreshold], so shooting
  /// stars never appear before the background star field itself has
  /// started fading in.
  static const double shootingStarVisibilityThreshold = 0.5;
}
