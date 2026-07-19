import 'package:crappy_turd/models/particle.dart';
import 'package:flutter/material.dart';

/// Paints every live particle as a small filled circle at its pixel
/// position, sized by [Particle.size] and faded by [Particle.opacity].
void paintParticles(Canvas canvas, Size size, List<Particle> particles) {
  for (final p in particles) {
    final paint = Paint()
      ..color = p.color.withValues(alpha: p.color.a * p.opacity);
    canvas.drawCircle(
      Offset(p.x * size.width, p.y * size.height),
      p.size * size.width,
      paint,
    );
  }
}
