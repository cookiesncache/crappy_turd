import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/star_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StarField', () {
    test('a fresh field always has exactly starCount stars', () {
      final field = StarField(math.Random(1));
      expect(field.stars.length, GameConstants.starCount);
    });

    test('every star falls within the documented tunable ranges', () {
      final field = StarField(math.Random(3));
      for (final star in field.stars) {
        expect(star.x, inInclusiveRange(0.0, 1.0));
        expect(
          star.y,
          inInclusiveRange(GameConstants.starMinY, GameConstants.starMaxY),
        );
        expect(
          star.size,
          inInclusiveRange(
            GameConstants.starMinSize,
            GameConstants.starMaxSize,
          ),
        );
        expect(star.twinklePhase, inInclusiveRange(0.0, 2 * math.pi));
        expect(
          star.twinkleSpeed,
          inInclusiveRange(
            GameConstants.starTwinkleSpeedMin,
            GameConstants.starTwinkleSpeedMax,
          ),
        );
      }
    });

    test('the same seed produces the exact same stars (determinism)', () {
      final a = StarField(math.Random(42));
      final b = StarField(math.Random(42));
      expect(a.stars.length, b.stars.length);
      for (var i = 0; i < a.stars.length; i++) {
        expect(a.stars[i].x, b.stars[i].x);
        expect(a.stars[i].y, b.stars[i].y);
        expect(a.stars[i].size, b.stars[i].size);
        expect(a.stars[i].twinklePhase, b.stars[i].twinklePhase);
        expect(a.stars[i].twinkleSpeed, b.stars[i].twinkleSpeed);
      }
    });

    test('a different seed produces a different field', () {
      final a = StarField(math.Random(1));
      final b = StarField(math.Random(2));
      final anyDifferent = List.generate(
        a.stars.length,
        (i) => a.stars[i].x != b.stars[i].x || a.stars[i].y != b.stars[i].y,
      ).any((different) => different);
      expect(anyDifferent, isTrue);
    });
  });
}
