import 'package:crappy_turd/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the game screen', (tester) async {
    await tester.pumpWidget(const CrappyTurdApp());
    expect(find.byType(GameScreen), findsOneWidget);

    // Replace the tree to dispose the game-loop ticker cleanly.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'a real collision shows Game Over, and tapping restarts play',
    (tester) async {
      await tester.pumpWidget(const CrappyTurdApp());

      // _GameScreenState/_status/_turd are library-private, so there's no
      // direct handle on the state machine from here. The game-over
      // overlay's AnimatedOpacity.opacity is the one state signal exposed
      // through the public widget tree, so it doubles as this test's proxy
      // for "is GameStatus.gameOver active right now".
      AnimatedOpacity gameOverOpacity() => tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('Game Over'),
          matching: find.byType(AnimatedOpacity),
        ),
      );

      expect(gameOverOpacity().opacity, 0);

      // Leave the title screen and start falling.
      await tester.tap(find.byType(GameScreen));
      await tester.pump();

      // Drive the real, unmocked game loop frame-by-frame (mirrors the
      // ~60fps loop) until gravity settles the turd on the ground and a
      // genuine collision fires. This exercises the exact code path a
      // real player hits, not a simulated/forced state change.
      for (var i = 0; i < 600; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(gameOverOpacity().opacity, 1);

      // Tap to restart: should immediately hide the game-over overlay
      // again (a stuck/never-clearing overlay would fail this).
      await tester.tap(find.byType(GameScreen));
      await tester.pump();

      expect(gameOverOpacity().opacity, 0);

      // Replace the tree to dispose the game-loop ticker cleanly.
      await tester.pumpWidget(const SizedBox());
    },
  );
}
