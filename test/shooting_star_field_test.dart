import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/shooting_star_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShootingStarField', () {
    test(
      'never spawns anything while dayNightT stays below the visibility '
      'threshold, even across many ticks',
      () {
        final field = ShootingStarField(math.Random(1));
        const belowThreshold =
            GameConstants.shootingStarVisibilityThreshold - 0.01;
        const dt = 0.1;
        // Comfortably more than enough elapsed time to have crossed
        // several max-interval's worth of spawn delays were the threshold
        // not holding it back -- so this can't pass merely because too
        // little time had elapsed.
        final ticks = ((GameConstants.shootingStarIntervalMax * 5) / dt).ceil();
        for (var i = 0; i < ticks; i++) {
          field.update(dt, belowThreshold);
        }
        expect(field.shootingStars, isEmpty);
      },
    );

    test(
      'eventually spawns at least one once dayNightT is at/above the '
      'visibility threshold',
      () {
        final field = ShootingStarField(math.Random(1));
        const atThreshold = GameConstants.shootingStarVisibilityThreshold;
        const dt = 0.1;
        // A couple of max-interval's worth of ticks is guaranteed to cross
        // at least one randomised (but capped by shootingStarIntervalMax)
        // spawn delay.
        final ticks = ((GameConstants.shootingStarIntervalMax * 2) / dt).ceil();
        // shootingStarLife (well under a second) is far shorter than the
        // multi-second spawn interval, so a star that spawns partway
        // through this drive will very likely have already aged out and
        // been culled again by the time the LAST tick runs -- checking
        // `isNotEmpty` only once, after the whole drive, could find the
        // field legitimately empty even though a spawn genuinely happened
        // somewhere in between. Observe every tick instead, so a spawn is
        // caught the moment it appears rather than missed because it
        // already came and went by the time we look.
        var everSpawned = false;
        for (var i = 0; i < ticks; i++) {
          field.update(dt, atThreshold);
          if (field.shootingStars.isNotEmpty) {
            everSpawned = true;
          }
        }
        expect(everSpawned, isTrue);
      },
    );

    test('a spawned shooting star ages and is culled once past maxLife', () {
      final field = ShootingStarField(math.Random(1));
      const above = GameConstants.shootingStarVisibilityThreshold + 0.1;
      // Force an immediate spawn regardless of the randomised initial
      // delay (which can be at most shootingStarIntervalMax) by driving
      // past the longest possible interval in one call.
      field.update(GameConstants.shootingStarIntervalMax + 0.01, above);
      expect(field.shootingStars, isNotEmpty);

      field.update(GameConstants.shootingStarLife + 0.01, above);
      expect(field.shootingStars, isEmpty);
    });

    test(
      'an in-flight shooting star is NOT force-removed just because '
      'dayNightT later drops back below the threshold',
      () {
        final field = ShootingStarField(math.Random(1));
        const above = GameConstants.shootingStarVisibilityThreshold + 0.1;
        const below = GameConstants.shootingStarVisibilityThreshold - 0.1;

        // Force a spawn while above the threshold.
        field.update(GameConstants.shootingStarIntervalMax + 0.01, above);
        expect(field.shootingStars, isNotEmpty);
        final survivor = field.shootingStars.first;
        final ageAfterSpawn = survivor.age;

        // Drop below the threshold -- well short of maxLife -- and
        // confirm it's still present (and still ageing normally, not
        // frozen in place) rather than being yanked out just because new
        // spawns are currently gated off.
        const dt = 0.05;
        field.update(dt, below);
        expect(field.shootingStars, contains(survivor));
        expect(survivor.age, closeTo(ageAfterSpawn + dt, 1e-9));

        // It still gets culled on its own schedule once it genuinely
        // outlives maxLife, even while dayNightT remains below threshold
        // the whole time.
        field.update(GameConstants.shootingStarLife, below);
        expect(field.shootingStars, isEmpty);
      },
    );
  });
}
