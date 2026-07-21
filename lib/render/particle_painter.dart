import 'dart:math' as math;

import 'package:crappy_turd/models/particle.dart';
import 'package:crappy_turd/models/particle_shape.dart';
import 'package:flutter/material.dart';

/// Paints every live particle at its pixel position, sized by
/// [Particle.size] and faded by [Particle.opacity] -- a plain filled
/// circle for [ParticleShape.soft], a four-pointed twinkling star for
/// [ParticleShape.sparkle].
void paintParticles(Canvas canvas, Size size, List<Particle> particles) {
  for (final p in particles) {
    final paint = Paint()
      ..color = p.color.withValues(alpha: p.color.a * p.opacity);
    final center = Offset(p.x * size.width, p.y * size.height);
    final radius = p.size * size.width;
    switch (p.shape) {
      case ParticleShape.soft:
        canvas.drawCircle(center, radius, paint);
      case ParticleShape.sparkle:
        _drawSparkle(canvas, center, radius, p.spin, paint);
    }
  }
}

/// Draws a four-pointed star (the classic twinkle/sparkle glyph) centred
/// on [center]: 8 vertices alternating between [radius] (the points) and a
/// pinched inner radius (the waist between them), rotated by [spin].
void _drawSparkle(
  Canvas canvas,
  Offset center,
  double radius,
  double spin,
  Paint paint,
) {
  const innerRatio = 0.35;
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final angle = spin + i * math.pi / 4;
    final r = i.isEven ? radius : radius * innerRatio;
    final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  canvas.drawPath(path, paint);
}
