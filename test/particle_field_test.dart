import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/particle_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParticleField', () {
    test('a fresh field has zero particles', () {
      final field = ParticleField(math.Random(1));
      expect(field.particles, isEmpty);
    });

    test('burstFlap adds exactly flapParticleCount particles', () {
      final field = ParticleField(math.Random(1))..burstFlap(0.3, 0.4);
      expect(field.particles.length, GameConstants.flapParticleCount);
    });

    test('burstDeath adds exactly deathParticleCount particles', () {
      final field = ParticleField(math.Random(1))..burstDeath(0.3, 0.4);
      expect(field.particles.length, GameConstants.deathParticleCount);
    });

    test('bursts are additive, not replacing each other', () {
      final field = ParticleField(math.Random(1))
        ..burstFlap(0.3, 0.4)
        ..burstDeath(0.3, 0.4);
      expect(
        field.particles.length,
        GameConstants.flapParticleCount + GameConstants.deathParticleCount,
      );
    });

    test('update moves and ages every particle', () {
      final field = ParticleField(math.Random(1))..burstFlap(0.3, 0.4);
      final startX = field.particles.map((p) => p.x).toList();
      final startY = field.particles.map((p) => p.y).toList();

      field.update(0.1);

      for (var i = 0; i < field.particles.length; i++) {
        expect(field.particles[i].age, closeTo(0.1, 1e-9));
        // vx/vy are randomised but never both exactly zero, so at least
        // one coordinate must have moved.
        final moved =
            field.particles[i].x != startX[i] ||
            field.particles[i].y != startY[i];
        expect(moved, isTrue);
      }
    });

    test('a particle past its maxLife is removed by the next update', () {
      final field = ParticleField(math.Random(1))
        ..burstFlap(0.3, 0.4)
        ..update(GameConstants.flapParticleLife + 0.01);
      expect(field.particles, isEmpty);
    });

    test(
      'a particle short of its maxLife survives an update that stops just '
      'short of it',
      () {
        final field = ParticleField(math.Random(1))
          ..burstFlap(0.3, 0.4)
          ..update(GameConstants.flapParticleLife - 0.01);
        expect(field.particles, isNotEmpty);
      },
    );

    test('reset clears everything', () {
      final field = ParticleField(math.Random(1))
        ..burstFlap(0.3, 0.4)
        ..burstDeath(0.3, 0.4)
        ..reset();
      expect(field.particles, isEmpty);
    });
  });
}
