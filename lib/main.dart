import 'dart:async';

import 'package:crappy_turd/game/collision.dart';
import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/game_status.dart';
import 'package:crappy_turd/game/pipe_field.dart';
import 'package:crappy_turd/game/scoring.dart';
import 'package:crappy_turd/models/turd.dart';
import 'package:crappy_turd/render/game_painter.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

void main() {
  runApp(const CrappyTurdApp());
}

/// Root of the Crappy Turd game.
class CrappyTurdApp extends StatelessWidget {
  const CrappyTurdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crappy Turd',
      home: GameScreen(),
    );
  }
}

/// Hosts the game: a [Ticker]-driven loop always runs — hovering the turd
/// on the title screen, then applying gravity and scrolling pipes once play
/// starts — and a tap makes it flap. The same [GamePainter] draws the scene
/// throughout, so the title-to-gameplay handoff has no visual cut. A hit
/// pipe or the ground ends the run (see [checkCollision]) and freezes the
/// scene until the next tap restarts it, showing both the run's score and
/// the best score seen so far this session.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final Turd _turd = Turd();
  final PipeField _pipeField = PipeField();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  GameStatus _status = GameStatus.title;

  /// The current run's live score (pipes passed since the last restart).
  int _score = 0;

  /// The best score seen so far this session. In-memory only -- persisting
  /// it across app restarts is a later milestone.
  int _best = 0;

  /// The real pixel size of the game canvas, refreshed on every [build] so
  /// collision detection (which needs actual pixel geometry, not just
  /// fractions) always has an up-to-date value.
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    unawaited(_ticker.start());
  }

  void _onTick(Duration elapsed) {
    final dt =
        (elapsed - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = elapsed;
    // Skip the first frame and any large hitches so the physics stays stable.
    if (dt <= 0 || dt > 0.1) return;
    setState(() {
      switch (_status) {
        case GameStatus.title:
          final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
          _turd.hover(t);
        case GameStatus.playing:
          _turd.update(dt);
          _pipeField.update(dt);
          // Scoring and dying are independent per-frame events; tally any
          // pipes the turd has newly flown past before checking whether
          // this frame is also the one where it dies.
          _score += countPipesPassed(_pipeField.pipes);
          // Guards the impossible-in-practice case of a tick firing before
          // the first build/layout has ever run — the player can't reach
          // `playing` before at least one build (a tap is required first),
          // so this should never actually skip a real check.
          if (_size != Size.zero &&
              checkCollision(_turd, _pipeField.pipes, _size)) {
            _status = GameStatus.gameOver;
            if (_score > _best) {
              _best = _score;
            }
          }
        case GameStatus.gameOver:
        // Frozen: no physics or pipe movement until the player taps to
        // restart.
      }
    });
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      if (_status == GameStatus.gameOver) {
        _turd.reset();
        _pipeField.reset();
        // The best score is NOT reset here -- it persists for the lifetime
        // of the running app, across as many runs as the player takes.
        _score = 0;
      }
      _status = GameStatus.playing;
      _turd.flap();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Picks the overlay widget for the current [_status].
  ///
  /// Each branch carries its own explicit, distinct [ValueKey]. This
  /// matters because [AnimatedSwitcher] decides whether to animate a
  /// transition (fading the old child out and the new one in) by comparing
  /// the incoming child against the outgoing one via `Widget.canUpdate`,
  /// which is true only when both the `runtimeType` AND the `key` match.
  /// The three branches already return different widget types today, so
  /// distinct keys aren't strictly load-bearing yet -- but spelling them
  /// out makes that intent explicit and keeps this robust against a future
  /// change (e.g. two statuses sharing a widget type) silently breaking the
  /// cross-fade instead of relying on an incidental type difference.
  Widget _overlayForStatus() {
    return switch (_status) {
      GameStatus.title => _TitleOverlay(
        key: const ValueKey('title'),
        best: _best,
      ),
      GameStatus.playing => const SizedBox.shrink(key: ValueKey('playing')),
      GameStatus.gameOver => _GameOverPanel(
        key: const ValueKey('gameOver'),
        score: _score,
        best: _best,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: GestureDetector(
        onTapDown: _onTapDown,
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: GamePainter(turd: _turd, pipes: _pipeField.pipes),
            ),
            IgnorePointer(
              child: AnimatedSwitcher(
                duration: GameConstants.overlayFadeDuration,
                child: _overlayForStatus(),
              ),
            ),
            if (_status == GameStatus.playing)
              _ScoreHud(key: const ValueKey('scoreHud'), score: _score),
          ],
        ),
      ),
    );
  }
}

/// The idle title card: a bold game title plus a gently pulsing hint,
/// shown until the first tap and then faded away by [_GameScreenState].
/// Also shows a "Best: N" line beneath the hint, but only once a run has
/// actually ended at least once this session ([best] > 0) -- a fresh app
/// launch shouldn't advertise "Best: 0".
class _TitleOverlay extends StatefulWidget {
  const _TitleOverlay({required this.best, super.key});

  final int best;

  @override
  State<_TitleOverlay> createState() => _TitleOverlayState();
}

class _TitleOverlayState extends State<_TitleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_pulse.repeat(reverse: true));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.62),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Crappy Turd',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: Palette.turdDark,
              shadows: [
                Shadow(color: Colors.white, blurRadius: 4),
                Shadow(color: Colors.white, blurRadius: 12),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: Tween<double>(begin: 0.4, end: 1).animate(_pulse),
            child: const Text(
              'Tap to start',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Palette.turdMid,
              ),
            ),
          ),
          if (widget.best > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Best: ${widget.best}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Palette.turdMid,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The game-over card: a rounded, semi-opaque panel showing a "Game Over"
/// heading, this run's [score], the session [best], and a "Tap to restart"
/// hint. Shown once the run ends and faded out again by [_GameScreenState]
/// on restart.
///
/// The panel's own background (see [Palette.panelBackground]) reads clearly
/// over the busy frozen scene behind it, so unlike the earlier text-only
/// overlay it doesn't need to hunt for screen real estate that's guaranteed
/// clear -- a conventional centred placement is fine.
class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({required this.score, required this.best, super.key});

  final int score;
  final int best;

  @override
  Widget build(BuildContext context) {
    // A tied-or-beaten record is only worth celebrating once a run has
    // actually scored -- guards against `score == best == 0` (nothing
    // played yet) reading as a "new best".
    final isNewBest = score >= best && score > 0;

    return Align(
      alignment: const Alignment(0, -0.1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.panelBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Palette.shadow,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Game Over',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                  shadows: [
                    Shadow(color: Colors.white, blurRadius: 4),
                    Shadow(color: Colors.white, blurRadius: 12),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Score: $score',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Palette.turdDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isNewBest ? 'New Best: $best!' : 'Best: $best',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isNewBest ? Palette.gold : Palette.turdDark,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tap to restart',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Palette.turdMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The always-mounted live score readout, shown near the top of the screen
/// only while [GameStatus.playing] is active. Not part of the
/// [AnimatedSwitcher] overlay stack -- it needs to track the live [score]
/// every frame, not cross-fade between discrete states.
class _ScoreHud extends StatelessWidget {
  const _ScoreHud({required this.score, super.key});

  final int score;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.92),
        child: Text(
          '$score',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(color: Palette.turdDark, blurRadius: 4),
              Shadow(color: Palette.turdDark, blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}
