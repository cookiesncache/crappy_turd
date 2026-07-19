import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/trail_sample.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// The four stacked "scoops" (bottom -> swirl tip) that make up the turd's
/// silhouette, expressed relative to [size] and centred on the local origin
/// (0, 0).
///
/// Shared by [turdBodyPath] (for the union silhouette) and [paintTurd]
/// (which also needs the individual rects to draw crease arcs), so the two
/// can never disagree about the underlying geometry.
List<Rect> _turdScoops(double size) {
  final s = size;
  Rect scoop(double cy, double w, double h) =>
      Rect.fromCenter(center: Offset(0, s * cy), width: s * w, height: s * h);
  return <Rect>[
    scoop(0.30, 0.96, 0.44),
    scoop(0.04, 0.74, 0.40),
    scoop(-0.20, 0.52, 0.34),
    scoop(-0.40, 0.30, 0.26),
  ];
}

/// The turd's exact painted silhouette: a boolean union of its four stacked
/// scoops (see [_turdScoops]), in LOCAL space centred on the origin (0, 0)
/// and sized by [size].
///
/// This is the same path [paintTurd] fills/outlines, and it's also used
/// directly for real-geometry collision detection (see
/// `lib/game/collision.dart`) — sharing it means rendering and collision
/// are structurally unable to drift apart.
Path turdBodyPath(double size) {
  var body = Path();
  for (final r in _turdScoops(size)) {
    body = Path.combine(PathOperation.union, body, Path()..addOval(r));
  }
  return body;
}

/// Paints the cute, glossy turd mascot centred on the canvas origin (0, 0),
/// sized so its overall height is roughly [size].
///
/// The caller translates (and, from M2, rotates) the canvas before calling
/// this, which keeps the mascot reusable for velocity-based tilt later.
void paintTurd(Canvas canvas, double size) {
  final s = size;

  final scoops = _turdScoops(s);
  final body = turdBodyPath(s);

  // Fill with a soft top-to-bottom brown gradient (soft-serve look).
  final bodyPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Palette.turdLight, Palette.turdMid, Palette.turdDark],
    ).createShader(body.getBounds());
  canvas.drawPath(body, bodyPaint);

  // Crease shadows: the underside arc of each upper scoop reads as a fold,
  // giving the stack real definition between the lobes.
  final crease = Paint()
    ..color = Palette.turdDark.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.03
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
  canvas
    ..drawArc(scoops[1], 0, math.pi, false, crease)
    ..drawArc(scoops[2], 0, math.pi, false, crease)
    ..drawArc(scoops[3], 0, math.pi, false, crease);

  // Crisp outline around the whole silhouette for extra definition.
  final outline = Paint()
    ..color = Palette.turdDark.withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.022;
  canvas.drawPath(body, outline);

  // Soft glossy highlight near the top-left for a shiny, cute finish.
  final highlight = Paint()
    ..color = Colors.white.withValues(alpha: 0.2)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(-s * 0.12, -s * 0.22),
      width: s * 0.28,
      height: s * 0.15,
    ),
    highlight,
  );

  _paintFace(canvas, s);
}

/// Paints a fading motion-trail of past turd silhouettes: flat,
/// semi-transparent brown ghosts with no face/gradient/outline (unlike the
/// live turd itself), oldest to newest so newer ghosts draw over older
/// ones. Purely decorative -- reuses [turdBodyPath], the exact same
/// silhouette [paintTurd] fills, just rendered as a flat fading shadow
/// instead of the full glossy render.
void paintTurdTrail(Canvas canvas, Size size, List<TrailSample> samples) {
  final turdSize = size.height * GameConstants.turdSize;
  final body = turdBodyPath(turdSize);
  // A cap on how opaque even the very newest ghost gets, so the trail
  // always reads as a subtle wisp behind the turd rather than a second
  // solid copy of it. Feel-tunable. Lowered after feedback that the
  // original 0.3 read as distracting "ghosting" rather than a subtle
  // touch.
  const maxGhostAlpha = 0.14;
  for (final sample in samples) {
    final fade = (1 - sample.age / GameConstants.trailWindow).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = Palette.turdMid.withValues(alpha: maxGhostAlpha * fade);
    canvas
      ..save()
      ..translate(GameConstants.turdX * size.width, sample.y * size.height)
      ..rotate(sample.tilt)
      ..drawPath(body, paint)
      ..restore();
  }
}

void _paintFace(Canvas canvas, double s) {
  final eyeY = -s * 0.15;
  final eyeDx = s * 0.15;
  final eyeR = s * 0.11;
  final pupilR = s * 0.055;

  final white = Paint()..color = Palette.eyeWhite;
  final pupil = Paint()..color = Palette.pupil;
  final shine = Paint()..color = Colors.white;

  for (final dx in [-eyeDx, eyeDx]) {
    canvas
      ..drawCircle(Offset(dx, eyeY), eyeR, white)
      ..drawCircle(Offset(dx, eyeY + s * 0.015), pupilR, pupil)
      ..drawCircle(
        Offset(dx - pupilR * 0.4, eyeY - pupilR * 0.4),
        pupilR * 0.35,
        shine,
      );
  }

  // Rosy cheeks.
  final cheek = Paint()..color = Palette.cheek;
  canvas
    ..drawCircle(Offset(-s * 0.27, eyeY + s * 0.13), s * 0.07, cheek)
    ..drawCircle(Offset(s * 0.27, eyeY + s * 0.13), s * 0.07, cheek);

  // Happy smile.
  final smile = Path()
    ..moveTo(-s * 0.13, eyeY + s * 0.15)
    ..quadraticBezierTo(0, eyeY + s * 0.30, s * 0.13, eyeY + s * 0.15);
  final smilePaint = Paint()
    ..color = Palette.mouth
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.035
    ..strokeCap = StrokeCap.round;
  canvas.drawPath(smile, smilePaint);
}
