import 'package:crappy_turd/game/high_score_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HighScoreStore', () {
    test('a fresh store with no prior saved value loads 0', () async {
      SharedPreferences.setMockInitialValues({});

      final store = HighScoreStore();

      expect(await store.load(), 0);
    });

    test(
      'saving a value and then loading from a new instance roundtrips it '
      'correctly',
      () async {
        SharedPreferences.setMockInitialValues({});

        final writer = HighScoreStore();
        await writer.save(42);

        // A brand-new instance -- proves the value came back from the
        // underlying mocked platform storage, not from any in-memory state
        // held by the instance that wrote it.
        final reader = HighScoreStore();
        expect(await reader.load(), 42);
      },
    );
  });
}
