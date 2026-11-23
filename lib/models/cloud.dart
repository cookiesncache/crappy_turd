import 'package:crappy_turd/game/constants.dart';

/// One round "puff" of a [Cloud]'s shape, relative to the cloud's centre.
/// All three values are in units of the cloud's radius (half its width),
/// so a cloud's shape stays the same as its size changes.
class CloudPuff {
  const CloudPuff(this.dx, this.dy, this.radius);

  /// Horizontal offset from the cloud's centre (positive is right).
  final double dx;

  /// Vertical offset from the cloud's centre (positive is down).
  final double dy;

  /// The puff's radius.
  final double radius;
}

/// A single drifting background cloud: pure ambient decoration, no
/// gameplay effect whatsoever. [x] is mutable (fraction of screen width,
/// drifts left every frame); [y] (fraction of screen height), [scale] (a
/// size-variation multiplier) and [puffs] (its shape) are fixed at spawn.
class Cloud {
  Cloud({
    required this.x,
    required this.y,
    required this.scale,
    this.puffs = defaultPuffs,
  });

  /// A plain four-puff shape, for clouds created without a randomised one
  /// (see `CloudField`, which gives every cloud its own).
  static const List<CloudPuff> defaultPuffs = [
    CloudPuff(-0.6, 0.15, 0.55),
    CloudPuff(0, -0.1, 0.7),
    CloudPuff(0.65, 0.1, 0.5),
    CloudPuff(0.1, 0.25, 0.45),
  ];

  /// Horizontal position, fraction of screen width.
  double x;

  /// Vertical position, fraction of screen height. Fixed at spawn -- clouds
  /// drift horizontally only, never vertically.
  final double y;

  /// Size-variation multiplier so clouds don't all look identical (see
  /// `lib/render/cloud_painter.dart`).
  final double scale;

  /// The overlapping puffs that make up this cloud's silhouette. Kept
  /// within about 1.15 cloud-radii of the centre horizontally, which
  /// [isOffscreen] and `CloudField`'s wrap point rely on.
  final List<CloudPuff> puffs;

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
