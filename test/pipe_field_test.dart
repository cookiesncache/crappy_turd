import 'dart:math' as math;
import 'dart:ui';

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/pipe_field.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:flutter_test/flutter_test.dart';

/// A plausible portrait viewport, matching test/collision_test.dart's
/// convention -- used throughout for tests that don't care about a
/// SPECIFIC aspect ratio.
const testSize = Size(400, 800);

void main() {
  group('Pipe', () {
    test('spawn starts at the dynamic right-edge-plus-margin position', () {
      final pipe = Pipe.spawn(testSize, math.Random(1));
      expect(
        pipe.x,
        testSize.width / testSize.height + GameConstants.pipeSpawnMargin,
      );
    });

    test('update moves the pipe left by pipeSpeed * dt', () {
      final pipe = Pipe.spawn(testSize, math.Random(1));
      final startX = pipe.x;
      pipe.update(0.1);
      expect(
        pipe.x,
        closeTo(startX - GameConstants.pipeSpeed * 0.1, 1e-9),
      );
    });

    test('isOffscreen is false just before the threshold', () {
      final pipe = Pipe.spawn(testSize, math.Random(1))
        ..x = -GameConstants.pipeWidth + 0.001;
      expect(pipe.isOffscreen, isFalse);
    });

    test('isOffscreen is true once fully past the left edge', () {
      final pipe = Pipe.spawn(testSize, math.Random(1))
        ..x = -GameConstants.pipeWidth - 0.001;
      expect(pipe.isOffscreen, isTrue);
    });
  });

  group('PipeField', () {
    test('starts with zero pipes', () {
      final field = PipeField(math.Random(1));
      expect(field.pipes, isEmpty);
    });

    test('spawns exactly one pipe once the spawn interval elapses', () {
      const overshoot = 0.001;
      final field = PipeField(math.Random(1))
        // Half the interval first (no spawn yet), then just past the
        // remainder, so the spawn happens on the final call.
        ..update(GameConstants.spawnInterval / 2, testSize)
        ..update(GameConstants.spawnInterval / 2 + overshoot, testSize);
      expect(field.pipes.length, 1);
      final spawnX =
          testSize.width / testSize.height + GameConstants.pipeSpawnMargin;
      // The pipe is immediately advanced by the tiny overshoot past the
      // interval boundary — this is PipeField's staggering behaviour,
      // which keeps same-frame spawns from landing on top of each other.
      expect(
        field.pipes.single.x,
        closeTo(spawnX - GameConstants.pipeSpeed * overshoot, 1e-9),
      );
    });

    test('a long single dt still spawns the correct number of pipes', () {
      final field = PipeField(math.Random(1))
        ..update(GameConstants.spawnInterval * 3.5, testSize);
      expect(field.pipes.length, 3);
    });

    test(
      'pipes spawned in the same long-dt update are staggered, not '
      'overlapping',
      () {
        final field = PipeField(math.Random(1))
          ..update(GameConstants.spawnInterval * 2, testSize);
        expect(field.pipes.length, 2);
        // The earlier-spawned pipe (index 0) has had more of this frame's
        // time applied to it, so it must sit strictly further left than
        // the one spawned right at the end of the same update() call —
        // matching the "oldest (leftmost) first" ordering pipes documents.
        expect(field.pipes[0].x, lessThan(field.pipes[1].x));
      },
    );

    test('pipes move left by pipeSpeed * dt per update', () {
      final field = PipeField(math.Random(1))
        ..update(GameConstants.spawnInterval, testSize);
      final startX = field.pipes.single.x;
      field.update(0.2, testSize);
      expect(
        field.pipes.single.x,
        closeTo(startX - GameConstants.pipeSpeed * 0.2, 1e-9),
      );
    });

    test('offscreen pipes are removed on the next update', () {
      final field = PipeField(math.Random(1));
      field.pipes.add(Pipe.spawn(testSize, math.Random(1))..x = -1);
      expect(field.pipes, isNotEmpty);
      field.update(0.001, testSize);
      expect(field.pipes, isEmpty);
    });

    test('reset clears pipes and the spawn timer', () {
      // Deliberately leave a non-zero remainder (half an interval) before
      // reset(), so this test can actually detect a broken/missing timer
      // reset — update(spawnInterval) alone leaves the timer at exactly
      // 0.0 already, which would make the assertions below pass even if
      // reset() never touched the timer at all.
      final field = PipeField(math.Random(1))
        ..update(GameConstants.spawnInterval * 1.5, testSize)
        ..reset();
      expect(field.pipes, isEmpty);
      // After a real reset, it should take a fresh full interval to spawn
      // again — if the leftover 0.5*interval had survived, this much time
      // would incorrectly be enough to spawn one.
      field.update(GameConstants.spawnInterval - 0.01, testSize);
      expect(field.pipes, isEmpty);
    });
  });

  test(
    'across many spawns, gapCenterY always stays within the documented '
    'ceiling/ground bounds',
    () {
      const lo =
          GameConstants.ceiling +
          GameConstants.gapHeight / 2 +
          GameConstants.gapMargin;
      const hi =
          GameConstants.groundY -
          GameConstants.gapHeight / 2 -
          GameConstants.gapMargin;
      final random = math.Random(42);
      for (var i = 0; i < 200; i++) {
        final pipe = Pipe.spawn(testSize, random);
        expect(pipe.gapCenterY, greaterThanOrEqualTo(lo));
        expect(pipe.gapCenterY, lessThanOrEqualTo(hi));
      }
    },
  );
}
