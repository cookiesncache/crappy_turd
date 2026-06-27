import 'dart:math' as math;

import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints the cute, glossy turd mascot centred on the canvas origin (0, 0),
/// sized so its overall height is roughly [size].
///
/// The caller translates (and, from M2, rotates) the canvas before calling
/// this, which keeps the mascot reusable for velocity-based tilt later.
void paintTurd(Canvas canvas, double size) {
  final s = size;

  // Four stacked "scoops" (bottom -> swirl tip), expressed relative to [s].
  Rect scoop(double cy, double w, double h) =>
      Rect.fromCenter(center: Offset(0, s * cy), width: s * w, height: s * h);
  final scoops = <Rect>[
    scoop(0.30, 0.96, 0.44),
    scoop(0.04, 0.74, 0.40),
    scoop(-0.20, 0.52, 0.34),
    scoop(-0.40, 0.30, 0.26),
  ];

  // Merge the scoops into one clean silhouette via boolean union.
  var body = Path();
  for (final r in scoops) {
    body = Path.combine(PathOperation.union, body, Path()..addOval(r));
  }

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
