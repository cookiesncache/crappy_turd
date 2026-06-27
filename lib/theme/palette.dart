import 'package:flutter/material.dart';

/// Central colour palette for Crappy Turd's cute, glossy art direction.
abstract final class Palette {
  // Sky (bright and cheerful).
  static const Color skyTop = Color(0xFF74C7F2);
  static const Color skyBottom = Color(0xFFC8EEFB);

  // Rainbow bands (outer red -> inner violet).
  static const List<Color> rainbow = [
    Color(0xFFFF6B6B),
    Color(0xFFFFA94D),
    Color(0xFFFFD43B),
    Color(0xFF69DB7C),
    Color(0xFF4DABF7),
    Color(0xFF748FFC),
    Color(0xFFB197FC),
  ];

  // Ground.
  static const Color ground = Color(0xFF93DC82);
  static const Color groundShadow = Color(0xFF6FBF63);

  // Turd body (top -> bottom, used for the soft-serve gradient).
  static const Color turdLight = Color(0xFFB07A50);
  static const Color turdMid = Color(0xFF8C5A35);
  static const Color turdDark = Color(0xFF6E4426);

  // Face.
  static const Color eyeWhite = Color(0xFFFFFFFF);
  static const Color pupil = Color(0xFF2B2B2B);
  static const Color cheek = Color(0x33FF6B81);
  static const Color mouth = Color(0xFF4A2C18);

  // Misc.
  static const Color shadow = Color(0x33000000);
}
