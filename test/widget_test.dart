import 'package:crappy_turd/game/constants.dart';
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
      // direct handle on the state machine from here. Since the game-over
      // branch of the AnimatedSwitcher is a real _GameOverPanel (with a
      // "Game Over" Text in it) while the playing branch is just a
      // SizedBox.shrink, the presence/absence of that text in the PUBLIC
      // widget tree is a robust proxy for "is GameStatus.gameOver active
      // right now" -- simpler than the old approach of reading an
      // AnimatedOpacity's current opacity value, and it doesn't rely on
      // any particular animation widget being used under the hood.
      expect(find.text('Game Over'), findsNothing);

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

      expect(find.text('Game Over'), findsOneWidget);

      // The game-over panel shows both the run's score and the session
      // best. The exact number reached before the turd hits the ground is
      // timing-dependent on pipe-spawn/travel math, so assert only that
      // the labelled lines exist (loose, RegExp-based substring matches)
      // rather than hardcoding a specific score -- the precise counting
      // logic itself is rigorously covered by test/scoring_test.dart.
      expect(find.textContaining(RegExp(r'^Score: \d+$')), findsOneWidget);
      expect(find.textContaining(RegExp(r'Best: \d+')), findsOneWidget);

      // Tap to restart. AnimatedSwitcher keeps the OUTGOING child mounted
      // (mid cross-fade) for the duration of the transition, so a single
      // zero-time pump() isn't enough to observe it gone -- advance past
      // overlayFadeDuration first, then confirm the game-over panel has
      // fully cleared (a stuck/never-clearing overlay would fail this).
      await tester.tap(find.byType(GameScreen));
      await tester.pump();
      await tester.pump(
        GameConstants.overlayFadeDuration + const Duration(milliseconds: 50),
      );

      expect(find.text('Game Over'), findsNothing);

      // Replace the tree to dispose the game-loop ticker cleanly.
      await tester.pumpWidget(const SizedBox());
    },
  );
}
