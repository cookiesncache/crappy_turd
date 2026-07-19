/// A single point-in-time snapshot of the turd's vertical position and
/// tilt, used by `lib/game/trail_field.dart` to paint a fading
/// motion-trail ghost behind it. Pure value type: no behaviour beyond
/// aging.
class TrailSample {
  TrailSample({required this.y, required this.tilt});

  /// The turd's `y` at the moment this sample was taken (fraction of
  /// screen height).
  final double y;

  /// The turd's tilt (radians) at the moment this sample was taken.
  final double tilt;

  /// Seconds elapsed since this sample was taken.
  double age = 0;
}
