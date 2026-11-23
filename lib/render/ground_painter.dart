import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// The fraction of the ground's depth that is grass (the rest is soil).
const double _grassFraction = 0.3;

/// Where something standing on the grass (a bunny) puts its feet: a bit
/// over halfway down the grass band, so it reads as standing on the grass
/// rather than balancing on its back edge.
double grassFootY(Size size) {
  final top = size.height * GameConstants.groundY;
  return top + (size.height - top) * _grassFraction * 0.55;
}

/// Paints the ground: a band of striped grass dotted with little flowers,
/// with blades along its top edge and a scalloped lip hanging over warm,
/// pebbly soil.
///
/// [scroll] is how far, in pixels, the ground has moved left. Passing the
/// distance the pipes have travelled makes the ground move with them, so
/// the whole world reads as sliding past the turd. Every repeating detail
/// takes `scroll` modulo its own period, so the numbers stay small however
/// long a run lasts.
void paintGround(Canvas canvas, Size size, double scroll) {
  final top = size.height * GameConstants.groundY;
  final depth = size.height - top;
  if (depth <= 0 || size.width <= 0) return;
  final w = size.width;
  final grassH = depth * _grassFraction;
  final lipR = grassH * 0.3;
  final lipY = top + grassH;

  // Soil, from just under the grass down to the bottom of the screen.
  final soil = Rect.fromLTRB(0, top + grassH * 0.5, w, size.height);
  canvas.drawRect(
    soil,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Palette.soilTop, Palette.soilBottom],
      ).createShader(soil),
  );
  _paintPebbles(
    canvas,
    w,
    soilTop: lipY + lipR * 1.4,
    soilBottom: size.height,
    depth: depth,
    scroll: scroll,
  );

  // The grass band plus its scalloped lower lip, as one shape, with the
  // lip's shadow on the soil underneath.
  final lipPeriod = lipR * 1.8;
  final lipShift = scroll % lipPeriod;
  final grass = Path()..addRect(Rect.fromLTRB(0, top, w, lipY));
  final lipShadow = Path();
  for (var x = -lipShift; x < w + lipPeriod; x += lipPeriod) {
    grass.addOval(Rect.fromCircle(center: Offset(x, lipY), radius: lipR));
    lipShadow.addOval(
      Rect.fromCircle(center: Offset(x, lipY + depth * 0.03), radius: lipR),
    );
  }
  canvas
    ..drawPath(
      lipShadow,
      Paint()..color = Palette.pebbleDark.withValues(alpha: 0.55),
    )
    ..drawPath(grass, Paint()..color = Palette.ground)
    ..save()
    ..clipPath(grass);

  // Diagonal mowing stripes across the grass.
  final stripePeriod = grassH * 0.9;
  final stripeShift = scroll % stripePeriod;
  final slant = grassH * 0.45;
  final bottom = lipY + lipR;
  final stripes = Path();
  for (
    var x = -stripeShift - stripePeriod;
    x < w + slant + stripePeriod;
    x += stripePeriod
  ) {
    stripes
      ..moveTo(x, top)
      ..lineTo(x + stripePeriod / 2, top)
      ..lineTo(x + stripePeriod / 2 - slant, bottom)
      ..lineTo(x - slant, bottom)
      ..close();
  }
  canvas
    ..drawPath(stripes, Paint()..color = Palette.groundStripe)
    // A lit strip just under the top edge.
    ..drawRect(
      Rect.fromLTWH(0, top + depth * 0.02, w, depth * 0.025),
      Paint()..color = Palette.groundHighlight.withValues(alpha: 0.7),
    )
    ..restore();

  // Grass blades poking up along the top edge, in a few repeating heights,
  // over a darker edge line. (They poke above the ground line, into the
  // play area, but are drawn under the pipes and are too small to matter
  // next to the turd's own ground collision.)
  final bladeGap = grassH * 0.16;
  final firstBlade = (scroll / bladeGap).floor();
  final blades = Path();
  for (var k = firstBlade - 1; ; k++) {
    final x = k * bladeGap - scroll;
    if (x > w + bladeGap) break;
    final height = grassH * const [0.14, 0.22, 0.17, 0.26, 0.12][k % 5];
    final lean = bladeGap * (k.isEven ? 0.15 : -0.1);
    blades
      ..moveTo(x - bladeGap * 0.45, top + 1)
      ..lineTo(x + lean, top - height)
      ..lineTo(x + bladeGap * 0.45, top + 1)
      ..close();
  }
  canvas
    ..drawPath(blades, Paint()..color = Palette.groundShadow)
    ..drawRect(
      Rect.fromLTWH(0, top, w, depth * 0.02),
      Paint()..color = Palette.groundShadow,
    );

  _paintFlowers(
    canvas,
    w,
    grassTop: top,
    grassBottom: lipY,
    depth: depth,
    scroll: scroll,
  );
}

/// One flower in the repeating flower tile: [fx] across the tile, [fy]
/// down the grass band (0 = back edge, 1 = front), [size] and [stem] as
/// fractions of the ground depth, and which petal colour it has.
class _Flower {
  const _Flower(this.fx, this.fy, this.size, this.stem, this.color);

  final double fx;
  final double fy;
  final double size;
  final double stem;
  final int color;
}

/// A fixed tile of flowers (fixed seed, so identical every frame). Drawn
/// in batches by part and colour, which is cheap and fine because the
/// flowers are small and sparse enough to rarely overlap.
final List<_Flower> _flowerTile = () {
  final random = math.Random(5);
  return [
    for (var i = 0; i < 11; i++)
      _Flower(
        random.nextDouble(),
        random.nextDouble(),
        0.021 + random.nextDouble() * 0.013,
        0.04 + random.nextDouble() * 0.06,
        random.nextInt(Palette.flowerPetals.length),
      ),
  ];
}();

void _paintFlowers(
  Canvas canvas,
  double width, {
  required double grassTop,
  required double grassBottom,
  required double depth,
  required double scroll,
}) {
  // A different width from the pebble tile, so the two repeats never line
  // up into an obvious pattern.
  final tile = depth * 1.9;
  final shift = scroll % tile;
  final band = grassBottom - grassTop;
  final stems = Path();
  final leaves = Path();
  final petals = [for (final _ in Palette.flowerPetals) Path()];
  final centers = Path();
  for (var x0 = -shift - tile; x0 < width + tile; x0 += tile) {
    for (final f in _flowerTile) {
      // Nearer (lower) flowers are drawn a little bigger.
      final near = 0.8 + 0.4 * f.fy;
      final base = Offset(
        x0 + f.fx * tile,
        grassTop + band * (0.2 + 0.7 * f.fy),
      );
      final head = base.translate(0, -f.stem * depth * near);
      final p = f.size * depth * near;
      stems
        ..moveTo(base.dx, base.dy)
        ..lineTo(head.dx, head.dy);
      // One leaf partway up, alternating sides.
      final side = f.fx < 0.5 ? 1.0 : -1.0;
      final leafY = (base.dy + head.dy) / 2 + p * 0.4;
      final l = p * 1.1 * side;
      leaves
        ..moveTo(base.dx, leafY)
        ..quadraticBezierTo(
          base.dx + l,
          leafY - p * 1.0,
          base.dx + l * 1.5,
          leafY - p * 0.3,
        )
        ..quadraticBezierTo(base.dx + l * 0.6, leafY + p * 0.2, base.dx, leafY)
        ..close();
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / 5;
        petals[f.color].addOval(
          Rect.fromCircle(
            center: head.translate(
              math.cos(a) * p * 0.72,
              math.sin(a) * p * 0.72,
            ),
            radius: p * 0.55,
          ),
        );
      }
      centers.addOval(Rect.fromCircle(center: head, radius: p * 0.4));
    }
  }
  canvas
    ..drawPath(
      stems,
      Paint()
        ..color = Palette.flowerStem
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, depth * 0.008)
        ..strokeCap = StrokeCap.round,
    )
    ..drawPath(leaves, Paint()..color = Palette.flowerStem);
  for (var i = 0; i < petals.length; i++) {
    canvas.drawPath(petals[i], Paint()..color = Palette.flowerPetals[i]);
  }
  canvas.drawPath(centers, Paint()..color = Palette.flowerCenter);
}

/// One pebble in the repeating soil tile: position as fractions of the
/// tile's width and the soil's visible depth, size as a fraction of the
/// whole ground depth.
class _Pebble {
  const _Pebble(this.fx, this.fy, this.size, {required this.light});

  final double fx;
  final double fy;
  final double size;
  final bool light;
}

/// A fixed, hand-scattered-looking tile of pebbles (from a fixed seed, so
/// it's identical every frame and every launch).
final List<_Pebble> _pebbleTile = () {
  final random = math.Random(11);
  return [
    for (var i = 0; i < 20; i++)
      _Pebble(
        random.nextDouble(),
        random.nextDouble(),
        // Mostly small, the odd bigger one.
        0.01 + math.pow(random.nextDouble(), 2) * 0.03,
        light: random.nextInt(3) == 0,
      ),
  ];
}();

void _paintPebbles(
  Canvas canvas,
  double width, {
  required double soilTop,
  required double soilBottom,
  required double depth,
  required double scroll,
}) {
  final band = soilBottom - soilTop;
  if (band <= 0) return;
  // Wider than most phone screens, so the repeat is hard to spot.
  final tile = depth * 2.6;
  final shift = scroll % tile;
  final dark = Path();
  final light = Path();
  final shine = Path();
  // Starts one tile early so pebbles hanging over a tile's left edge are
  // still drawn.
  for (var x0 = -shift - tile; x0 < width; x0 += tile) {
    for (final p in _pebbleTile) {
      final r = p.size * depth;
      final c = Offset(
        x0 + p.fx * tile,
        soilTop + r + p.fy * math.max(0, band - 2 * r),
      );
      final oval = Rect.fromCenter(center: c, width: r * 2.6, height: r * 1.8);
      (p.light ? light : dark).addOval(oval);
      shine.addOval(
        Rect.fromCenter(
          center: c.translate(-r * 0.45, -r * 0.35),
          width: r * 0.9,
          height: r * 0.5,
        ),
      );
    }
  }
  canvas
    ..drawPath(dark, Paint()..color = Palette.pebbleDark)
    ..drawPath(light, Paint()..color = Palette.pebbleLight)
    ..drawPath(shine, Paint()..color = Colors.white.withValues(alpha: 0.25));
}
