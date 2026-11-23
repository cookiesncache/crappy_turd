import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:crappy_turd/game/bunny_field.dart';
import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/bunny.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _size = Size(400, 800);
const double _dt = 1 / 60;

void main() {
  group('Bunny', () {
    Bunny bunny({int facing = 1}) => Bunny(
      x: 0.2,
      facing: facing,
      scale: 1,
      coat: 0,
      restTime: 0.5,
    );

    test('arcs up mid-hop, then sits on the grass between hops', () {
      final b = bunny()..update(GameConstants.bunnyHopTime / 2, 0);
      expect(b.airborne, isTrue);
      expect(b.lift, closeTo(GameConstants.bunnyHopHeight, 1e-9));

      b.update(GameConstants.bunnyHopTime / 2 + 0.1, 0);
      expect(b.airborne, isFalse);
      expect(b.lift, 0);
    });

    test('hops one hop-distance in the direction it faces', () {
      final right = bunny();
      final left = bunny(facing: -1);
      for (var t = 0.0; t < GameConstants.bunnyHopTime; t += 0.001) {
        right.update(0.001, 0);
        left.update(0.001, 0);
      }
      expect(right.x - 0.2, closeTo(GameConstants.bunnyHopDistance, 0.002));
      expect(0.2 - left.x, closeTo(GameConstants.bunnyHopDistance, 0.002));
    });

    test('the scrolling ground carries it left even while sitting', () {
      final b = bunny()..update(GameConstants.bunnyHopTime + 0.01, 0);
      final before = b.x;
      b.update(0.1, GameConstants.pipeSpeed);
      expect(b.x, closeTo(before - GameConstants.pipeSpeed * 0.1, 1e-9));
    });
  });

  group('BunnyField', () {
    test('starts empty and spawns a bunny within the longest interval', () {
      final field = BunnyField(math.Random(1));
      expect(field.bunnies, isEmpty);
      for (var t = 0.0; t < GameConstants.bunnyIntervalMax; t += _dt) {
        field.update(_dt, _size, groundSpeed: 0);
      }
      expect(field.bunnies, isNotEmpty);
    });

    test('never has more than bunnyMaxCount at once', () {
      for (final speed in [0.0, GameConstants.pipeSpeed]) {
        final field = BunnyField(math.Random(2));
        for (var t = 0.0; t < 300; t += _dt) {
          field.update(_dt, _size, groundSpeed: speed);
          expect(
            field.bunnies.length,
            lessThanOrEqualTo(GameConstants.bunnyMaxCount),
          );
        }
      }
    });

    test(
      'while the ground scrolls, bunnies enter from the right and are '
      'culled once they leave on the left',
      () {
        final field = BunnyField(math.Random(3));
        final right = _size.width / _size.height;
        var spawned = 0;
        var previous = <Bunny>{};
        for (var t = 0.0; t < 120; t += _dt) {
          field.update(_dt, _size, groundSpeed: GameConstants.pipeSpeed);
          for (final b in field.bunnies) {
            if (!previous.contains(b)) {
              spawned++;
              expect(b.x, greaterThan(right));
            }
          }
          previous = field.bunnies.toSet();
        }
        expect(spawned, greaterThan(5));
        // Every bunny eventually leaves: 30 s on, none of the ones on
        // screen now are still there.
        final old = field.bunnies.toSet();
        for (var t = 0.0; t < 30; t += _dt) {
          field.update(_dt, _size, groundSpeed: GameConstants.pipeSpeed);
        }
        expect(field.bunnies.toSet().intersection(old), isEmpty);
      },
    );

    test('while the ground is still, a bunny always hops inward', () {
      final field = BunnyField(math.Random(4));
      final right = _size.width / _size.height;
      var previous = <Bunny>{};
      for (var t = 0.0; t < 200; t += _dt) {
        field.update(_dt, _size, groundSpeed: 0);
        for (final b in field.bunnies) {
          if (!previous.contains(b)) {
            expect(b.facing, b.x > right / 2 ? -1 : 1);
          }
        }
        previous = field.bunnies.toSet();
      }
    });
  });
}
