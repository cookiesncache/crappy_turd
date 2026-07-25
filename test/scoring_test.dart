import 'dart:math' as math;
import 'dart:ui';

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/scoring.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:flutter_test/flutter_test.dart';

/// A plausible portrait viewport, matching test/collision_test.dart's
/// convention.
const testSize = Size(400, 800);

/// The pipe.x (height-fraction) threshold countPipesPassed actually compares
/// against for [testSize]: GameConstants.turdX is a WIDTH-fraction, but
/// pipe.x/pipeWidth are height-fractions (see lib/models/pipe.dart), so
/// countPipesPassed converts turdX into this same unit before comparing --
/// `turdX * size.width / size.height`, NOT a bare `GameConstants.turdX`.
/// Every pipe.x below is built relative to THIS value, not the raw
/// (width-fraction) constant, so these tests actually exercise the real
/// conversion rather than accidentally passing under two different unit
/// systems that happen to agree only at a 1:1 aspect ratio (testSize here
/// is deliberately not square, so that coincidence can't mask a bug).
final double turdXHeightFraction =
    GameConstants.turdX * testSize.width / testSize.height; // 0.15

void main() {
  group('countPipesPassed', () {
    test('an empty list scores 0', () {
      expect(countPipesPassed([], testSize), 0);
    });

    test(
      'a pipe already past the converted turd threshold and not yet '
      'marked passed is counted once and its passed flag flips to true',
      () {
        final pipe = Pipe.spawn(testSize, math.Random(1))
          ..x = turdXHeightFraction - GameConstants.pipeWidth - 0.01;
        expect(pipe.passed, isFalse);

        expect(countPipesPassed([pipe], testSize), 1);
        expect(pipe.passed, isTrue);
      },
    );

    test(
      'calling it again on the same pipe after a real first call does not '
      'double-count',
      () {
        final pipe = Pipe.spawn(testSize, math.Random(1))
          ..x = turdXHeightFraction - GameConstants.pipeWidth - 0.01;

        // A genuine first call: this is what actually sets passed=true.
        expect(countPipesPassed([pipe], testSize), 1);
        expect(pipe.passed, isTrue);

        // A genuine second call on the same (now-passed) pipe -- proves
        // idempotency across real consecutive invocations, not just that
        // the function respects a flag forged by the test itself.
        expect(countPipesPassed([pipe], testSize), 0);
        expect(pipe.passed, isTrue);
      },
    );

    test(
      'a pipe not yet past the converted turd threshold scores 0 and its '
      'passed flag stays false',
      () {
        final pipe = Pipe.spawn(testSize, math.Random(1))
          ..x = turdXHeightFraction - GameConstants.pipeWidth + 0.01;

        expect(countPipesPassed([pipe], testSize), 0);
        expect(pipe.passed, isFalse);
      },
    );

    test(
      'a mixed list of several pipes returns the correct aggregate count '
      "and leaves each pipe's passed flag correct individually",
      () {
        // Already past, not yet marked -- should count and flip.
        final newlyPassed1 = Pipe.spawn(testSize, math.Random(1))
          ..x = turdXHeightFraction - GameConstants.pipeWidth - 0.05;
        // Already past, not yet marked -- should count and flip.
        final newlyPassed2 = Pipe.spawn(testSize, math.Random(2))
          ..x = turdXHeightFraction - GameConstants.pipeWidth - 0.5;
        // Already past AND already marked -- should not be recounted.
        final alreadyPassed = Pipe.spawn(testSize, math.Random(3))
          ..x = turdXHeightFraction - GameConstants.pipeWidth - 0.2
          ..passed = true;
        // Not yet past -- should not be counted.
        final notPassed = Pipe.spawn(testSize, math.Random(4))
          ..x = turdXHeightFraction + 0.2;

        final pipes = [newlyPassed1, alreadyPassed, notPassed, newlyPassed2];

        expect(countPipesPassed(pipes, testSize), 2);
        expect(newlyPassed1.passed, isTrue);
        expect(newlyPassed2.passed, isTrue);
        expect(alreadyPassed.passed, isTrue);
        expect(notPassed.passed, isFalse);

        // A second call on the same list should now score 0 -- every
        // eligible pipe has already been marked.
        expect(countPipesPassed(pipes, testSize), 0);
      },
    );

    test(
      'the turdX-to-pipe-unit conversion is actually load-bearing: the same '
      'pipe.x reads as passed or not depending on aspect ratio',
      () {
        // At testSize (0.5 aspect ratio), turdXHeightFraction is 0.15. Pick
        // an x strictly between 0.15 and the raw (unconverted)
        // GameConstants.turdX (0.30) -- if countPipesPassed ever regressed
        // back to comparing against bare turdX instead of the converted
        // value, this exact pipe would flip from "not passed" to "passed"
        // at this SAME aspect ratio, without even needing a second size.
        const x = 0.20;
        expect(x, greaterThan(turdXHeightFraction));
        expect(x, lessThan(GameConstants.turdX));

        final pipe = Pipe.spawn(testSize, math.Random(1))
          ..x = x - GameConstants.pipeWidth;
        expect(
          countPipesPassed([pipe], testSize),
          0,
          reason:
              'this pipe has not reached the correctly-converted turd '
              'threshold (0.15) yet, even though it has already passed '
              'the raw, unconverted GameConstants.turdX (0.30) -- scoring '
              'this now would mean the units bug crept back in',
        );
      },
    );
  });
}
