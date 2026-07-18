import 'dart:math' as math;

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/models/pipe.dart';

/// Owns the live list of pipes and the spawn timer: advances and culls
/// pipes each frame, and spawns new ones on a fixed interval. Pure Dart, no
/// widget/ticker dependency, so it's unit-testable exactly like the turd
/// model.
class PipeField {
  PipeField([math.Random? random]) : _random = random ?? math.Random();

  final math.Random _random;

  /// Live pipes, ordered oldest (leftmost) first.
  final List<Pipe> pipes = [];

  double _spawnTimer = 0;

  /// Advance all pipes by [dt] seconds, cull offscreen ones, and spawn new
  /// pipes as the spawn timer crosses [GameConstants.spawnInterval].
  void update(double dt) {
    for (final p in pipes) {
      p.update(dt);
    }
    pipes.removeWhere((p) => p.isOffscreen);

    _spawnTimer += dt;
    while (_spawnTimer >= GameConstants.spawnInterval) {
      _spawnTimer -= GameConstants.spawnInterval;
      // Advance the new pipe by the time elapsed since its spawn instant
      // within this frame, so pipes spawned in the same update() call (a
      // long dt) land at distinct, correctly staggered positions instead
      // of overlapping at pipeSpawnX.
      final pipe = Pipe.spawn(_random)..update(_spawnTimer);
      pipes.add(pipe);
    }
  }

  /// Clear all pipes and reset the spawn timer.
  void reset() {
    pipes.clear();
    _spawnTimer = 0;
  }
}
