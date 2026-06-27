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

/// Hosts the game. For now it shows a placeholder; the real
/// CustomPainter-driven game world arrives in milestone M1.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF9BD7F0),
      body: Center(
        child: Text(
          'Crappy Turd\nscaffold ready',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
