import 'dart:math' as math;

import 'package:crappy_turd/game/pipe_field.dart';
import 'package:crappy_turd/main.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// gapCenterY (the only thing this test actually predicts -- see below)
/// never depends on the canvas size, so this placeholder is just to
/// satisfy Pipe.spawn's now-required Size parameter, matching
/// test/collision_test.dart's convention.
const testSize = Size(400, 800);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameScreen.pipeField injection', () {
    testWidgets(
      'a pre-seeded PipeField passed in is the exact instance the running '
      'game populates, and its first gap is fully reproducible from the '
      'same seed',
      (tester) async {
        const seed = 42;

        // A second, independently-constructed PipeField/Random with the
        // SAME seed as the one handed to GameScreen below -- since
        // math.Random(seed) is deterministic, this predicts exactly what
        // the running game's first spawned pipe's gap will be, without
        // needing to guess or hardcode a magic float.
        final expectedGapCenterY = Pipe.spawn(
          testSize,
          math.Random(seed),
        ).gapCenterY;

        final injected = PipeField(math.Random(seed));
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: GameScreen(pipeField: injected),
          ),
        );

        expect(find.text('Tap to start'), findsOneWidget);

        // Leave the title screen with the first flap.
        await tester.tap(find.byType(GameScreen));
        await tester.pump();

        // GameConstants.spawnInterval is 2.1s, but an unbroken freefall
        // after a single flap hits the ground in well under that -- so
        // stay aloft with periodic re-flaps (mirroring real play) for long
        // enough that the spawn timer actually crosses the interval before
        // a premature Game Over ever stops _pipeField.update() from being
        // called at all (it's only ticked in GameStatus.playing).
        for (var i = 0; i < 150; i++) {
          if (i % 20 == 0) {
            await tester.tap(find.byType(GameScreen));
          }
          await tester.pump(const Duration(milliseconds: 16));
        }

        expect(
          injected.pipes,
          isNotEmpty,
          reason:
              'the running GameScreen should have spawned into the exact '
              'PipeField instance passed in, not a separate internal one',
        );
        expect(injected.pipes.first.gapCenterY, expectedGapCenterY);

        // Replace the tree to dispose the game-loop ticker cleanly.
        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}
