import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/star.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints every star as a small pale filled circle that both brightens AND
/// grows at the peak of its twinkle (see [GameConstants.starTwinkleMinScale]
/// / [GameConstants.starTwinkleMaxScale]) via a per-star sine wave, with
/// overall visibility following [alpha].
///
/// [playTime] -- NOT wall-clock/real elapsed time -- drives the twinkle
/// phase. It must be `_GameScreenState._playTime` (see main.dart): that
/// clock freezes the instant a run ends and resets to 0 on restart, same as
/// everything else on the frozen game-over scene, so stars freeze mid-
/// twinkle right along with it. A separate always-ticking clock would keep
/// the stars visibly twinkling over an otherwise fully frozen scene, which
/// would read as a bug.
///
/// [alpha] is the star field's overall visibility (`0.0` = fully hidden,
/// `1.0` = fully shown) -- the caller (`lib/render/game_painter.dart`)
/// derives this from the current day/night amount via its own fade curve,
/// so this function only needs the already-resolved result, not the shape
/// of that curve.
void paintStars(
  Canvas canvas,
  Size size,
  List<Star> stars,
  double playTime,
  double alpha,
) {
  if (alpha <= 0) return;
  for (final star in stars) {
    _paintStar(canvas, size, star, playTime, alpha);
  }
}

void _paintStar(
  Canvas canvas,
  Size size,
  Star star,
  double playTime,
  double alpha,
) {
  final twinkle =
      0.5 + 0.5 * math.sin(playTime * star.twinkleSpeed + star.twinklePhase);
  final paint = Paint()
    ..color = Palette.star.withValues(
      alpha: Palette.star.a * twinkle * alpha,
    );
  final center = Offset(star.x * size.width, star.y * size.height);
  // Grows past its own resting size at peak brightness and shrinks below
  // it at the dimmest point, rather than staying a fixed size while only
  // its opacity changes.
  final scale =
      GameConstants.starTwinkleMinScale +
      (GameConstants.starTwinkleMaxScale - GameConstants.starTwinkleMinScale) *
          twinkle;
  final radius = star.size * size.width * scale;
  canvas.drawCircle(center, radius, paint);
}
