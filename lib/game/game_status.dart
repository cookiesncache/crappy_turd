/// The high-level state of a play session.
enum GameStatus {
  /// Idle title screen: the turd hovers in place, waiting for the first tap.
  title,

  /// The player is actively flying; gravity and flaps are live.
  playing,

  /// The turd has hit a pipe or the ground; the run has ended and is
  /// awaiting a tap to restart.
  gameOver,
}
