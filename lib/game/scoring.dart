import 'dart:ui' show Size;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/pipe.dart';

/// Counts how many [pipes] have newly scrolled behind the turd's fixed
/// horizontal position ([GameConstants.turdX]) since the last call, marking
/// each one's [Pipe.passed] flag so it is never counted twice.
///
/// A pipe counts as "passed" once its right edge (`pipe.x +
/// GameConstants.pipeWidth`, both screen-HEIGHT fractions) has scrolled
/// behind the turd's fixed screen-WIDTH-fraction position
/// ([GameConstants.turdX]). Those two quantities are expressed in different
/// units (see `lib/models/pipe.dart`'s doc comment for why pipe.x is
/// height-normalized), so comparing them directly would silently be wrong
/// at any non-square aspect ratio -- [size] converts turdX into the same
/// height-fraction unit pipe.x/pipeWidth use before comparing, exactly the
/// same conversion `lib/render/pipe_painter.dart` and
/// `lib/game/collision.dart` already do for the turd's own on-screen pixel
/// position. Call this once per frame with the live pipe list and the real
/// canvas size; the returned count is how much the running score should
/// increase by this frame (usually 0 or 1, but could be more than one if
/// several pipes cross the threshold in the same frame).
int countPipesPassed(List<Pipe> pipes, Size size) {
  final turdXHeightFraction = GameConstants.turdX * size.width / size.height;
  var count = 0;
  for (final pipe in pipes) {
    if (!pipe.passed &&
        pipe.x + GameConstants.pipeWidth < turdXHeightFraction) {
      pipe.passed = true;
      count++;
    }
  }
  return count;
}
