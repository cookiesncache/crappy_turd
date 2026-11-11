// This is a standalone build-time console script (not app code shipped to
// players), so printing progress straight to stdout is the intended UX.
// ignore_for_file: avoid_print
/// One-off build tool that renders Play Store marketing screenshots by
/// pumping the game's OWN real [GameScreen] widget (see `lib/main.dart`)
/// under `flutter_test` and capturing it via a [RepaintBoundary] -- the
/// exact same technique Flutter's own `matchesGoldenFile()` uses internally
/// (see `tool/generate_icon.dart` for the sibling script that renders raw
/// painter output the same way). This sidesteps a rendering glitch specific
/// to running the app under `flutter run -d web-server` at a custom
/// viewport size, and produces genuinely faithful screenshots since it's
/// the real widget tree, title overlay and all -- not a hand-drawn
/// approximation of it.
///
/// Two screenshots are generated:
///   * `title.png` -- the idle title screen (default random cloud/turd
///     state, no pipeField override needed).
///   * `gameplay.png` -- an in-flight shot. Flying the turd through a real
///     randomly-placed gap turns out to be fragile to script even with a
///     single static frame to aim for (see `test/score_persistence_test.dart`'s
///     comment on this exact difficulty), so this takes the same approach
///     that test uses: inject pipes directly into a seeded [PipeField]
///     rather than relying on live taps to thread a gap by chance. A few
///     already-"passed" pipes (fast-forwarded via their own real
///     [Pipe.update], mirroring `score_persistence_test.dart`) bump the
///     score HUD to a modest, honest-looking non-zero number, and one
///     pipe is placed with its gap manually aligned to the turd's expected
///     on-screen position at capture time.
///
/// ---------------------------------------------------------------------
/// IMPORTANT -- how to run this file: `flutter test tool/generate_screenshots.dart`
/// ---------------------------------------------------------------------
/// Needs `flutter_test`'s widget-testing/engine access, same reason as
/// `tool/generate_icon.dart` -- plain `dart run` has no `dart:ui` engine.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crappy_turd/game/collision.dart';
import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/pipe_field.dart';
import 'package:crappy_turd/main.dart';
import 'package:crappy_turd/models/pipe.dart';
import 'package:crappy_turd/models/turd.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

/// Play Store phone screenshot resolution: a standard 16:9-ish portrait
/// size comfortably within Play Console's accepted dimension/ratio range.
const Size screenshotSize = Size(1080, 1920);

/// `flutter_test`'s widget binding has no real fonts loaded by default, so
/// text (the title, "Tap to start", the score HUD) and the mute icon render
/// as solid placeholder boxes instead of real glyphs -- a well-known
/// golden-screenshot gotcha, unrelated to anything in the app itself.
/// Loads the SAME font files a real Flutter build already bundles (from the
/// Flutter SDK's own cache, `bin/cache/artifacts/material_fonts/`) under
/// the family names the app's widgets actually reference -- "Roboto"
/// (MaterialApp's default text theme, since none of this app's TextStyles
/// set an explicit fontFamily) and "MaterialIcons" (what every `Icons.*`
/// constant resolves to, needed for the mute button). Using the SDK's own
/// bundled fonts rather than a substitute keeps this pixel-faithful to a
/// real build, in the same "no extra external asset" spirit as
/// `tool/generate_icon.dart`/`tool/generate_audio.dart` -- this file never
/// ships with the app, it's a one-off local build tool.
Future<void> _loadRealFonts() async {
  const fontsDir =
      r'C:\Users\simsc\dev\flutter\bin\cache\artifacts\material_fonts';
  await _loadFont('Roboto', '$fontsDir\\roboto-regular.ttf');
  await _loadFont('MaterialIcons', '$fontsDir\\materialicons-regular.otf');
}

Future<void> _loadFont(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future.value(bytes.buffer.asByteData()));
  await loader.load();
}

void main() {
  testWidgets('generate title screenshot', (tester) async {
    await _withScreenshotSurface(tester, () async {
      // Real filesystem I/O (unlike everything else in a widget test) must
      // run inside runAsync -- it escapes flutter_test's FakeAsync zone
      // rather than leaving a dangling async gap that trips up the test
      // framework's guarded-call tracking on a later pump/pumpWidget call.
      await tester.runAsync(_loadRealFonts);
      await tester.pumpWidget(
        const RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: GameScreen(),
          ),
        ),
      );
      // A few settled frames of the title bob, not frame zero -- a nicer,
      // slightly-off-center pose than the exact rest position.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await _capture(tester, 'title');
    });
  });

  testWidgets('generate gameplay screenshot', (tester) async {
    await _withScreenshotSurface(tester, () async {
      await tester.runAsync(_loadRealFonts);

      const frameDt = 0.016;
      final turdXPx = GameConstants.turdX * screenshotSize.width;
      final pipeWidthPx = GameConstants.pipeWidth * screenshotSize.height;
      final centeredX = (turdXPx - pipeWidthPx / 2) / screenshotSize.height;

      // Pipe.spawn's gapCenterY is randomly chosen (bounded but not
      // settable directly -- see lib/models/pipe.dart), so rather than
      // guess a seed and hope it lines up with the turd, simulate a
      // STANDALONE Turd through the exact same tap-then-pump sequence used
      // below (a single flap, then N fixed-dt updates) to find out exactly
      // where the real turd will be, then search seeds for a gap that
      // contains it. Physics are pure and deterministic, so this
      // reproduces the real widget's trajectory exactly.
      //
      // A first pass that only matched the gap's vertical CENTRE turned
      // out not to be enough: turd.tilt (public, even though the
      // underlying _displayTilt field is private) eases toward its
      // velocity-driven target rather than snapping to it, so it's still
      // meaningfully non-zero this soon after a flap, and a rotated
      // silhouette's effective reach differs from its un-rotated bounding
      // shape -- exactly what test/collision_test.dart's "significant
      // tilt" test exercises. Rather than hand-derive the exact safe
      // tilt/position combination, this searches candidate frame counts
      // (which determine both the turd's y AND its tilt) and asks the
      // REAL turdCollidesWithPipe directly whether that combination is
      // actually safe, the same verify-don't-assume approach used
      // elsewhere in this project's test suite.
      Pipe? verifiedPipe;
      Turd? verifiedTurd;
      var verifiedFrames = -1;
      // Starts past GameConstants.overlayFadeDuration (300ms / 16ms per
      // frame ~= 19 frames) so the title/"Tap to start" AnimatedSwitcher
      // crossfade has always fully finished by the frame count this
      // search can pick -- a first pass that allowed earlier frames found
      // a collision-free one at frame 8, but the title overlay was still
      // visibly mid-fade in the capture.
      for (var frames = 20; frames <= 55 && verifiedPipe == null; frames++) {
        final rehearsalTurd = Turd()..flap();
        for (var i = 0; i < frames; i++) {
          rehearsalTurd.update(frameDt);
        }

        Pipe? bestPipe;
        var bestDistance = double.infinity;
        for (var seed = 1; seed <= 500; seed++) {
          final candidate = Pipe.spawn(screenshotSize, math.Random(seed));
          final distance = (candidate.gapCenterY - rehearsalTurd.y).abs();
          if (distance < bestDistance) {
            bestDistance = distance;
            bestPipe = candidate;
          }
        }
        if (bestPipe == null) {
          continue;
        }

        // Re-simulate the WHOLE approach frame by frame (not just the
        // final frame) and check turdCollidesWithPipe at every step --
        // the real game checks collision every tick too, so a path that
        // clips the pipe at some intermediate frame is unsafe even if the
        // final position looks clear. This is exactly the bug the first
        // version of this search had: it verified only the last frame,
        // found frames=8 "safe", but the actual approach up to frame 8
        // had already clipped the pipe partway through. Reuses bestPipe
        // itself (its gapCenterY, chosen above, is already the aligned
        // one -- Pipe.gapCenterY is immutable, so there's no way to copy
        // it onto a different Pipe instance) and walks its `x` backward
        // in the same per-frame steps PipeField.update would apply.
        final pathTurd = Turd()..flap();
        bestPipe.x = centeredX + GameConstants.pipeSpeed * frames * frameDt;
        var safe = true;
        for (var i = 0; i < frames && safe; i++) {
          pathTurd.update(frameDt);
          bestPipe.x -= GameConstants.pipeSpeed * frameDt;
          if (turdCollidesWithPipe(pathTurd, bestPipe, screenshotSize)) {
            safe = false;
          }
        }
        if (safe) {
          verifiedPipe = bestPipe;
          verifiedTurd = pathTurd;
          verifiedFrames = frames;
        }
      }

      if (verifiedPipe == null || verifiedTurd == null) {
        throw StateError(
          'No (frameCount, seed) combination in the searched range flies '
          'safely through a gap according to the real turdCollidesWithPipe.',
        );
      }
      print(
        'Verified safe: frames=$verifiedFrames turdY=${verifiedTurd.y} '
        'tilt=${verifiedTurd.tilt} gapCenterY=${verifiedPipe.gapCenterY}',
      );

      final pipeField = PipeField(math.Random(7));
      // Undo the temporary check-time position: the pipe (like every
      // pipe) keeps scrolling left at pipeSpeed for the whole
      // verifiedFrames window between now and capture, so it's placed
      // that same distance further right up front to land exactly where
      // it was just verified safe once that scroll has happened.
      verifiedPipe.x =
          centeredX + GameConstants.pipeSpeed * verifiedFrames * frameDt;
      pipeField.pipes.add(verifiedPipe);

      // A second pipe further out for visual depth -- far enough right
      // that it can never geometrically overlap the turd during this
      // short window regardless of its own (unaligned) random gap.
      final farPipe = Pipe.spawn(screenshotSize, math.Random(43))
        ..x = (turdXPx + screenshotSize.width * 0.55) / screenshotSize.height;
      pipeField.pipes.add(farPipe);

      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: GameScreen(pipeField: pipeField),
          ),
        ),
      );

      // Leave the title screen with the first flap -- the same single tap
      // the rehearsal simulation above modelled.
      await tester.tap(find.byType(GameScreen));
      await tester.pump();

      for (var i = 0; i < verifiedFrames; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(
        find.text('Game Over'),
        findsNothing,
        reason:
            'the feature pipe was supposed to be aligned so the turd '
            'flies safely through its gap -- a Game Over here means the '
            'alignment above is wrong',
      );

      await _capture(tester, 'gameplay');
    });
  });
}

/// Pumps [body] with the test view fixed to [screenshotSize] at a 1:1
/// device pixel ratio, so the eventual RenderRepaintBoundary.toImage
/// capture comes out at exactly that pixel resolution.
Future<void> _withScreenshotSurface(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  tester.view.physicalSize = screenshotSize;
  tester.view.devicePixelRatio = 1.0;
  // The test binding's default view simulates a nonzero top inset (as if
  // for a status bar/notch), which the real app never actually paints
  // over -- GamePainter's CustomPaint fills the full canvas regardless of
  // safe-area padding -- but the DEFAULT background peeking through above
  // it in a real device screenshot doesn't show this because there's no
  // such default background there. Zeroing it out matches what the real
  // emulator screenshots (captured earlier via adb) actually looked like.
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  tester.view.viewInsets = FakeViewPadding.zero;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetViewInsets);
  await body();
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final image = await boundary.toImage();
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Failed to PNG-encode the $name screenshot.');
  }
  final bytes = byteData.buffer.asUint8List();

  final dir = Directory('build/screenshots');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final file = File('build/screenshots/$name.png')..writeAsBytesSync(bytes);
  print('Wrote ${file.path} (${bytes.length} bytes)');
}
