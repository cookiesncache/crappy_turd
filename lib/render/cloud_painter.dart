import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/cloud.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints every live cloud as a soft, puffy cluster of overlapping filled
/// circles -- a simple, cheap silhouette that reads as a background cloud
/// with no image assets involved.
void paintClouds(Canvas canvas, Size size, List<Cloud> clouds) {
  for (final cloud in clouds) {
    _paintCloud(canvas, size, cloud);
  }
}

void _paintCloud(Canvas canvas, Size size, Cloud cloud) {
  final cx = cloud.x * size.width;
  final cy = cloud.y * size.height;
  final r = GameConstants.cloudWidth * size.width * cloud.scale * 0.5;

  final paint = Paint()..color = Palette.cloud;

  // A puffy cluster of four overlapping lobes: one central "main" lobe
  // plus three smaller ones offset around it, close enough together to
  // read as one soft silhouette rather than distinct circles.
  canvas
    ..drawCircle(Offset(cx - r * 0.6, cy + r * 0.15), r * 0.55, paint)
    ..drawCircle(Offset(cx, cy - r * 0.1), r * 0.7, paint)
    ..drawCircle(Offset(cx + r * 0.65, cy + r * 0.1), r * 0.5, paint)
    ..drawCircle(Offset(cx + r * 0.1, cy + r * 0.25), r * 0.45, paint);
}
