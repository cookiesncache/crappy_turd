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

    test(
      'reset restores the starting state, including eased tilt and '
      'squash pulse',
      () {
        final turd = Turd()
          ..y = 0.9
          ..velocity = 3
          ..update(0.5) // builds up a non-zero eased tilt
          ..flap() // and a non-zero squash pulse
          ..reset();
        expect(turd.y, GameConstants.startY);
        expect(turd.velocity, 0);
        expect(turd.tilt, 0);
        expect(turd.scaleX, 1);
        expect(turd.scaleY, 1);
      },
    );

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

  group('Turd tilt easing', () {
    test(
      'tilt eases toward the target rather than snapping to it, for a '
      'small dt',
      () {
        final turd = Turd()..velocity = 3;
        const dt = 0.016;
        final targetAfterGravity =
            ((turd.velocity + GameConstants.gravity * dt) * 0.55).clamp(
              -0.5,
              1.1,
            );
        final oldTilt = turd.tilt; // 0, fresh turd
        turd.update(dt);
        expect(turd.tilt, greaterThan(oldTilt));
        expect(turd.tilt, lessThan(targetAfterGravity));
      },
    );

    test('repeated updates converge tilt toward the target', () {
      // Re-pin y/velocity before every update so gravity accumulation and
      // ground clamping never interfere -- this isolates the ease
      // behaviour of `tilt` itself across successive calls.
      const dt = 0.016;
      const velocity = 3.0;
      const target = 1.1; // (velocity * 0.55).clamp(-0.5, 1.1)
      final turd = Turd();
      var previousDistance = (target - turd.tilt).abs();
      for (var i = 0; i < 30; i++) {
        turd
          ..y = GameConstants.startY
          ..velocity = velocity
          ..update(dt);
        final distance = (target - turd.tilt).abs();
        expect(distance, lessThan(previousDistance));
        previousDistance = distance;
      }
      expect(turd.tilt, closeTo(target, 0.05));
    });
  });

  group('Turd squash/stretch', () {
    test('flap sets a positive stretch pulse', () {
      final turd = Turd()..flap();
      expect(turd.scaleY, greaterThan(1));
      expect(turd.scaleX, lessThan(1));
    });

    test('impact sets a negative squash pulse', () {
      final turd = Turd()..impact();
      expect(turd.scaleY, lessThan(1));
      expect(turd.scaleX, greaterThan(1));
    });

    test(
      'the squash pulse decays back toward neutral (scaleY/scaleX -> 1) '
      'over repeated updates, with velocity pinned to 0 each frame so the '
      'target tilt stays (near) 0 and this checks squash decay in '
      'isolation',
      () {
        final turd = Turd()..impact();
        const dt = 0.016;
        var previousDistance = (1 - turd.scaleY).abs();
        for (var i = 0; i < 15; i++) {
          turd
            ..velocity = 0
            ..update(dt);
          final distance = (1 - turd.scaleY).abs();
          expect(distance, lessThan(previousDistance));
          previousDistance = distance;
        }
        expect(turd.scaleY, closeTo(1, 0.05));
        expect(turd.scaleX, closeTo(1, 0.05));
      },
    );
  });
}
