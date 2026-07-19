import 'dart:math' as math;
import 'dart:ui';

import 'package:crappy_turd/game/collision.dart';
import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:crappy_turd/models/turd.dart';
import 'package:crappy_turd/render/pipe_painter.dart';
import 'package:crappy_turd/render/turd_painter.dart';
import 'package:flutter_test/flutter_test.dart';

/// A plausible portrait viewport. Collision now depends on real pixel
/// geometry (a [Size]), not just screen-fraction constants, so every test
/// below needs a concrete one to work against.
const testSize = Size(400, 800);

void main() {
  group('turdHitsGround', () {
    // Unchanged: ground contact is a flat plane, so the fraction-based
    // formula stays exactly as it was before this milestone.
    test('false with the turd well above the ground', () {
      final turd = Turd()..y = GameConstants.startY;
      expect(turdHitsGround(turd), isFalse);
    });

    test('true at the exact clamp threshold', () {
      final turd = Turd()
        ..y = GameConstants.groundY - GameConstants.turdSize / 2;
      expect(turdHitsGround(turd), isTrue);
    });

    test('true just past the exact clamp threshold', () {
      final turd = Turd()
        ..y = GameConstants.groundY - GameConstants.turdSize / 2 + 0.001;
      expect(turdHitsGround(turd), isTrue);
    });

    test(
      'true once a real Turd has fallen and settled on the floor via '
      'update()',
      () {
        // Mirrors turd_test.dart's "never falls through the ground" test:
        // drive the real simulation (not just the raw formula) so this
        // would catch a threshold mismatch against Turd's own floor clamp.
        final turd = Turd();
        for (var i = 0; i < 600; i++) {
          turd.update(1 / 60);
        }
        expect(turd.velocity, 0);
        expect(turdHitsGround(turd), isTrue);
      },
    );
  });

  group('turdCollidesWithPipe', () {
    test('false when horizontally far from the pipe', () {
      final pipe = Pipe.spawn(math.Random(1))..x = GameConstants.turdX + 1;
      final turd = Turd()..y = pipe.gapCenterY;
      expect(turdCollidesWithPipe(turd, pipe, testSize), isFalse);
    });

    test(
      'false when flying through the centre of the gap (real shape must '
      'not false-positive on open space)',
      () {
        final pipe = Pipe.spawn(math.Random(1))..x = GameConstants.turdX;
        final turd = Turd()..y = pipe.gapCenterY;
        expect(turdCollidesWithPipe(turd, pipe, testSize), isFalse);
      },
    );

    test(
      'true when horizontally overlapping and vertically in the top bar',
      () {
        final pipe = Pipe.spawn(math.Random(1))..x = GameConstants.turdX;
        // ceiling is always above the lowest possible gapTop (see
        // pipe_field_test.dart's documented gapCenterY bounds), so the
        // turd's real silhouette is guaranteed to reach into the top bar
        // for any spawned pipe.
        final turd = Turd()..y = GameConstants.ceiling;
        expect(turdCollidesWithPipe(turd, pipe, testSize), isTrue);
      },
    );

    test(
      'true when horizontally overlapping and vertically in the bottom bar',
      () {
        final pipe = Pipe.spawn(math.Random(1))..x = GameConstants.turdX;
        // groundY is always below the highest possible gapBottom (see
        // pipe_field_test.dart), so the turd's real silhouette is
        // guaranteed to reach into the bottom bar for any spawned pipe.
        final turd = Turd()..y = GameConstants.groundY;
        expect(turdCollidesWithPipe(turd, pipe, testSize), isTrue);
      },
    );

    test(
      "the milestone's actual point: the real silhouette clears a pipe "
      'that a naive full-bounding-box check would flag, because the '
      "turd's tapering top scoop is far narrower than the bounding box "
      'set by its much wider base scoop',
      () {
        // turdBodyPath's four stacked scoops (see turd_painter.dart):
        // the topmost ("tip") scoop is centred at local y = -0.40*s with
        // half-width 0.15*s, while the bottommost ("base") scoop is
        // centred at local y = +0.30*s with half-width 0.48*s -- roughly
        // 3x wider. At size = GameConstants.turdSize * testSize.height
        // (= 104), that's a tip half-width of 15.6px versus an overall
        // bounding-box half-width of 49.92px set by the base scoop, at a
        // completely different row.
        final pipe = Pipe.spawn(math.Random(1));
        final gapTopWorld =
            (pipe.gapCenterY - GameConstants.gapHeight / 2) * testSize.height;

        // Anchor the turd so the pipe's top bar spans local y in
        // [-centerDy, -40]. -40 sits below (more negative than) -38.48,
        // the top edge of the third scoop's own range, so nothing but the
        // tapering tip scoop is ever in play for this whole bar -- true
        // for ANY spawned pipe, since gapTopWorld is always >= 88px (see
        // pipe_field_test.dart's documented bounds), making centerDy
        // always >= 128px, comfortably past the tip scoop's own centre at
        // local y = -41.6.
        final centerDy = gapTopWorld + 40;
        final turd = Turd()..y = centerDy / testSize.height;
        expect(
          turd.tilt,
          0,
          reason:
              'keep this case unrotated so only the silhouette shape '
              'itself is under test',
        );

        final centerDx = GameConstants.turdX * testSize.width;
        // 28.4px clears both the tip scoop's own 15.6px half-width AND its
        // collar cap's overhang (pipeWidth*0.15 = 8.4px) with room to
        // spare, while still sitting well inside the turd's overall
        // bounding-box half-width of 49.92px.
        const localXCutoff = 28.4;
        pipe.x = (centerDx + localXCutoff) / testSize.width;

        final turdWorldPath = turdBodyPath(
          GameConstants.turdSize * testSize.height,
        ).shift(Offset(centerDx, centerDy));
        final pipeWorldPath = pipeCollisionPath(pipe, testSize);

        // Precondition: a naive check using only the two shapes' overall
        // bounding boxes says they overlap...
        expect(
          turdWorldPath.getBounds().overlaps(pipeWorldPath.getBounds()),
          isTrue,
          reason:
              'sanity-check the naive bounding-box test would actually '
              'flag this position',
        );
        // ...but the real, precise silhouettes do not actually touch.
        expect(turdCollidesWithPipe(turd, pipe, testSize), isFalse);
      },
    );

    test(
      'a significant tilt changes the collision outcome relative to an '
      'un-rotated check at the same position',
      () {
        final pipe = Pipe.spawn(math.Random(1));
        final gapTopWorld =
            (pipe.gapCenterY - GameConstants.gapHeight / 2) * testSize.height;
        final centerDx = GameConstants.turdX * testSize.width;

        // Same top-bar-only construction as above, shifted up and further
        // right so a steep nose-down tilt swings part of the silhouette
        // into the pipe that the un-rotated silhouette clears.
        final centerDy = gapTopWorld + 40 - 60;
        final turdY = centerDy / testSize.height;
        pipe.x = (centerDx + 48) / testSize.width;

        final flat = Turd()
          ..y = turdY
          ..velocity = 0;

        // From M6, `tilt` eases toward its velocity-driven target rather
        // than snapping to it instantly (see Turd._easeTiltAndSquash), so
        // a real tilt of ~1.1 (== (3 * 0.55).clamp(-0.5, 1.1)) has to be
        // built up over several update() calls, not read straight off a
        // freshly-set `velocity`. Each call re-pins `y` back to a safe
        // mid-air value first so the ground clamp never zeroes velocity
        // out mid-loop -- which would otherwise pull the eased tilt back
        // toward a target of 0 instead of the intended 1.1.
        final tilted = Turd();
        for (var i = 0; i < 40; i++) {
          tilted
            ..y = GameConstants.startY
            ..velocity = 3
            ..update(1 / 60);
        }
        tilted.y = turdY;

        expect(flat.tilt, 0);
        expect(tilted.tilt, closeTo(1.1, 1e-2));

        expect(
          turdCollidesWithPipe(flat, pipe, testSize),
          isFalse,
          reason: 'un-rotated, the silhouette clears the pipe',
        );
        expect(
          turdCollidesWithPipe(tilted, pipe, testSize),
          isTrue,
          reason:
              'tilted, the rotated silhouette swings into the pipe -- '
              'proving rotation is genuinely accounted for',
        );
      },
    );
  });

  group('checkCollision', () {
    test('false with an empty pipe list and the turd mid-air', () {
      final turd = Turd()..y = GameConstants.startY;
      expect(checkCollision(turd, [], testSize), isFalse);
    });

    test('true if any one pipe in a multi-pipe list collides', () {
      // Far away horizontally, so it can never collide no matter where the
      // turd is vertically.
      final nonCollidingPipe = Pipe.spawn(math.Random(1))
        ..x = GameConstants.turdX + 1;
      // Directly under the turd, and ceiling sits above every possible gap
      // (see the top-bar test above), so this one always collides.
      final collidingPipe = Pipe.spawn(math.Random(2))..x = GameConstants.turdX;
      final turd = Turd()..y = GameConstants.ceiling;
      expect(
        checkCollision(turd, [nonCollidingPipe, collidingPipe], testSize),
        isTrue,
      );
    });

    test('true on ground contact even with zero pipes', () {
      final turd = Turd()
        ..y = GameConstants.groundY - GameConstants.turdSize / 2;
      expect(checkCollision(turd, [], testSize), isTrue);
    });
  });
}
