import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints every live pipe as a friendly, rounded, non-scary obstacle: a
/// green body with a darker, slightly wider "collar" cap at the end facing
/// the gap, for a cute silhouette. All positions/sizes are derived from
/// [GameConstants] converted to pixels via [size].
void paintPipes(Canvas canvas, Size size, List<Pipe> pipes) {
  for (final pipe in pipes) {
    _paintPipe(canvas, size, pipe);
  }
}

void _paintPipe(Canvas canvas, Size size, Pipe pipe) {
  final left = pipe.x * size.width;
  final pipeWidth = GameConstants.pipeWidth * size.width;
  final right = left + pipeWidth;

  final gapTop = (pipe.gapCenterY - GameConstants.gapHeight / 2) * size.height;
  final gapBottom =
      (pipe.gapCenterY + GameConstants.gapHeight / 2) * size.height;
  final groundTop = size.height * GameConstants.groundY;

  final bodyRadius = Radius.circular(pipeWidth * 0.12);
  final body = Paint()..color = Palette.pipeGreen;

  canvas
    // Top pipe: screen top down to the gap.
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, 0, right, gapTop),
        bodyRadius,
      ),
      body,
    )
    // Bottom pipe: from the gap down to where it meets the ground.
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, gapBottom, right, groundTop),
        bodyRadius,
      ),
      body,
    );

  // Wider "collar" caps at the gap-facing end of each pipe, for a cute
  // silhouette.
  final capOverhang = pipeWidth * 0.15;
  final capHeight = pipeWidth * 0.4;
  final capRadius = Radius.circular(pipeWidth * 0.16);
  final cap = Paint()..color = Palette.pipeGreenDark;

  // Clamp both caps to the screen edges: capHeight scales with pipe width,
  // so on a wide (landscape) viewport it can otherwise exceed the vertical
  // clearance GameConstants.gapMargin guarantees, clipping into the ground
  // or off the top of the screen.
  final topCapTop = math.max<double>(gapTop - capHeight, 0);
  final bottomCapBottom = math.min(gapBottom + capHeight, groundTop);

  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          left - capOverhang,
          topCapTop,
          right + capOverhang,
          gapTop,
        ),
        capRadius,
      ),
      cap,
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          left - capOverhang,
          gapBottom,
          right + capOverhang,
          bottomCapBottom,
        ),
        capRadius,
      ),
      cap,
    );
}
