import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/cloud.dart';
import 'package:crappy_turd/models/particle.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:crappy_turd/models/shooting_star.dart';
import 'package:crappy_turd/models/star.dart';
import 'package:crappy_turd/models/trail_sample.dart';
import 'package:crappy_turd/models/turd.dart';
import 'package:crappy_turd/render/cloud_painter.dart';
import 'package:crappy_turd/render/particle_painter.dart';
import 'package:crappy_turd/render/pipe_painter.dart';
import 'package:crappy_turd/render/shooting_star_painter.dart';
import 'package:crappy_turd/render/star_painter.dart';
import 'package:crappy_turd/render/turd_painter.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints the whole game world each frame: a bright (or, on a long enough
/// run, twilight) sky with twinkling stars and the odd shooting star,
/// drifting clouds and a rainbow, a grassy ground, scrolling pipes, a
/// fading motion trail, the turd at its current height/tilt/squash, and any
/// live decorative particles on top of everything.
class GamePainter extends CustomPainter {
  const GamePainter({
    required this.turd,
    required this.pipes,
    required this.clouds,
    required this.trailSamples,
    required this.particles,
    required this.stars,
    required this.shootingStars,
    required this.dayNightT,
    required this.playTime,
  });

  final Turd turd;
  final List<Pipe> pipes;
  final List<Cloud> clouds;
  final List<TrailSample> trailSamples;
  final List<Particle> particles;
  final List<Star> stars;
  final List<ShootingStar> shootingStars;

  /// How far a run has shifted from day (0.0) toward night (1.0), looping
  /// back and forth for as long as a run lasts. See
  /// `GameConstants.dayNightCycleDuration` and `lib/game/day_night.dart`.
  final double dayNightT;

  /// Seconds of continuous play in the current run -- the same clock
  /// driving [dayNightT], reused here purely as the twinkle-phase time
  /// input for `paintStars` (see that function's doc for why it must be
  /// this clock and not a separate always-ticking one).
  final double playTime;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    // Stars and shooting streaks sit in front of the plain sky gradient but
    // behind everything else, including the clouds -- explicitly requested
    // z-order, so a cloud drifting past never looks like it's occluding a
    // star that's actually meant to be far behind it.
    //
    // Stars don't fade in/out in lockstep with the raw day/night amount --
    // see GameConstants.starVisibilityThreshold -- they stay fully hidden
    // until the sky is already well into dusk, then fade in over the rest
    // of the way to peak night, and (since this is applied to dayNightT
    // itself, which rises then falls) fade back out again over the
    // equivalent stretch on the way back toward day. _smoothstep eases
    // that fade in/out smoothly rather than ramping at a constant linear
    // rate with an abrupt kink where the ramp starts/ends.
    final starRamp =
        ((dayNightT - GameConstants.starVisibilityThreshold) /
                (1 - GameConstants.starVisibilityThreshold))
            .clamp(0.0, 1.0);
    final starVisibility = _smoothstep(starRamp);
    paintStars(canvas, size, stars, playTime, starVisibility);
    paintShootingStars(canvas, size, shootingStars);
    // Furthest-back solid layer: clouds drift behind the rainbow and
    // everything else.
    paintClouds(canvas, size, clouds);
    _paintRainbow(canvas, size);
    _paintGround(canvas, size);
    paintPipes(canvas, size, pipes);
    paintTurdTrail(canvas, size, trailSamples);
    _paintTurd(canvas, size);
    // Frontmost layer: particle bursts read as being in front of
    // everything, including the turd itself.
    paintParticles(canvas, size, particles);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final topColor = Color.lerp(
      Palette.skyTop,
      Palette.nightSkyTop,
      dayNightT,
    )!;
    final bottomColor = Color.lerp(
      Palette.skyBottom,
      Palette.nightSkyBottom,
      dayNightT,
    )!;
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      ).createShader(rect);
    canvas.drawRect(rect, sky);
  }

  void _paintRainbow(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.86);
    final outerR = size.height * 0.72;
    final band = size.height * 0.024;
    // Finishes fading out early in dusk rather than lingering faintly
    // visible across the whole transition -- see
    // GameConstants.rainbowFadeThreshold -- and (since this is applied to
    // dayNightT itself, which rises then falls) doesn't start fading back
    // in until deep into the return leg toward day. _smoothstep eases that
    // fade in/out smoothly rather than ramping at a constant linear rate
    // with an abrupt kink where the ramp starts/ends.
    final rainbowRamp = (dayNightT / GameConstants.rainbowFadeThreshold).clamp(
      0.0,
      1.0,
    );
    final visibility = 1 - _smoothstep(rainbowRamp);
    for (var i = 0; i < Palette.rainbow.length; i++) {
      final paint = Paint()
        ..color = Palette.rainbow[i].withValues(alpha: 0.6 * visibility)
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
    final widthScale = size.width * GameConstants.turdWidthFraction;
    final heightScale = size.height * GameConstants.turdSize;
    final center = Offset(
      size.width * GameConstants.turdX,
      turd.y * size.height,
    );
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(turd.tilt)
      // RENDER-ONLY squash/stretch: a few-percent scale wobble on
      // flap/impact. Deliberately NOT applied in
      // `lib/game/collision.dart`, which keeps translating+rotating the
      // unscaled silhouette -- see the comment there. Adding a scale here
      // and nowhere else is intentional, not an oversight.
      ..scale(turd.scaleX, turd.scaleY);
    paintTurd(canvas, widthScale, heightScale);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}

/// A classic ease-in-ease-out curve (zero slope at both `x == 0` and
/// `x == 1`, unlike a raw linear ramp) for [x] in `[0, 1]`. Used to smooth
/// the rainbow/star visibility fades above so they ease gently in and out
/// instead of changing at a constant rate with an abrupt kink at each end
/// of the ramp.
double _smoothstep(double x) => x * x * (3 - 2 * x);
