import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/bunny.dart';
import 'package:crappy_turd/render/ground_painter.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Paints every live bunny on the grass: a round, fluffy little rabbit in
/// three-quarter view with long ears, a cotton tail, happy closed eyes,
/// rosy cheeks and a tiny smile, plus a soft shadow on the grass that
/// shrinks as it hops up.
void paintBunnies(Canvas canvas, Size size, List<Bunny> bunnies) {
  final feetY = grassFootY(size);
  for (final bunny in bunnies) {
    _paintBunny(canvas, size, bunny, feetY);
  }
}

void _paintBunny(Canvas canvas, Size size, Bunny bunny, double feetY) {
  // u: the bunny's height in pixels; every part below is in units of u,
  // drawn facing right with the feet at the origin (y up is negative).
  final u = GameConstants.bunnySize * size.height * bunny.scale;
  final x = bunny.x * size.height;
  final lift = bunny.lift * size.height;

  // Shadow on the grass, smaller and fainter the higher it hops.
  final airFactor = 1 - (lift / (u * 0.9)).clamp(0.0, 0.6);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(x, feetY + u * 0.02),
      width: u * 0.75 * airFactor,
      height: u * 0.14 * airFactor,
    ),
    Paint()..color = Colors.black.withValues(alpha: 0.16 * airFactor),
  );

  final stretch = bunny.stretch;
  canvas
    ..save()
    ..translate(x, feetY - lift)
    ..scale(bunny.facing * u * (2 - stretch), u * stretch);

  final coat = Palette.bunnyCoats[bunny.coat];
  final shade = Palette.bunnyCoatShades[bunny.coat];
  final outline = Paint()
    ..color = Palette.bunnyOutline
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05
    ..strokeJoin = StrokeJoin.round;
  final coatPaint = Paint()..color = coat;
  final innerEar = Paint()..color = Palette.bunnyInnerEar;
  // Ears sweep back while it's in the air.
  final earSweep = bunny.airborne ? -0.3 : 0.0;

  // Both ears rise from behind the head (drawn before it, so the head
  // covers their roots), in the same coat colour.
  _paintEar(
    canvas,
    const Offset(0.08, -0.7),
    -0.35 + earSweep,
    outline,
    coatPaint,
    innerEar,
  );
  _paintEar(
    canvas,
    const Offset(0.21, -0.73),
    0.05 + earSweep,
    outline,
    coatPaint,
    innerEar,
  );

  // Body parts, outlines first so each fill covers the inner outline
  // strokes and only the outer silhouette stays outlined.
  final backFoot = Rect.fromCenter(
    center: const Offset(-0.12, -0.05),
    width: 0.36,
    height: 0.12,
  );
  final body = Rect.fromCenter(
    center: const Offset(-0.05, -0.27),
    width: 0.62,
    height: 0.48,
  );
  final tail = Rect.fromCircle(
    center: const Offset(-0.36, -0.3),
    radius: 0.09,
  );
  final head = Rect.fromCircle(
    center: const Offset(0.17, -0.55),
    radius: 0.23,
  );
  final frontFoot = Rect.fromCenter(
    center: const Offset(0.14, -0.04),
    width: 0.16,
    height: 0.09,
  );
  for (final part in [backFoot, body, tail, head, frontFoot]) {
    canvas.drawOval(part, outline);
  }
  canvas
    ..drawOval(backFoot, Paint()..color = shade)
    ..drawOval(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [coat, coat, shade],
          stops: const [0, 0.45, 1],
        ).createShader(body),
    )
    ..drawOval(tail, Paint()..color = Color.lerp(coat, Colors.white, 0.6)!)
    ..drawOval(head, coatPaint)
    ..drawOval(frontFoot, coatPaint);

  // Face: rosy cheeks, happy closed "^ ^" eyes, a pink nose, a tiny smile.
  final cheek = Paint()..color = Palette.bunnyNose.withValues(alpha: 0.35);
  canvas
    ..drawCircle(const Offset(0.09, -0.48), 0.04, cheek)
    ..drawCircle(const Offset(0.33, -0.48), 0.035, cheek);
  final face = Paint()
    ..color = Palette.bunnyFace
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.028
    ..strokeCap = StrokeCap.round;
  for (final eye in const [Offset(0.12, -0.58), Offset(0.29, -0.58)]) {
    canvas.drawPath(
      Path()
        ..moveTo(eye.dx - 0.04, eye.dy + 0.012)
        ..quadraticBezierTo(
          eye.dx,
          eye.dy - 0.04,
          eye.dx + 0.04,
          eye.dy + 0.012,
        ),
      face,
    );
  }
  canvas
    ..drawOval(
      Rect.fromCenter(
        center: const Offset(0.225, -0.5),
        width: 0.055,
        height: 0.04,
      ),
      Paint()..color = Palette.bunnyNose,
    )
    ..drawPath(
      Path()
        ..moveTo(0.185, -0.465)
        ..quadraticBezierTo(0.205, -0.44, 0.225, -0.465)
        ..quadraticBezierTo(0.245, -0.44, 0.265, -0.465),
      face..strokeWidth = 0.02,
    )
    ..restore();
}

/// One long ear rooted at [base] and tipped back by [angle] radians from
/// straight up, with a pink inside.
void _paintEar(
  Canvas canvas,
  Offset base,
  double angle,
  Paint outline,
  Paint fill,
  Paint inner,
) {
  const length = 0.42;
  const width = 0.13;
  final ear = Rect.fromCenter(
    center: const Offset(0, -length / 2),
    width: width,
    height: length,
  );
  final inside = Rect.fromCenter(
    center: const Offset(0, -length / 2 - 0.01),
    width: width * 0.5,
    height: length * 0.72,
  );
  canvas
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(angle)
    ..drawOval(ear, outline)
    ..drawOval(ear, fill)
    ..drawOval(inside, inner)
    ..restore();
}
