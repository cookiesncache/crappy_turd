import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/turd.dart';
import 'package:crappy_turd/render/turd_painter.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints the whole game world each frame: a bright sky with a rainbow, a
/// grassy ground, and the turd at its current height and tilt.
class GamePainter extends CustomPainter {
  const GamePainter({required this.turd});

  final Turd turd;

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
    final groundTop = size.height * GameConstants.groundY;
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
    final turdSize = size.height * GameConstants.turdSize;
    final center = Offset(
      size.width * GameConstants.turdX,
      turd.y * size.height,
    );
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(turd.tilt);
    paintTurd(canvas, turdSize);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
