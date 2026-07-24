/// A single twinkling background star: pure ambient decoration in the
/// night sky, with no gameplay effect whatsoever. Everything about a star
/// is fixed at spawn -- unlike `Cloud`, a star neither drifts nor loops,
/// and unlike `Particle`/`ShootingStar` it never ages or dies either; the
/// star FIELD itself is generated once and never respawns individual stars
/// (see `lib/game/star_field.dart`). What reads as "twinkling" comes
/// entirely from `lib/render/star_painter.dart` modulating brightness over
/// time using [twinklePhase]/[twinkleSpeed], not from any per-frame change
/// to the star's own state.
class Star {
  const Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinklePhase,
    required this.twinkleSpeed,
  });

  /// Horizontal position, fraction of screen width. Fixed at spawn.
  final double x;

  /// Vertical position, fraction of screen height. Fixed at spawn -- see
  /// `GameConstants.starMinY`/`GameConstants.starMaxY` for the band stars
  /// are scattered across (the upper sky, mostly above/around where the
  /// rainbow's arcs sit).
  final double y;

  /// A small render-size hint (interpreted by
  /// `lib/render/star_painter.dart` as a fraction of screen width), drawn
  /// from `GameConstants.starMinSize`/`GameConstants.starMaxSize`. Fixed at
  /// spawn.
  final double size;

  /// A fixed per-star phase offset (radians), added inside the twinkle
  /// sine wave so a whole field of stars don't all brighten/dim in
  /// lockstep. Fixed at spawn.
  final double twinklePhase;

  /// A fixed per-star angular speed (radians per second) driving how fast
  /// this star's own twinkle oscillates, drawn from
  /// `GameConstants.starTwinkleSpeedMin`/`GameConstants.starTwinkleSpeedMax`.
  /// Fixed at spawn.
  final double twinkleSpeed;
}
