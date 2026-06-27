import 'package:crappy_turd/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the game screen', (tester) async {
    await tester.pumpWidget(const CrappyTurdApp());
    expect(find.byType(GameScreen), findsOneWidget);
  });
}
