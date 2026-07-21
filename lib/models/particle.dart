import 'dart:ui' show Color;

import 'package:crappy_turd/models/particle_shape.dart';

/// A single short-lived decorative particle (a flap "sparkle" or a death
/// "splat"): pure ambient effect with no gameplay impact. [x]/[y] are
/// mutable (fraction of screen width/height respectively); [vx]/[vy]
/// (fraction-per-second), [maxLife] (seconds), [size] (a render-size hint),
/// [color], [shape] and [spin] are all fixed at spawn.
class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.maxLife,
    required this.size,
    required this.color,
    required this.shape,
    this.spin = 0,
  });

  /// Horizontal position, fraction of screen width.
  double x;

  /// Vertical position, fraction of screen height.
  double y;

  /// Horizontal velocity, fraction-of-width per second. Fixed at spawn.
  final double vx;

  /// Vertical velocity, fraction-of-height per second. Fixed at spawn.
  final double vy;

  /// Total lifespan in seconds. Fixed at spawn.
  final double maxLife;

  /// Seconds elapsed since spawn.
  double age = 0;

  /// A small render-size hint (interpreted by `lib/render/particle_painter
  /// .dart` as a fraction of screen width). Fixed at spawn.
  final double size;

  /// Fixed at spawn.
  final Color color;

  /// Which shape `paintParticles` renders this particle as. Fixed at
  /// spawn.
  final ParticleShape shape;

  /// A fixed rotation offset in radians, applied so a burst of several
  /// [ParticleShape.sparkle] particles don't all point the same way.
  /// Unused by [ParticleShape.soft]. Fixed at spawn.
  final double spin;

  /// True once the particle has outlived [maxLife].
  bool get isDead => age >= maxLife;

  /// Fades linearly from 1.0 at spawn (`age == 0`) to 0.0 at
  /// `age == maxLife`.
  double get opacity => (1 - age / maxLife).clamp(0.0, 1.0);

  /// Advance the particle by [dt] seconds.
  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    age += dt;
  }
}
