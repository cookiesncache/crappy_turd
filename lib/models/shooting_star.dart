/// A single in-flight shooting star: pure ambient decoration, no gameplay
/// effect. Closely mirrors `Particle`'s shape -- mutable [x]/[y] driven by
/// a fixed velocity, an [age]/[maxLife] pair, an [isDead] getter, and the
/// same linear age/maxLife [opacity] fade -- but moves in one straight
/// diagonal streak rather than particle-style scatter, and is painted as a
/// fading trail/streak rather than a dot (see
/// `lib/render/shooting_star_painter.dart`).
class ShootingStar {
  ShootingStar({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.maxLife,
  });

  /// Horizontal position of the streak's head, fraction of screen width.
  double x;

  /// Vertical position of the streak's head, fraction of screen height.
  double y;

  /// Horizontal velocity, fraction-of-width per second. Fixed at spawn.
  final double vx;

  /// Vertical velocity, fraction-of-height per second. Fixed at spawn.
  final double vy;

  /// Total lifespan in seconds. Fixed at spawn.
  final double maxLife;

  /// Seconds elapsed since spawn.
  double age = 0;

  /// True once the shooting star has outlived [maxLife].
  bool get isDead => age >= maxLife;

  /// Fades linearly from 1.0 at spawn (`age == 0`) to 0.0 at
  /// `age == maxLife` -- same linear fade shape as `Particle.opacity`.
  double get opacity => (1 - age / maxLife).clamp(0.0, 1.0);

  /// Advance the shooting star by [dt] seconds.
  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    age += dt;
  }
}
