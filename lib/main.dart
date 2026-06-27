import 'package:crappy_turd/render/game_painter.dart';
import 'package:flutter/material.dart';

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

/// Hosts the game. For M1 it statically paints the world (sky, ground, turd);
/// the game loop and tap-to-flap interaction arrive in M2.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CustomPaint(
        size: Size.infinite,
        painter: GamePainter(),
      ),
    );
  }
}
