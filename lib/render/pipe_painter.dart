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
    : left = pipe.x * size.height,
      pipeWidth = GameConstants.pipeWidth * size.height,
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
  final outline = Paint()
    ..color = Palette.pipeOutline
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1, g.pipeWidth * 0.025);

  // Bodies first, then the wider "collar" caps over their gap-facing
  // ends, for a cute silhouette. Purely decorative: none of the shading
  // or detail below changes the silhouette [pipeCollisionPath] uses.
  _paintBody(canvas, g, g.topBar, outline, capEnd: g.topCapTop, up: true);
  _paintBody(
    canvas,
    g,
    g.bottomBar,
    outline,
    capEnd: g.bottomCapBottom,
    up: false,
  );
  _paintCap(canvas, g, g.topCap, outline);
  _paintCap(canvas, g, g.bottomCap, outline);
}

/// Shades a pipe body as a rounded tube lit from the upper left: a
/// horizontal light-to-dark gradient, a glossy highlight stripe, joint
/// rings every so often, and a soft shadow where it meets its cap.
///
/// [capEnd] is the cap's far edge (the end facing away from the gap), and
/// [up] says which way the body runs from there: up for the top pipe, down
/// for the bottom one.
void _paintBody(
  Canvas canvas,
  _PipeGeometry g,
  RRect bar,
  Paint outline, {
  required double capEnd,
  required bool up,
}) {
  if (bar.height <= 0) return;
  final rect = bar.outerRect;
  final w = g.pipeWidth;
  canvas
    ..drawRRect(
      bar,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Palette.pipeGreenDark,
            Palette.pipeGreen,
            Palette.pipeGreenLight,
            Palette.pipeGreen,
            Palette.pipeGreenDark,
          ],
          stops: [0, 0.14, 0.3, 0.55, 1],
        ).createShader(rect),
    )
    ..save()
    ..clipRRect(bar);

  // Joint rings, counted out from the cap so they stay evenly spaced from
  // the gap whatever the pipe's height: a dark groove with a lit edge.
  final spacing = w * 1.4;
  final groove = Paint()..color = Palette.pipeOutline.withValues(alpha: 0.3);
  final lit = Paint()..color = Colors.white.withValues(alpha: 0.18);
  for (var k = 1; ; k++) {
    final y = up ? capEnd - k * spacing : capEnd + k * spacing;
    if (y < rect.top - w || y > rect.bottom) break;
    canvas
      ..drawRect(Rect.fromLTWH(rect.left, y, w, w * 0.035), groove)
      ..drawRect(Rect.fromLTWH(rect.left, y + w * 0.035, w, w * 0.025), lit);
  }

  // Glossy highlight stripe running the length of the tube.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left + w * 0.2, rect.top, w * 0.07, rect.height),
      Radius.circular(w * 0.035),
    ),
    Paint()..color = Colors.white.withValues(alpha: 0.32),
  );

  // Soft contact shadow on the body right next to the cap.
  final shadowDepth = w * 0.25;
  final shadowRect = up
      ? Rect.fromLTRB(rect.left, capEnd - shadowDepth, rect.right, capEnd)
      : Rect.fromLTRB(rect.left, capEnd, rect.right, capEnd + shadowDepth);
  canvas
    ..drawRect(
      shadowRect,
      Paint()
        ..shader = LinearGradient(
          begin: up ? Alignment.bottomCenter : Alignment.topCenter,
          end: up ? Alignment.topCenter : Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0),
          ],
        ).createShader(shadowRect),
    )
    ..restore()
    ..drawRRect(bar, outline);
}

/// Shades a collar cap like the body (a touch darker), with a lit top rim,
/// a shaded bottom rim, and a row of rivets.
void _paintCap(Canvas canvas, _PipeGeometry g, RRect cap, Paint outline) {
  if (cap.height <= 0) return;
  final rect = cap.outerRect;
  final w = g.pipeWidth;
  canvas
    ..drawRRect(
      cap,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Palette.pipeOutline,
            Palette.pipeGreenDark,
            Palette.pipeGreen,
            Palette.pipeGreenDark,
            Palette.pipeOutline,
          ],
          stops: [0, 0.12, 0.28, 0.6, 1],
        ).createShader(rect),
    )
    ..save()
    ..clipRRect(cap)
    ..drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.16),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    )
    ..drawRect(
      Rect.fromLTWH(
        rect.left,
        rect.bottom - rect.height * 0.14,
        rect.width,
        rect.height * 0.14,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left + rect.width * 0.2,
          rect.top,
          w * 0.07,
          rect.height,
        ),
        Radius.circular(w * 0.035),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

  // Rivets, skipped on a cap squeezed too short (see the clamping in
  // _PipeGeometry) to fit them.
  final rivetR = w * 0.045;
  if (rect.height > rivetR * 4) {
    final rivet = Paint()..color = Palette.pipeOutline.withValues(alpha: 0.7);
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (final f in const [0.18, 0.5, 0.82]) {
      final c = Offset(rect.left + rect.width * f, rect.center.dy);
      canvas
        ..drawCircle(c, rivetR, rivet)
        ..drawCircle(
          c.translate(-rivetR * 0.35, -rivetR * 0.35),
          rivetR * 0.4,
          shine,
        );
    }
  }
  canvas
    ..restore()
    ..drawRRect(cap, outline);
}
