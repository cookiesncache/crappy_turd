import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/turd.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Turd physics', () {
    test('gravity builds downward velocity over time', () {
      final turd = Turd()..update(0.1);
      expect(turd.velocity, closeTo(GameConstants.gravity * 0.1, 1e-9));
    });

    test('flap sets an upward (negative) velocity', () {
      final turd = Turd()
        ..velocity = 1
        ..flap();
      expect(turd.velocity, GameConstants.flapVelocity);
      expect(turd.velocity, lessThan(0));
    });

    test('never falls through the ground', () {
      final turd = Turd();
      for (var i = 0; i < 600; i++) {
        turd.update(1 / 60);
      }
      expect(turd.y, lessThanOrEqualTo(GameConstants.groundY));
      expect(turd.velocity, 0);
    });

    test('never rises above the ceiling', () {
      final turd = Turd()
        ..y = GameConstants.ceiling
        ..velocity = -5
        ..update(1 / 60);
      expect(turd.y, greaterThanOrEqualTo(GameConstants.ceiling));
    });

    test('reset restores the starting state', () {
      final turd = Turd()
        ..y = 0.9
        ..velocity = 3
        ..reset();
      expect(turd.y, GameConstants.startY);
      expect(turd.velocity, 0);
    });

    test(
      'hover bobs within amplitude of startY and holds velocity at zero',
      () {
        final turd = Turd();
        for (final t in [0.0, 0.3, 1.0, 2.5, 10.0]) {
          turd.hover(t);
          expect(
            turd.y,
            closeTo(GameConstants.startY, GameConstants.bobAmplitude),
          );
          expect(turd.velocity, 0);
        }
      },
    );
  });
}
