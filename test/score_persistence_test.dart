import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/high_score_store.dart';
import 'package:crappy_turd/game/pipe_field.dart';
import 'package:crappy_turd/main.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'a genuine new high score, scored via real gameplay, is persisted to '
    'storage',
    (tester) async {
      // Flying the turd through a randomly-placed pipe gap turns out to be
      // a genuinely fragile thing to script: a single flap's rise
      // (flapVelocity^2 / (2*gravity), ~0.13 of screen height) is actually
      // LARGER than the gap's own vertical tolerance, so no fixed tap
      // cadence reliably threads it -- confirmed by brute-force search
      // across many (seed, cadence) pairs finding no reliable combo.
      //
      // Instead: seed the injected PipeField with one pipe fast-forwarded
      // (via its own public update(dt), the same method the real game loop
      // calls every frame) to just behind the turd's x -- close enough
      // that PipeField.update won't have culled it as offscreen yet, but
      // already past countPipesPassed's "has this pipe's right edge
      // scrolled behind turdX" threshold. On the very first
      // GameStatus.playing tick, that real countPipesPassed call counts it
      // immediately, producing a genuine score of 1 through the exact same
      // production code path an actual pass would use -- no gap-navigation
      // required, and this pipe sits at x=0 (see the sanity check below),
      // far to the left of turdX (0.30) with no way to ever geometrically
      // collide with the turd.
      final pipeField = PipeField(math.Random(1));

      // The real game canvas size GameScreen will report via MediaQuery
      // once pumped below -- needed up front to reproduce the exact (now
      // aspect-ratio-dependent) dynamic spawn position, since Pipe.spawn
      // needs the actual Size to compute it. The test binding's view is
      // already configured before the first pumpWidget call.
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      final spawnX = size.width / size.height + GameConstants.pipeSpawnMargin;
      final prePassedPipe = Pipe.spawn(size, math.Random(1))
        ..update(spawnX / GameConstants.pipeSpeed);
      expect(
        prePassedPipe.x,
        closeTo(0, 0.01),
        reason: 'sanity-check the fast-forward math landed where expected',
      );
      pipeField.pipes.add(prePassedPipe);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: GameScreen(pipeField: pipeField),
        ),
      );

      // Leave the title screen with the first (and only) flap -- no
      // further taps, so gravity carries the turd straight into the
      // ground for a fully deterministic Game Over shortly after.
      await tester.tap(find.byType(GameScreen));
      await tester.pump();

      for (var i = 0; i < 600; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.text('Game Over'), findsOneWidget);
      expect(find.text('Score: 1'), findsOneWidget);
      expect(find.text('New Best: 1!'), findsOneWidget);

      // The real proof: the actual HighScoreStore.save() call inside
      // _GameScreenState fired with the right value and it's sitting in
      // (mocked) storage -- not just reflected in this session's UI.
      // Reading it back via a brand-new HighScoreStore (the same public
      // API a real relaunch would use), not a raw SharedPreferences key,
      // so this stays correct even if the store's internal key ever
      // changes.
      expect(await HighScoreStore().load(), 1);

      // Replace the tree to dispose the game-loop ticker cleanly.
      await tester.pumpWidget(const SizedBox());
    },
  );
}
