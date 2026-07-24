/// Computes how far a run has shifted from day (`0.0`) toward night
/// (`1.0`) at [playTime] seconds into a run, given [cycleDuration] -- the
/// number of seconds for a single one-way day->night ramp (see
/// `GameConstants.dayNightCycleDuration`).
///
/// This is a triangle wave, not a one-way ramp: it rises linearly from 0 to
/// 1 over the first [cycleDuration] seconds (day -> night), then falls
/// linearly from 1 back to 0 over the NEXT [cycleDuration] seconds (night
/// -> day), then repeats that `2 * cycleDuration`-second cycle indefinitely
/// for as long as a run lasts -- day -> night -> day -> night -> ...
///
/// [cycleDuration] is deliberately the ONE-WAY duration, not the round-trip
/// period; the round trip is `2 * cycleDuration` seconds.
///
/// Pure function, no Flutter/dart:ui dependency, so it's directly
/// unit-testable in isolation (see test/day_night_test.dart) rather than
/// only indirectly via the widget it drives.
double dayNightT(double playTime, double cycleDuration) {
  final period = 2 * cycleDuration;
  // Fold playTime into a single [0, period) phase. Dart's `%` on doubles
  // already returns a result with the same sign as the (positive) divisor,
  // so this stays non-negative even for the (currently unreachable, since
  // `_playTime` never goes negative) case of a negative playTime.
  final phase = playTime % period;
  if (phase <= cycleDuration) {
    // Rising half of the wave: day -> night. At phase == 0 this is exactly
    // 0.0 (day); at phase == cycleDuration it is exactly 1.0 (peak night),
    // which is also where the falling-half branch below picks up from --
    // the two halves meet with no jump.
    return phase / cycleDuration;
  }
  // Falling half of the wave: night -> day. At phase == period (which
  // `%` folds back to phase == 0 on the NEXT call, not this one -- see the
  // loop-seam test) this branch is never actually evaluated at exactly
  // phase == period; the largest phase this branch ever sees approaches
  // (but never reaches) `period`, where the value approaches (but never
  // reaches) 0 from above -- the seam back to exactly 0.0 is provided by
  // the `phase <= cycleDuration` branch on the wrap-around, not by this
  // one.
  return 2 - phase / cycleDuration;
}
