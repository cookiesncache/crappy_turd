import 'package:crappy_turd/game/constants.dart';

/// A single drifting background cloud: pure ambient decoration, no
/// gameplay effect whatsoever. [x] is mutable (fraction of screen width,
/// drifts left every frame); [y] (fraction of screen height) and [scale]
/// (a size-variation multiplier) are fixed at spawn.
class Cloud {
  Cloud({required this.x, required this.y, required this.scale});

  /// Horizontal position, fraction of screen width.
  double x;

  /// Vertical position, fraction of screen height. Fixed at spawn -- clouds
  /// drift horizontally only, never vertically.
  final double y;

  /// Size-variation multiplier so clouds don't all look identical (see
  /// `lib/render/cloud_painter.dart`).
  final double scale;

  /// True once the cloud has fully drifted past the left edge, accounting
  /// for its own (scaled) width -- mirrors `Pipe.isOffscreen`'s
  /// style/threshold reasoning, sized generously so a cloud fully clears
  /// the screen before it gets wrapped back around (see
  /// `lib/game/cloud_field.dart`).
  bool get isOffscreen => x < -GameConstants.cloudWidth * scale;

  /// Advance the cloud by [dt] seconds.
  void update(double dt) {
    x -= GameConstants.cloudSpeed * dt;
  }
}
