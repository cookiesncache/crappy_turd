import 'dart:math' as math;

import 'package:crappy_turd/render/turd_painter.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints the whole game world. For milestone M1 this is a static scene:
/// a bright sky with a rainbow, a grassy ground, and the turd mascot on it.
class GamePainter extends CustomPainter {
  const GamePainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintRainbow(canvas, size);
    _paintGround(canvas, size);
    _paintTurd(canvas, size);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Palette.skyTop, Palette.skyBottom],
      ).createShader(rect);
    canvas.drawRect(rect, sky);
  }

  void _paintRainbow(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.86);
    final outerR = size.height * 0.72;
    final band = size.height * 0.024;
    for (var i = 0; i < Palette.rainbow.length; i++) {
      final paint = Paint()
        ..color = Palette.rainbow[i].withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = band * 1.05;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerR - i * band),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
  }

  void _paintGround(Canvas canvas, Size size) {
    final groundTop = size.height * 0.82;
    canvas
      ..drawRect(
        Rect.fromLTRB(0, groundTop, size.width, size.height),
        Paint()..color = Palette.ground,
      )
      ..drawRect(
        Rect.fromLTWH(0, groundTop, size.width, size.height * 0.018),
        Paint()..color = Palette.groundShadow,
      );
  }

  void _paintTurd(Canvas canvas, Size size) {
    final turdSize = size.height * 0.22;
    final groundTop = size.height * 0.82;
    final center = Offset(size.width / 2, groundTop - turdSize * 0.5);

    final shadow = Paint()
      ..color = Palette.shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas
      ..drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, groundTop + turdSize * 0.02),
          width: turdSize * 0.9,
          height: turdSize * 0.18,
        ),
        shadow,
      )
      ..save()
      ..translate(center.dx, center.dy);
    paintTurd(canvas, turdSize);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => false;
}
