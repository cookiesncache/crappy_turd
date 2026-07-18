import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints every live pipe as a friendly, rounded, non-scary obstacle: a
/// green body with a darker, slightly wider "collar" cap at the end facing
/// the gap, for a cute silhouette. All positions/sizes are derived from
/// [GameConstants] converted to pixels via [size].
void paintPipes(Canvas canvas, Size size, List<Pipe> pipes) {
  for (final pipe in pipes) {
    _paintPipe(canvas, size, pipe);
  }
}

/// Pixel-space geometry for one pipe's four solid pieces (top bar, bottom
/// bar, top collar cap, bottom collar cap), derived from a pipe and the
/// real canvas size.
///
/// Shared by [_paintPipe] and [pipeCollisionPath] so rendering and
/// collision detection read from one formula rather than two
/// independently-written ones that merely happen to agree today.
class _PipeGeometry {
  _PipeGeometry(Pipe pipe, Size size)
    : left = pipe.x * size.width,
      pipeWidth = GameConstants.pipeWidth * size.width,
      gapTop = (pipe.gapCenterY - GameConstants.gapHeight / 2) * size.height,
      gapBottom = (pipe.gapCenterY + GameConstants.gapHeight / 2) * size.height,
      groundTop = size.height * GameConstants.groundY;

  final double left;
  final double pipeWidth;
  final double gapTop;
  final double gapBottom;
  final double groundTop;

  double get right => left + pipeWidth;

  Radius get bodyRadius => Radius.circular(pipeWidth * 0.12);

  double get capOverhang => pipeWidth * 0.15;
  double get capHeight => pipeWidth * 0.4;
  Radius get capRadius => Radius.circular(pipeWidth * 0.16);

  // Clamp both caps to the screen edges: capHeight scales with pipe width,
  // so on a wide (landscape) viewport it can otherwise exceed the vertical
  // clearance GameConstants.gapMargin guarantees, clipping into the ground
  // or off the top of the screen.
  double get topCapTop => math.max<double>(gapTop - capHeight, 0);
  double get bottomCapBottom => math.min(gapBottom + capHeight, groundTop);

  /// Top pipe: screen top down to the gap.
  RRect get topBar => RRect.fromRectAndRadius(
    Rect.fromLTRB(left, 0, right, gapTop),
    bodyRadius,
  );

  /// Bottom pipe: from the gap down to where it meets the ground.
  RRect get bottomBar => RRect.fromRectAndRadius(
    Rect.fromLTRB(left, gapBottom, right, groundTop),
    bodyRadius,
  );

  RRect get topCap => RRect.fromRectAndRadius(
    Rect.fromLTRB(left - capOverhang, topCapTop, right + capOverhang, gapTop),
    capRadius,
  );

  RRect get bottomCap => RRect.fromRectAndRadius(
    Rect.fromLTRB(
      left - capOverhang,
      gapBottom,
      right + capOverhang,
      bottomCapBottom,
    ),
    capRadius,
  );
}

/// The pipe's exact painted silhouette: the union of its top bar, bottom
/// bar, and both (clamped) collar caps, in absolute SCREEN/pixel space for
/// the given canvas [size].
///
/// This is built from the same [_PipeGeometry] that [_paintPipe] draws, and
/// is used directly for real-geometry collision detection (see
/// `lib/game/collision.dart`).
Path pipeCollisionPath(Pipe pipe, Size size) {
  final g = _PipeGeometry(pipe, size);
  var path = Path()..addRRect(g.topBar);
  path = Path.combine(PathOperation.union, path, Path()..addRRect(g.bottomBar));
  path = Path.combine(PathOperation.union, path, Path()..addRRect(g.topCap));
  path = Path.combine(
    PathOperation.union,
    path,
    Path()..addRRect(g.bottomCap),
  );
  return path;
}

void _paintPipe(Canvas canvas, Size size, Pipe pipe) {
  final g = _PipeGeometry(pipe, size);

  final body = Paint()..color = Palette.pipeGreen;
  canvas
    ..drawRRect(g.topBar, body)
    ..drawRRect(g.bottomBar, body);

  // Wider "collar" caps at the gap-facing end of each pipe, for a cute
  // silhouette.
  final cap = Paint()..color = Palette.pipeGreenDark;
  canvas
    ..drawRRect(g.topCap, cap)
    ..drawRRect(g.bottomCap, cap);
}
