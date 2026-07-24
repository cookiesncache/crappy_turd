import 'dart:ui' as ui;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/shooting_star.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints every live shooting star as a short streak/trail along its
/// direction of travel: bright at the head, fading to fully transparent at
/// the tail, with the whole streak's opacity additionally following
/// [ShootingStar.opacity] (the same linear age/maxLife fade `Particle` uses)
/// so the entire streak dims out together as it nears the end of its life.
void paintShootingStars(
  Canvas canvas,
  Size size,
  List<ShootingStar> shootingStars,
) {
  for (final star in shootingStars) {
    _paintShootingStar(canvas, size, star);
  }
}

void _paintShootingStar(Canvas canvas, Size size, ShootingStar star) {
  final head = Offset(star.x * size.width, star.y * size.height);

  // `vx`/`vy` are fraction-of-width/fraction-of-height per second
  // respectively -- different scales -- so each must be converted to real
  // pixels using its OWN matching screen dimension before the two are
  // combined into one pixel-space direction vector.
  final directionPx = Offset(star.vx * size.width, star.vy * size.height);
  final directionLength = directionPx.distance;
  if (directionLength == 0) return;
  final unit = directionPx / directionLength;

  final tailLength = GameConstants.shootingStarStreakLength * size.width;
  final tail = head - unit * tailLength;

  final headAlpha = Palette.star.a * star.opacity;
  final headColor = Palette.star.withValues(alpha: headAlpha);
  final tailColor = Palette.star.withValues(alpha: 0);

  final paint = Paint()
    ..strokeWidth = GameConstants.shootingStarStrokeWidth * size.width
    ..strokeCap = StrokeCap.round
    ..shader = ui.Gradient.linear(head, tail, [headColor, tailColor]);
  canvas.drawLine(head, tail, paint);
}
