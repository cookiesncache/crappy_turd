import 'dart:ui';

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:crappy_turd/models/turd.dart';
import 'package:crappy_turd/render/pipe_painter.dart';
import 'package:crappy_turd/render/turd_painter.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// True once the turd has settled on the ground.
///
/// Uses the exact same threshold as [Turd.update]'s own floor clamp
/// (`groundY - turdSize / 2`) rather than the smaller hitbox constants —
/// the clamp already caps `y` at that value every frame, so checking
/// against anything larger (like a hitbox-based threshold) would mean this
/// could never fire. It also keeps ground contact visually honest: the
/// turd dies exactly when it visually rests on the ground, not before or
/// after.
bool turdHitsGround(Turd turd) =>
    turd.y >= GameConstants.groundY - GameConstants.turdSize / 2;

/// True if the turd's ACTUAL painted silhouette overlaps the pipe's ACTUAL
/// painted silhouette, for a canvas of the given [size].
///
/// Both silhouettes are built from the exact same geometry the renderer
/// uses ([turdBodyPath] and [pipeCollisionPath]), so this can never drift
/// from what's visually on screen:
///
/// 1. The turd's local-space silhouette (centred on its own origin) is
///    transformed into world/screen space with the same
///    translate-then-rotate composition `game_painter.dart` applies before
///    calling `paintTurd` — translate by the turd's on-screen centre, then
///    rotate by [Turd.tilt].
/// 2. The pipe's silhouette is already in screen space.
/// 3. A cheap bounding-box rejection skips the expensive path-intersection
///    when the two plainly don't overlap.
/// 4. Otherwise, a real `Path.combine(PathOperation.intersect, ...)` decides
///    the answer from actual shape overlap, not a rectangle approximation.
bool turdCollidesWithPipe(Turd turd, Pipe pipe, Size size) {
  final localTurdPath = turdBodyPath(
    GameConstants.turdWidthFraction * size.width,
    GameConstants.turdSize * size.height,
  );

  // Mirrors game_painter.dart's `_paintTurd`: translate to the turd's
  // on-screen centre, THEN rotate by its tilt — same order, same values.
  final center = Offset(
    GameConstants.turdX * size.width,
    turd.y * size.height,
  );
  // Deliberately translate + rotate ONLY -- no scale. From M6, rendering
  // also applies a small render-only squash/stretch scale on flap/impact
  // (see Turd.scaleX/scaleY and game_painter.dart's `_paintTurd`) for a
  // few-percent visual wobble. Collision intentionally keeps using this
  // unscaled silhouette: that's a deliberate simplification, not an
  // oversight -- a flap/impact's squash should never change what the turd
  // can or can't fly through.
  final transform = Matrix4.identity()
    ..translateByDouble(center.dx, center.dy, 0, 1)
    ..rotateZ(turd.tilt);

  final turdWorldPath = localTurdPath.transform(transform.storage);
  final pipeWorldPath = pipeCollisionPath(pipe, size);

  // Cheap early-out: pure optimization, never changes the final answer.
  if (!turdWorldPath.getBounds().overlaps(pipeWorldPath.getBounds())) {
    return false;
  }

  final intersection = Path.combine(
    PathOperation.intersect,
    turdWorldPath,
    pipeWorldPath,
  );
  return !intersection.getBounds().isEmpty;
}

/// True if the turd has hit the ground or any pipe in [pipes], for a canvas
/// of the given [size].
bool checkCollision(Turd turd, List<Pipe> pipes, Size size) =>
    turdHitsGround(turd) ||
    pipes.any((pipe) => turdCollidesWithPipe(turd, pipe, size));
