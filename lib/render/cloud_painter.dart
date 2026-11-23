import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/cloud.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints every live cloud as a soft, lit cumulus: its puffs merged into
/// one silhouette, shaded from a bright top to a blue-grey underside, with
/// a glow on each puff's upper half where the sun catches it. [dayNightT]
/// (0 = day, 1 = night) dims them toward moonlit slate after dark.
void paintClouds(
  Canvas canvas,
  Size size,
  List<Cloud> clouds,
  double dayNightT,
) {
  final top = Color.lerp(Palette.cloudTop, Palette.cloudNightTop, dayNightT)!;
  final shade = Color.lerp(
    Palette.cloudShade,
    Palette.cloudNightShade,
    dayNightT,
  )!;
  final highlight = Color.lerp(
    Palette.cloudHighlight,
    Palette.cloudNightHighlight,
    dayNightT,
  )!;
  for (final cloud in clouds) {
    _paintCloud(canvas, size, cloud, top, shade, highlight);
  }
}

void _paintCloud(
  Canvas canvas,
  Size size,
  Cloud cloud,
  Color top,
  Color shade,
  Color highlight,
) {
  final cx = cloud.x * size.width;
  final cy = cloud.y * size.height;
  final r = GameConstants.cloudWidth * size.width * cloud.scale * 0.5;

  // All puffs go into ONE path. Same-direction circles fill as their union,
  // so overlaps don't double up the way separately drawn translucent
  // circles do, and the whole cloud reads as a single soft mass.
  final body = Path();
  final glow = Path();
  for (final puff in cloud.puffs) {
    final center = Offset(cx + puff.dx * r, cy + puff.dy * r);
    final radius = puff.radius * r;
    body.addOval(Rect.fromCircle(center: center, radius: radius));
    // The lit part of each puff: a smaller circle nudged upward, leaving
    // the puff's lower edge in shade.
    glow.addOval(
      Rect.fromCircle(
        center: center.translate(0, -radius * 0.2),
        radius: radius * 0.72,
      ),
    );
  }

  final bounds = body.getBounds();
  canvas
    ..drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, top, shade],
          stops: const [0, 0.35, 1],
        ).createShader(bounds)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.04),
    )
    ..drawPath(
      glow,
      Paint()
        ..color = highlight
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.1),
    );
}
