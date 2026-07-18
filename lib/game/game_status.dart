/// The high-level state of a play session.
enum GameStatus {
  /// Idle title screen: the turd hovers in place, waiting for the first tap.
  title,

  /// The player is actively flying; gravity and flaps are live.
  playing,
}
