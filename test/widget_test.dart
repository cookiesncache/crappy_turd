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
}
