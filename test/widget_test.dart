import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // _GameScreenState.initState() now fires off a shared_preferences read
  // (see HighScoreStore) on every pumpWidget(CrappyTurdApp()) below.
  // Without a mocked platform channel, that call throws
  // MissingPluginException under flutter_test -- setMockInitialValues
  // installs the in-memory mock backend setup requires before the first
  // real getInstance() call.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  testWidgets(
    'tapping the mute button toggles it without also registering as a '
    'flap/restart tap on the game underneath',
    (tester) async {
      await tester.pumpWidget(const CrappyTurdApp());

      // Starts unmuted, on the title screen.
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.volume_off), findsNothing);
      expect(find.text('Tap to start'), findsOneWidget);

      // Tap the mute button itself -- NOT the outer GestureDetector's own
      // area -- via a real hit test, exactly as a player's tap would be
      // dispatched.
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      // The button's own tap registered: the icon flipped.
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsNothing);

      // Crucially, the tap must NOT also have bubbled through to the
      // underlying GestureDetector's onTapDown as a flap/restart tap --
      // if it had, GameStatus would have left `title` for `playing`, and
      // the title overlay's AnimatedSwitcher would fade it out for good.
      // Advance past the full cross-fade duration (as the game-over
      // restart test above does) so a "did leave title" bug can't hide
      // behind a still-mid-transition outgoing child.
      await tester.pump(
        GameConstants.overlayFadeDuration + const Duration(milliseconds: 50),
      );
      expect(find.text('Tap to start'), findsOneWidget);

      // Tapping again toggles it back, confirming the button keeps
      // working (not just a one-shot fluke) and that the surrounding game
      // still hasn't budged from the title screen after two taps.
      await tester.tap(find.byIcon(Icons.volume_off));
      await tester.pump();
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.text('Tap to start'), findsOneWidget);

      // Replace the tree to dispose the game-loop ticker cleanly.
      await tester.pumpWidget(const SizedBox());
    },
  );
}
