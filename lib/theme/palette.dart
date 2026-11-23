import 'package:flutter/material.dart';

/// Central colour palette for Crappy Turd's cute, glossy art direction.
abstract final class Palette {
  // Sky (bright and cheerful).
  static const Color skyTop = Color(0xFF74C7F2);
  static const Color skyBottom = Color(0xFFC8EEFB);

  // Night sky -- a run gradually shifts toward these and back again on a
  // repeating loop (see GameConstants.dayNightCycleDuration and
  // lib/game/day_night.dart), a soft twilight indigo rather than a scary
  // black, keeping the same "lighter toward the horizon" gradient shape as
  // the day sky above.
  static const Color nightSkyTop = Color(0xFF1A2A5E);
  static const Color nightSkyBottom = Color(0xFF4A5FA0);

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

  // Ground: a striped grass band (with blades along its top edge and a
  // scalloped lip) over warm, pebbly soil.
  static const Color ground = Color(0xFF93DC82);
  static const Color groundShadow = Color(0xFF6FBF63);
  static const Color groundStripe = Color(0xFF86D175);
  static const Color groundHighlight = Color(0xFFB4EBA4);
  static const Color soilTop = Color(0xFFEBCB97);
  static const Color soilBottom = Color(0xFFD9AE73);
  static const Color pebbleDark = Color(0xFFC99A5E);
  static const Color pebbleLight = Color(0xFFF5E2BF);

  // Little flowers dotted through the grass.
  static const List<Color> flowerPetals = [
    Color(0xFFFF9EC4), // pink
    Color(0xFFFFE066), // butter yellow
    Color(0xFFFFFFFF), // white
    Color(0xFFC9A7FF), // lavender
  ];
  static const Color flowerCenter = Color(0xFFFFB238);
  static const Color flowerStem = Color(0xFF4E9F45);

  // Happy bunnies hopping along the grass: three coat colours, each with
  // a darker shade for its underside and outline.
  static const List<Color> bunnyCoats = [
    Color(0xFFFFFBF5), // snow white
    Color(0xFFEBD3B8), // fawn
    Color(0xFFDCDCE4), // dove grey
  ];
  static const List<Color> bunnyCoatShades = [
    Color(0xFFE8DED3),
    Color(0xFFD4B794),
    Color(0xFFC2C2CE),
  ];
  static const Color bunnyOutline = Color(0xFF9C8B7C);
  static const Color bunnyInnerEar = Color(0xFFFFC4D0);
  static const Color bunnyNose = Color(0xFFFF8FA8);
  static const Color bunnyFace = Color(0xFF5A4636);

  // Pipes (friendly, non-scary green, harmonising with the ground), shaded
  // across their width so they read as rounded.
  static const Color pipeGreen = Color(0xFF6FCF6B);
  static const Color pipeGreenLight = Color(0xFFA8EC9F);
  static const Color pipeGreenDark = Color(0xFF4A9E48);
  static const Color pipeOutline = Color(0xFF3B7F3A);

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

  // Overlay panels (e.g. the game-over card) -- a soft, semi-opaque cream
  // that reads clearly over the busy pipes/rainbow/ground scene without
  // looking harsh or out of step with the rest of the pastel palette.
  static const Color panelBackground = Color(0xF2FFF8EC);

  // Accent used to celebrate a new/tied best score on the game-over panel.
  static const Color gold = Color(0xFFE8A93B);

  // Background parallax clouds: sunlit white tops fading to a soft
  // blue-grey underside by day, and a dimmer moonlit slate by night (see
  // lib/render/cloud_painter.dart).
  static const Color cloudTop = Color(0xF2FFFFFF);
  static const Color cloudShade = Color(0xE6C9DAEB);
  static const Color cloudHighlight = Color(0xCCFFFFFF);
  static const Color cloudNightTop = Color(0xB38C9CCB);
  static const Color cloudNightShade = Color(0x99566596);
  static const Color cloudNightHighlight = Color(0x40B8C4EA);

  // Bright twinkle tones for the flap "sparkle" particle burst -- warm
  // gold and pale white-gold, alternated per-particle for a glinting look.
  static const Color sparkleWhite = Color(0xFFFFF9E6);

  // A soft, pale, faintly-blue white used for both the twinkling
  // background stars and shooting-star streaks (see lib/models/star.dart,
  // lib/models/shooting_star.dart) -- bright enough to read clearly
  // against the indigo night sky without looking harsh.
  static const Color star = Color(0xFFF0F4FF);
}
