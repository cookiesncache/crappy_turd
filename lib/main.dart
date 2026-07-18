import 'dart:async';

import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/game_status.dart';
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
/// on the title screen, then applying gravity once play starts — and a tap
/// makes it flap. The same [GamePainter] draws the scene throughout, so the
/// title-to-gameplay handoff has no visual cut. Pipes, collision, and
/// scoring arrive in later milestones.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final Turd _turd = Turd();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  GameStatus _status = GameStatus.title;

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
      if (_status == GameStatus.title) {
        final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
        _turd.hover(t);
      } else {
        _turd.update(dt);
      }
    });
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _status = GameStatus.playing;
      _turd.flap();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: _onTapDown,
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: GamePainter(turd: _turd),
            ),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _status == GameStatus.title ? 1 : 0,
                duration: GameConstants.titleFadeDuration,
                child: const _TitleOverlay(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The idle title card: a bold game title plus a gently pulsing hint,
/// shown until the first tap and then faded away by [_GameScreenState].
class _TitleOverlay extends StatefulWidget {
  const _TitleOverlay();

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
        ],
      ),
    );
  }
}
