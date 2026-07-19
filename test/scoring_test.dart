import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/scoring.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('countPipesPassed', () {
    test('an empty list scores 0', () {
      expect(countPipesPassed([]), 0);
    });

    test(
      'a pipe already past turdX and not yet marked passed is counted once '
      'and its passed flag flips to true',
      () {
        final pipe = Pipe.spawn(math.Random(1))
          ..x = GameConstants.turdX - GameConstants.pipeWidth - 0.01;
        expect(pipe.passed, isFalse);

        expect(countPipesPassed([pipe]), 1);
        expect(pipe.passed, isTrue);
      },
    );

    test(
      'calling it again on the same pipe after a real first call does not '
      'double-count',
      () {
        final pipe = Pipe.spawn(math.Random(1))
          ..x = GameConstants.turdX - GameConstants.pipeWidth - 0.01;

        // A genuine first call: this is what actually sets passed=true.
        expect(countPipesPassed([pipe]), 1);
        expect(pipe.passed, isTrue);

        // A genuine second call on the same (now-passed) pipe -- proves
        // idempotency across real consecutive invocations, not just that
        // the function respects a flag forged by the test itself.
        expect(countPipesPassed([pipe]), 0);
        expect(pipe.passed, isTrue);
      },
    );

    test(
      'a pipe not yet past turdX scores 0 and its passed flag stays false',
      () {
        final pipe = Pipe.spawn(math.Random(1))
          ..x = GameConstants.turdX - GameConstants.pipeWidth + 0.01;

        expect(countPipesPassed([pipe]), 0);
        expect(pipe.passed, isFalse);
      },
    );

    test(
      'a mixed list of several pipes returns the correct aggregate count '
      "and leaves each pipe's passed flag correct individually",
      () {
        // Already past, not yet marked -- should count and flip.
        final newlyPassed1 = Pipe.spawn(math.Random(1))
          ..x = GameConstants.turdX - GameConstants.pipeWidth - 0.05;
        // Already past, not yet marked -- should count and flip.
        final newlyPassed2 = Pipe.spawn(math.Random(2))
          ..x = GameConstants.turdX - GameConstants.pipeWidth - 0.5;
        // Already past AND already marked -- should not be recounted.
        final alreadyPassed = Pipe.spawn(math.Random(3))
          ..x = GameConstants.turdX - GameConstants.pipeWidth - 0.2
          ..passed = true;
        // Not yet past -- should not be counted.
        final notPassed = Pipe.spawn(math.Random(4))
          ..x = GameConstants.turdX + 0.2;

        final pipes = [newlyPassed1, alreadyPassed, notPassed, newlyPassed2];

        expect(countPipesPassed(pipes), 2);
        expect(newlyPassed1.passed, isTrue);
        expect(newlyPassed2.passed, isTrue);
        expect(alreadyPassed.passed, isTrue);
        expect(notPassed.passed, isFalse);

        // A second call on the same list should now score 0 -- every
        // eligible pipe has already been marked.
        expect(countPipesPassed(pipes), 0);
      },
    );
  });
}
