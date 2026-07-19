import 'dart:math' as math;

import 'package:crappy_turd/game/cloud_field.dart';
import 'package:crappy_turd/game/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CloudField', () {
    test('a fresh field has cloudCount clouds', () {
      final field = CloudField(math.Random(1));
      expect(field.clouds.length, GameConstants.cloudCount);
    });

    test('update moves every cloud left', () {
      final field = CloudField(math.Random(1));
      final startXs = field.clouds.map((c) => c.x).toList();
      field.update(0.1);
      for (var i = 0; i < field.clouds.length; i++) {
        expect(field.clouds[i].x, lessThan(startXs[i]));
      }
    });

    test(
      'a cloud driven far enough offscreen wraps back around instead of '
      'being removed from the list',
      () {
        final field = CloudField(math.Random(1));
        final countBefore = field.clouds.length;

        // Force the first cloud far past the left edge.
        field.clouds[0].x = -10;
        field.update(0.001);

        // Looping, not despawning: the list length never changes.
        expect(field.clouds.length, countBefore);
        // Wrapped back around to just past the right edge, not left
        // dangling far offscreen.
        expect(field.clouds[0].x, greaterThanOrEqualTo(1.0));
      },
    );

    test(
      'wrapping a cloud gives it a freshly randomised y within the '
      'documented sky band',
      () {
        final field = CloudField(math.Random(7));
        field.clouds[0].x = -10;
        field.update(0.001);
        expect(
          field.clouds[0].y,
          inInclusiveRange(GameConstants.cloudMinY, GameConstants.cloudMaxY),
        );
        expect(
          field.clouds[0].scale,
          inInclusiveRange(
            GameConstants.cloudMinScale,
            GameConstants.cloudMaxScale,
          ),
        );
      },
    );
  });
}
