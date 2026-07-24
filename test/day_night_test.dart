import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/day_night.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dayNightT', () {
    const cycle = 10.0;

    test('t=0 is exactly day (0.0)', () {
      expect(dayNightT(0, cycle), 0.0);
    });

    test('t=cycleDuration is exactly peak night (1.0)', () {
      expect(dayNightT(cycle, cycle), 1.0);
    });

    test('midway through the rising half is midway to night (0.5)', () {
      expect(dayNightT(cycle / 2, cycle), closeTo(0.5, 1e-9));
    });

    test('t=1.5*cycleDuration is halfway back to day (0.5)', () {
      expect(dayNightT(1.5 * cycle, cycle), closeTo(0.5, 1e-9));
    });

    test(
      't=2*cycleDuration is exactly day again (0.0) -- the loop seam',
      () {
        // The easiest spot to get an off-by-one wrong: this must land
        // exactly on the START of the next rising half (via the modulo
        // folding back to phase 0), not merely close to 0 from the tail
        // end of the falling half, which would mask a `<` vs `<=`
        // boundary mistake.
        expect(dayNightT(2 * cycle, cycle), 0.0);
      },
    );

    test(
      't=2.5*cycleDuration is 0.5 again, proving the wave actually loops '
      'instead of clamping after the first cycle',
      () {
        expect(dayNightT(2.5 * cycle, cycle), closeTo(0.5, 1e-9));
      },
    );

    test('a very-large t (10 full loops in) keeps cycling, not drifting', () {
      const loops = 10;
      const base = loops * 2 * cycle;
      // Exactly on a loop seam, 10 loops in -- day.
      expect(dayNightT(base, cycle), 0.0);
      // A quarter into loop 11's rising half.
      expect(dayNightT(base + cycle / 4, cycle), closeTo(0.25, 1e-9));
      // Peak night, 10 loops in.
      expect(dayNightT(base + cycle, cycle), 1.0);
      // Halfway back down toward day, 10 loops in.
      expect(dayNightT(base + 1.5 * cycle, cycle), closeTo(0.5, 1e-9));
      // Landing exactly on the NEXT loop seam (11 loops in).
      expect(dayNightT(base + 2 * cycle, cycle), 0.0);
    });

    test('the result never leaves [0, 1] across a dense sweep', () {
      for (var i = 0; i <= 2000; i++) {
        // A step size that's deliberately not a clean fraction of the
        // cycle, so the sweep lands on many different phases rather than
        // only ever re-hitting the same handful of "nice" points.
        final t = i * (cycle / 17);
        expect(dayNightT(t, cycle), inInclusiveRange(0.0, 1.0));
      }
    });

    test(
      'is symmetric around peak night: equal distance before and after '
      'give equal values',
      () {
        for (final offset in [0.0, 1.0, 3.3, 5.0]) {
          final before = dayNightT(cycle - offset, cycle);
          final after = dayNightT(cycle + offset, cycle);
          expect(before, closeTo(after, 1e-9));
        }
      },
    );

    test('behaves the same way when wired to the real game constant', () {
      const real = GameConstants.dayNightCycleDuration;
      expect(dayNightT(0, real), 0.0);
      expect(dayNightT(real, real), 1.0);
      expect(dayNightT(1.5 * real, real), closeTo(0.5, 1e-9));
      expect(dayNightT(2 * real, real), 0.0);
      expect(dayNightT(2.5 * real, real), closeTo(0.5, 1e-9));
    });
  });
}
