import 'dart:math' as math;
import 'dart:ui';

import 'package:crappy_turd/game/collision.dart';
import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/pipe_field.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:crappy_turd/models/turd.dart';
import 'package:crappy_turd/render/pipe_painter.dart';
import 'package:crappy_turd/render/turd_painter.dart';
import 'package:flutter_test/flutter_test.dart';

/// A plausible portrait viewport. Collision now depends on real pixel
/// geometry (a [Size]), not just screen-fraction constants, so every test
/// below needs a concrete one to work against.
const testSize = Size(400, 800);

/// The pipe.x (height-fraction) value that places a pipe at the SAME world
/// pixel x position as the turd's own fixed horizontal position
/// ([GameConstants.turdX], a WIDTH-fraction). Since the two are expressed
/// in different units, "pipe directly under the turd" is no longer just
/// `pipe.x = GameConstants.turdX` (that shortcut only ever coincidentally
/// worked back when both were width-fractions) -- it requires converting
/// through a shared pixel space for the [size] in question.
double turdAlignedPipeX(Size size) =>
    GameConstants.turdX * size.width / size.height;

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
      final pipe = Pipe.spawn(testSize, math.Random(1))
        ..x = GameConstants.turdX + 1;
      final turd = Turd()..y = pipe.gapCenterY;
      expect(turdCollidesWithPipe(turd, pipe, testSize), isFalse);
    });

    test(
      'false when flying through the centre of the gap (real shape must '
      'not false-positive on open space)',
      () {
        final pipe = Pipe.spawn(testSize, math.Random(1))
          ..x = turdAlignedPipeX(testSize);
        final turd = Turd()..y = pipe.gapCenterY;
        expect(turdCollidesWithPipe(turd, pipe, testSize), isFalse);
      },
    );

    test(
      'true when horizontally overlapping and vertically in the top bar',
      () {
        final pipe = Pipe.spawn(testSize, math.Random(1))
          ..x = turdAlignedPipeX(testSize);
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
        final pipe = Pipe.spawn(testSize, math.Random(1))
          ..x = turdAlignedPipeX(testSize);
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
        // (= 92), that's a tip half-width of 13.8px versus an overall
        // bounding-box half-width of 44.16px set by the base scoop, at a
        // completely different row.
        final pipe = Pipe.spawn(testSize, math.Random(1));
        final gapTopWorld =
            (pipe.gapCenterY - GameConstants.gapHeight / 2) * testSize.height;

        // Anchor the turd so the pipe's top bar spans local y in
        // [-centerDy, -40]. -40 sits below (more negative than) -34.04,
        // the top edge of the third scoop's own range, so nothing but the
        // tapering tip scoop is ever in play for this whole bar -- true
        // for ANY spawned pipe, since gapTopWorld is always >= 88px (see
        // pipe_field_test.dart's documented bounds), making centerDy
        // always >= 128px, comfortably past the tip scoop's own centre at
        // local y = -36.8.
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
        // 27.8px clears both the tip scoop's own 13.8px half-width AND its
        // collar cap's overhang (pipeWidth*0.15 = 9.6px) with room to
        // spare, while still sitting well inside the turd's overall
        // bounding-box half-width of 44.16px.
        const localXCutoff = 27.8;
        pipe.x = (centerDx + localXCutoff) / testSize.height;

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
        final pipe = Pipe.spawn(testSize, math.Random(1));
        final gapTopWorld =
            (pipe.gapCenterY - GameConstants.gapHeight / 2) * testSize.height;
        final centerDx = GameConstants.turdX * testSize.width;

        // Same top-bar-only construction as above, shifted up and further
        // right so a steep nose-down tilt swings part of the silhouette
        // into the pipe that the un-rotated silhouette clears.
        //
        // These two offsets were re-derived empirically (a throwaway script
        // sweeping candidate values directly against the real
        // turdCollidesWithPipe, deleted after use) rather than hand-derived,
        // because this tuning pass changed turdSize AND pipeWidth at the
        // same time -- turdBodyPath is self-similar in size (so a
        // turdSize-only change could be handled by scaling both offsets by
        // the same ratio, as the previous revision of this test did), but
        // the pipe's own shape is not self-similar with the turd's, so a
        // simultaneous pipeWidth change breaks that shortcut. 15px / 46px
        // sit in the middle of a comfortably wide band (44-49px at this
        // vertical offset) that reproduces the same flat-misses /
        // tilted-hits outcome, not right at its edge.
        final centerDy = gapTopWorld - 15;
        final turdY = centerDy / testSize.height;
        pipe.x = (centerDx + 46) / testSize.height;

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
      final nonCollidingPipe = Pipe.spawn(testSize, math.Random(1))
        ..x = GameConstants.turdX + 1;
      // Directly under the turd, and ceiling sits above every possible gap
      // (see the top-bar test above), so this one always collides.
      final collidingPipe = Pipe.spawn(testSize, math.Random(2))
        ..x = turdAlignedPipeX(testSize);
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

  group(
    'collision outcome is consistent across aspect ratios (regression '
    'for the reported "difficulty varies by screen shape" bug)',
    () {
      // Three meaningfully different viewport shapes, all expressed via
      // the SAME screen-fraction scenarios already used above: the
      // established reference (portrait, width/height = 0.5), a
      // narrower/taller portrait (0.333...), and a wider/shorter one
      // (~0.857). The turd's own silhouette is a single, screen-HEIGHT-only
      // scalar (GameConstants.turdSize) that never varies with aspect
      // ratio, and pipe geometry (GameConstants.pipeWidth) is now defined
      // on that SAME height axis too, so every ratio below must agree.
      const sizes = [
        Size(400, 800),
        Size(300, 900),
        Size(600, 700),
      ];

      test(
        'horizontally overlapping and vertically in the top bar stays '
        'true at every aspect ratio',
        () {
          for (final size in sizes) {
            final pipe = Pipe.spawn(size, math.Random(1))
              ..x = turdAlignedPipeX(size);
            final turd = Turd()..y = GameConstants.ceiling;
            expect(
              turdCollidesWithPipe(turd, pipe, size),
              isTrue,
              reason: 'expected a collision at aspect ratio $size',
            );
          }
        },
      );

      test(
        'flying through the centre of the gap stays false at every '
        'aspect ratio',
        () {
          for (final size in sizes) {
            final pipe = Pipe.spawn(size, math.Random(1))
              ..x = turdAlignedPipeX(size);
            final turd = Turd()..y = pipe.gapCenterY;
            expect(
              turdCollidesWithPipe(turd, pipe, size),
              isFalse,
              reason: 'expected clear flight at aspect ratio $size',
            );
          }
        },
      );

      test(
        'horizontally overlapping and vertically in the bottom bar stays '
        'true at every aspect ratio',
        () {
          for (final size in sizes) {
            final pipe = Pipe.spawn(size, math.Random(1))
              ..x = turdAlignedPipeX(size);
            final turd = Turd()..y = GameConstants.groundY;
            expect(
              turdCollidesWithPipe(turd, pipe, size),
              isTrue,
              reason: 'expected a collision at aspect ratio $size',
            );
          }
        },
      );
    },
  );

  group(
    'turd-to-pipe size ratio is aspect-ratio independent (regression for '
    'the reported difficulty-varies-by-screen-shape bug -- this time on '
    'the PIPE side, since the turd itself is now a fixed single scalar). '
    'Deliberately exercises the REAL rendering/collision geometry '
    '(pipeCollisionPath / PipeField.update), not a hand-reimplemented copy '
    'of the formula, so a regression in the actual production code is '
    'guaranteed to be caught -- this project has a history of '
    'cross-aspect-ratio tests that looked plausible but did not actually '
    'discriminate',
    () {
      // Genuinely varied shapes -- not near-duplicates -- same spirit as
      // the collision-outcome group above.
      const sizes = [
        Size(400, 800),
        Size(300, 900),
        Size(600, 700),
      ];

      test(
        "the ratio of the turd's fixed pixel size to the pipe's REAL "
        'painted/collision pixel width is the same constant at every '
        'aspect ratio',
        () {
          final ratios = sizes.map((size) {
            final turdPixelSize = GameConstants.turdSize * size.height;
            final pipe = Pipe.spawn(size, math.Random(1));
            // The pipe's actual painted/collision silhouette (top bar +
            // bottom bar + both collar caps) -- its bounding-box width is
            // pipeWidth + 2*capOverhang, a fixed multiple of whatever
            // pipeWidth itself resolves to in pixels. Reading this back
            // from the real geometry (rather than recomputing
            // GameConstants.pipeWidth * size.height by hand) means a
            // regression in pipe_painter.dart's actual formula is
            // guaranteed to show up here.
            final pipePixelWidth = pipeCollisionPath(
              pipe,
              size,
            ).getBounds().width;
            return turdPixelSize / pipePixelWidth;
          }).toList();

          for (final ratio in ratios) {
            expect(
              ratio,
              closeTo(ratios.first, 1e-4),
              reason:
                  'the turd-size-to-pipe-width ratio must be a pure '
                  'constant, independent of aspect ratio, since both are '
                  'now multiples of size.height',
            );
          }
        },
      );

      test(
        "the ratio of the turd's fixed pixel size to the REAL pixel "
        'spacing between two consecutively spawned pipes (as actually '
        'positioned by PipeField.update) is the same constant at every '
        'aspect ratio',
        () {
          final ratios = sizes.map((size) {
            final turdPixelSize = GameConstants.turdSize * size.height;
            // Two full spawn intervals, back to back: the first spawns one
            // pipe with zero overshoot: the second advances it by exactly
            // one more interval AND spawns a second fresh pipe, again with
            // zero overshoot -- so the two pipes' x values differ by
            // exactly one spawn-to-spawn step, with no same-frame
            // staggering complicating the arithmetic (see
            // pipe_field_test.dart for that staggering behaviour).
            final field = PipeField(math.Random(1))
              ..update(GameConstants.spawnInterval, size)
              ..update(GameConstants.spawnInterval, size);
            expect(
              field.pipes.length,
              2,
              reason: 'sanity-check exactly two pipes spawned',
            );
            // Read the spacing back from the pipes' REAL rendered/collision
            // left edges (pipeCollisionPath), not by recomputing
            // pipe.x * size.height by hand -- so a regression in
            // pipe_painter.dart's actual left-edge formula is guaranteed to
            // show up here too. The caps' overhang offsets both pipes'
            // bounds().left identically, so it cancels exactly in the
            // subtraction.
            final leftA = pipeCollisionPath(
              field.pipes[0],
              size,
            ).getBounds().left;
            final leftB = pipeCollisionPath(
              field.pipes[1],
              size,
            ).getBounds().left;
            final spacingPx = (leftB - leftA).abs();
            return turdPixelSize / spacingPx;
          }).toList();

          for (final ratio in ratios) {
            expect(
              ratio,
              closeTo(ratios.first, 1e-4),
              reason:
                  'the turd-size-to-pipe-spacing ratio must be a pure '
                  'constant, independent of aspect ratio, since both the '
                  "turd's size and real pipe spacing are now multiples of "
                  'size.height',
            );
          }
        },
      );
    },
  );
}
