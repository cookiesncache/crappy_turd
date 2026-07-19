import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/pipe.dart';

/// Counts how many [pipes] have newly scrolled behind the turd's fixed
/// horizontal position ([GameConstants.turdX]) since the last call, marking
/// each one's [Pipe.passed] flag so it is never counted twice.
///
/// A pipe counts as "passed" once its right edge (`pipe.x +
/// GameConstants.pipeWidth`) has scrolled behind the turd. Call this once
/// per frame with the live pipe list; the returned count is how much the
/// running score should increase by this frame (usually 0 or 1, but could
/// be more than one if several pipes cross the threshold in the same
/// frame).
int countPipesPassed(List<Pipe> pipes) {
  var count = 0;
  for (final pipe in pipes) {
    if (!pipe.passed &&
        pipe.x + GameConstants.pipeWidth < GameConstants.turdX) {
      pipe.passed = true;
      count++;
    }
  }
  return count;
}
