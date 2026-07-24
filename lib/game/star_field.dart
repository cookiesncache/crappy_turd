import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/star.dart';

/// Owns the fixed set of background stars. Purely ambient and, unlike
/// `CloudField`, entirely static once generated: individual stars never
/// move, respawn, or get replaced, so there is no per-frame `update()` at
/// all here -- only the painter (`lib/render/star_painter.dart`) needs
/// per-frame inputs (the current play time, for twinkle phase, and the
/// current day/night amount, for overall visibility), and both of those
/// are already tracked/computed elsewhere in `main.dart`. Like `CloudField`,
/// [stars] is never reset on restart -- this is a session-long ambient
/// field, not tied to any single run.
class StarField {
  /// An optional [random] can be supplied so tests get deterministic star
  /// placement; defaults to a fresh [math.Random].
  StarField([math.Random? random]) : _random = random ?? math.Random() {
    for (var i = 0; i < GameConstants.starCount; i++) {
      stars.add(_spawn());
    }
  }

  final math.Random _random;

  /// Live stars, always exactly [GameConstants.starCount] long -- generated
  /// once at construction and never mutated afterward.
  final List<Star> stars = [];

  Star _spawn() {
    return Star(
      x: _random.nextDouble(),
      y:
          GameConstants.starMinY +
          _random.nextDouble() *
              (GameConstants.starMaxY - GameConstants.starMinY),
      size:
          GameConstants.starMinSize +
          _random.nextDouble() *
              (GameConstants.starMaxSize - GameConstants.starMinSize),
      twinklePhase: _random.nextDouble() * 2 * math.pi,
      twinkleSpeed:
          GameConstants.starTwinkleSpeedMin +
          _random.nextDouble() *
              (GameConstants.starTwinkleSpeedMax -
                  GameConstants.starTwinkleSpeedMin),
    );
  }
}
