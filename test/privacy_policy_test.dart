import 'dart:io';

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/main.dart';
import 'package:crappy_turd/ui/privacy_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Long enough for the dialog's open/close transition and the title
/// overlay's cross-fade to finish. The title screen animates forever, so
/// pumpAndSettle would never return.
const Duration _settle = Duration(milliseconds: 400);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('the in-app policy is identical to store/privacy-policy.md', () {
    // The hosted policy (the URL on the Play listing) and the in-app copy
    // must say the same thing.
    String normalize(String s) => s.replaceAll('\r\n', '\n').trim();
    final hosted = File('store/privacy-policy.md').readAsStringSync();
    expect(normalize(privacyPolicyMarkdown), normalize(hosted));
  });

  testWidgets(
    'the title screen Privacy link opens the policy without starting the '
    'game, and Close returns to the title screen',
    (tester) async {
      await tester.pumpWidget(const CrappyTurdApp());
      expect(find.text('Tap to start'), findsOneWidget);

      await tester.tap(find.text('Privacy'));
      await tester.pump();
      await tester.pump(_settle);

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Information we collect'), findsOneWidget);
      expect(find.textContaining(privacyPolicyUrl), findsOneWidget);
      // The tap went to the link, not the game: still on the title screen,
      // and no score HUD.
      expect(find.text('Tap to start'), findsOneWidget);
      expect(find.text('0'), findsNothing);

      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(_settle);

      expect(find.text('Privacy Policy'), findsNothing);
      expect(find.text('Tap to start'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('the Privacy link is hidden once play starts', (tester) async {
    await tester.pumpWidget(const CrappyTurdApp());
    expect(find.text('Privacy'), findsOneWidget);

    await tester.tap(find.byType(GameScreen));
    await tester.pump();
    await tester.pump(
      GameConstants.overlayFadeDuration + const Duration(milliseconds: 50),
    );

    expect(find.text('Privacy'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
