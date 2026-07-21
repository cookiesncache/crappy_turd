import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/particle.dart';
import 'package:crappy_turd/models/particle_shape.dart';
import 'package:crappy_turd/theme/palette.dart';

/// Owns the live list of decorative particles (flap poofs, a death splat):
/// a pure ambient effect with no gameplay impact. Mirrors `PipeField`'s
/// shape for a `List<T>` owner -- `update(dt)`, spawn helpers, `reset()`.
class ParticleField {
  /// An optional [random] can be supplied so tests get deterministic
  /// scatter directions/speeds; defaults to a fresh [math.Random].
  ParticleField([math.Random? random]) : _random = random ?? math.Random();

  final math.Random _random;

  /// Live particles.
  final List<Particle> particles = [];

  /// Advance every particle by [dt] seconds and drop any that have died.
  void update(double dt) {
    for (final p in particles) {
      p.update(dt);
    }
    particles.removeWhere((p) => p.isDead);
  }

  /// A small burst of twinkling gold/white sparkles at ([originX],
  /// [originY]) (screen fractions), scattered generally upward/outward --
  /// spawned on every flap.
  void burstFlap(double originX, double originY) {
    for (var i = 0; i < GameConstants.flapParticleCount; i++) {
      // Scatter within a wide cone centred on "straight up".
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * math.pi;
      final speed =
          GameConstants.flapParticleSpeed * (0.5 + _random.nextDouble());
      particles.add(
        Particle(
          x: originX,
          y: originY,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          maxLife: GameConstants.flapParticleLife,
          size: GameConstants.flapParticleSize,
          color: _random.nextBool() ? Palette.gold : Palette.sparkleWhite,
          shape: ParticleShape.sparkle,
          // A sparkle's 4 points repeat every 90 degrees, so the full
          // range of visually-distinct rotations is just one quarter turn.
          spin: _random.nextDouble() * math.pi / 2,
        ),
      );
    }
  }

  /// A bigger burst of warm-brown "dust" particles at ([originX],
  /// [originY]) (screen fractions), scattered in every direction -- a
  /// comedic poof, not anything gross, so it reuses the turd's own soft
  /// brown palette rather than anything harsher. Spawned once, at the
  /// moment of a fatal collision.
  void burstDeath(double originX, double originY) {
    for (var i = 0; i < GameConstants.deathParticleCount; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed =
          GameConstants.deathParticleSpeed * (0.5 + _random.nextDouble());
      particles.add(
        Particle(
          x: originX,
          y: originY,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          maxLife: GameConstants.deathParticleLife,
          size: GameConstants.deathParticleSize,
          color: _random.nextBool() ? Palette.turdMid : Palette.turdLight,
          shape: ParticleShape.soft,
        ),
      );
    }
  }

  /// Clear all particles (e.g. on restart from game-over).
  void reset() {
    particles.clear();
  }
}
