// M10 polish: verifies the haptic feedback wired into _GameScreenState in
// lib/main.dart actually invokes the real platform channel Flutter's
// HapticFeedback class uses -- not just that "some call happens", but the
// exact method name/argument shape, read straight from the installed SDK's
// package:flutter/src/services/haptic_feedback.dart:
//   SystemChannels.platform.invokeMethod<void>(
//     'HapticFeedback.vibrate',
//     'HapticFeedbackType.heavyImpact',
//   );
// This is mocked via TestDefaultBinaryMessengerBinding rather than actually
// felt -- HapticFeedback is a no-op on this dev environment's web/desktop
// targets regardless, so the platform-channel call is the only thing
// verifiable here.
//
// Flapping deliberately has NO haptic -- an earlier light-impact-on-every-
// flap tick was removed after real playtesting feedback that it read as
// distracting and frustrating given how often a flap fires. Only the
// fatal collision gets a haptic now.
import 'package:crappy_turd/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final hapticCalls = <MethodCall>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    hapticCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('tapping to flap fires no haptic at all', (tester) async {
    await tester.pumpWidget(const CrappyTurdApp());

    // Leave the title screen: this is a flap tap. A later, in-flight flap
    // (still on the title/playing screen) is exercised too, since a flap
    // is a flap regardless of when it fires.
    await tester.tap(find.byType(GameScreen));
    await tester.pump();
    await tester.tap(find.byType(GameScreen));
    await tester.pump();

    expect(hapticCalls, isEmpty);

    // Replace the tree to dispose the game-loop ticker cleanly.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'a real collision fires a heavy-impact haptic at the moment of death',
    (tester) async {
      await tester.pumpWidget(const CrappyTurdApp());

      // Leave the title screen and start falling. No haptic fires on this
      // flap tap itself (see the group-level doc comment) -- nothing to
      // clear beforehand.
      await tester.tap(find.byType(GameScreen));
      await tester.pump();

      // Drive the real, unmocked game loop frame-by-frame (mirrors
      // test/widget_test.dart's "a real collision shows Game Over" test)
      // until gravity settles the turd on the ground and a genuine
      // collision fires.
      for (var i = 0; i < 600; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.text('Game Over'), findsOneWidget);

      // Exactly one heavy-impact call, fired at the moment of death -- the
      // earlier flap tap contributed none, and nothing else taps/flaps
      // during these frames.
      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.single.method, 'HapticFeedback.vibrate');
      expect(hapticCalls.single.arguments, 'HapticFeedbackType.heavyImpact');

      // Replace the tree to dispose the game-loop ticker cleanly.
      await tester.pumpWidget(const SizedBox());
    },
  );
}
