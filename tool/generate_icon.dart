// This is a standalone build-time console script (not app code shipped to
// players), so printing progress straight to stdout is the intended UX.
// ignore_for_file: avoid_print
/// One-off build tool that procedurally renders Crappy Turd's app icon
/// source images by invoking the game's OWN existing [paintTurd] mascot
/// artwork (see `lib/render/turd_painter.dart`) -- the exact same painter
/// that draws the turd every frame in the live game -- onto a couple of
/// large offscreen canvases. No external image, no AI-generated art, no
/// downloaded/licensed asset: every pixel comes from code already in this
/// repo, mirroring the spirit of `tool/generate_audio.dart` (which
/// hand-assembles WAV files instead of sourcing external audio).
///
/// This writes two PNGs under `assets/icon/`:
///   * `icon.png` -- a full-bleed background fill (a colour lifted straight
///     from [Palette]) with the turd centred and sized to fill most of the
///     canvas. Used as the master image for the app's regular icon on every
///     platform (iOS, Windows, macOS, web, and Android's non-adaptive
///     fallback).
///   * `icon_foreground.png` -- the SAME turd artwork, smaller and on a
///     fully transparent background. Android adaptive icons crop/mask/
///     parallax the foreground layer aggressively, so this needs generous
///     padding beyond what `icon.png` uses or the OS's mask shapes (circle,
///     squircle, etc.) will clip the mascot.
///
/// These two PNGs are themselves only an intermediate step: the committed
/// per-platform icon/splash files are generated FROM them by the
/// `flutter_launcher_icons` / `flutter_native_splash` dev-tools (see the
/// `flutter_launcher_icons:`/`flutter_native_splash:` blocks in
/// `pubspec.yaml`), run separately as documented there.
///
/// ---------------------------------------------------------------------
/// IMPORTANT -- how to run this file: `flutter test tool/generate_icon.dart`
/// ---------------------------------------------------------------------
/// Unlike `tool/generate_audio.dart` (which only needs `dart:io` and
/// `dart:typed_data` and so runs under plain `dart run`), this script calls
/// [paintTurd], which draws through `dart:ui`'s real `Canvas`/
/// `PictureRecorder`/`Image` -- engine-backed types that a bare `dart run`
/// process has no access to. `flutter test` DOES provide that engine
/// access (this project's own `test/day_night_test.dart` and
/// `test/star_field_test.dart` already rely on `dart:ui` types running fine
/// under it), which is why this script is structured as a `flutter_test`
/// `test()` block even though it asserts nothing and generates files rather
/// than checking behaviour -- the `test()` wrapper here is purely a vehicle
/// to get engine access, not a real test. `Image.toByteData(format:
/// ui.ImageByteFormat.png)`, used below to encode the PNGs, is the exact
/// mechanism Flutter's own `matchesGoldenFile()` uses internally, so this
/// is a proven, standard capability of the `flutter test` environment.
///
/// Running it with plain `dart run tool/generate_icon.dart` will fail (no
/// `dart:ui` engine available outside `flutter test`/a running Flutter app).
/// Re-run this script by hand whenever [paintTurd] or the tunable sizing
/// constants below change, to regenerate the committed PNGs.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crappy_turd/render/turd_painter.dart';
import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter_test/flutter_test.dart';

/// Square resolution (px) of both master PNGs. 1024 is the conventional
/// "master" icon size platform tools downscale from (it exactly matches,
/// for instance, iOS's largest required App Store icon slot).
const double canvasSize = 1024;

/// [paintTurd]'s `size` argument for `icon.png`, chosen so the mascot fills
/// most of the canvas with modest padding around it. [paintTurd]'s doc
/// comment notes the painted artwork's overall height comes out to
/// "roughly" its `size` argument (in practice a little taller, since the
/// silhouette's topmost/bottommost scoops extend slightly past the nominal
/// bounds) -- 82% of the canvas here lands the actual painted height at
/// roughly 85-90% of the frame, i.e. filling it generously without kissing
/// the edges.
const double iconTurdSize = canvasSize * 0.82;

/// [paintTurd]'s `size` argument for `icon_foreground.png`. Deliberately
/// much smaller than [iconTurdSize]: Android adaptive icons composite this
/// layer under a system-chosen mask (circle, squircle, rounded-square, ...)
/// that crops well inside the full canvas, and some launchers also apply a
/// parallax offset between foreground and background on home-screen
/// scroll. Sizing the turd down to roughly 60-65% of the frame (rather
/// than [iconTurdSize]'s ~85-90%) leaves enough breathing room that it
/// survives any of those masks/parallax without clipping the mascot.
const double foregroundTurdSize = canvasSize * 0.58;

/// Background fill for `icon.png`, lifted straight from the game's own sky
/// palette rather than inventing a new colour for this -- a bright,
/// cheerful blue that reads well as an icon backdrop and instantly
/// associates with the in-game sky.
const ui.Color backgroundColor = Palette.skyTop;

void main() {
  test('generate icon', () async {
    final iconBytes = await _renderTurdPng(
      turdSize: iconTurdSize,
      background: backgroundColor,
    );
    final foregroundBytes = await _renderTurdPng(turdSize: foregroundTurdSize);

    final dir = Directory('assets/icon');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    File('assets/icon/icon.png').writeAsBytesSync(iconBytes);
    File(
      'assets/icon/icon_foreground.png',
    ).writeAsBytesSync(foregroundBytes);

    print(
      'Wrote assets/icon/icon.png (${iconBytes.length} bytes) and '
      'assets/icon/icon_foreground.png (${foregroundBytes.length} bytes)',
    );

    // Sanity checks, not real assertions: a blank/broken render (e.g. a
    // canvas that silently failed to paint anything) would come out as a
    // suspiciously tiny, near-empty PNG. These thresholds are comfortably
    // below what either real render produces, just high enough to catch a
    // truly broken/empty image.
    expect(iconBytes.length, greaterThan(5000));
    expect(foregroundBytes.length, greaterThan(2000));
  });
}

/// Renders [paintTurd] at [turdSize], centred on a [canvasSize] x
/// [canvasSize] square canvas, optionally preceded by a full-bleed
/// [background] fill (left `null` for a fully transparent canvas), and
/// returns the result PNG-encoded.
Future<Uint8List> _renderTurdPng({
  required double turdSize,
  ui.Color? background,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(
    recorder,
    const ui.Rect.fromLTWH(0, 0, canvasSize, canvasSize),
  );

  if (background != null) {
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, canvasSize, canvasSize),
      ui.Paint()..color = background,
    );
  }

  // paintTurd expects to be called with the canvas already translated so
  // its local (0, 0) origin sits at the artwork's centre -- exactly what
  // the live game does each frame before calling it. The icon canvas is
  // square (canvasSize x canvasSize), so passing turdSize for both the
  // width and height scale renders the same undistorted mascot as before
  // paintTurd's two scale axes were decoupled.
  canvas.translate(canvasSize / 2, canvasSize / 2);
  paintTurd(canvas, turdSize, turdSize);

  final picture = recorder.endRecording();
  final image = await picture.toImage(canvasSize.round(), canvasSize.round());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Failed to PNG-encode the rendered icon image.');
  }
  return byteData.buffer.asUint8List();
}
