import 'dart:async';
import 'dart:math' as math;

import 'package:crappy_turd/game/cloud_field.dart';
import 'package:crappy_turd/game/collision.dart';
import 'package:crappy_turd/game/constants.dart';
import 'package:crappy_turd/game/day_night.dart';
import 'package:crappy_turd/game/game_status.dart';
import 'package:crappy_turd/game/high_score_store.dart';
import 'package:crappy_turd/game/particle_field.dart';
import 'package:crappy_turd/game/pipe_field.dart';
import 'package:crappy_turd/game/scoring.dart';
import 'package:crappy_turd/game/shooting_star_field.dart';
import 'package:crappy_turd/game/sound_manager.dart';
import 'package:crappy_turd/game/star_field.dart';
import 'package:crappy_turd/game/trail_field.dart';
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
/// the best score across all runs, persisted across app restarts via
/// [HighScoreStore].
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.pipeField});

  /// An optional pre-seeded [PipeField] override, used by tests that need
  /// deterministic pipe-gap placement (e.g. to reliably drive the turd
  /// through a real gap and score a genuine point, rather than depending on
  /// random chance). Left null for real gameplay -- see
  /// [_GameScreenState.initState], which creates a fresh unseeded field
  /// instead whenever this is null.
  final PipeField? pipeField;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final Turd _turd = Turd();
  late final PipeField _pipeField;
  final CloudField _cloudField = CloudField();
  final ParticleField _particleField = ParticleField();
  final TrailField _trailField = TrailField();

  /// Fixed background star field. Purely ambient and session-long, exactly
  /// like [_cloudField] -- never reset on restart (see
  /// `lib/game/star_field.dart`).
  final StarField _starField = StarField();

  /// Live shooting stars and their spawn timer. Also session-long and never
  /// reset on restart -- an in-flight shooting star, or the countdown to
  /// the next one, has no reason to care which run is currently underway
  /// (see `lib/game/shooting_star_field.dart`).
  final ShootingStarField _shootingStarField = ShootingStarField();
  final SoundManager _soundManager = SoundManager();
  final HighScoreStore _highScoreStore = HighScoreStore();
  late final Ticker _ticker;

  /// Drives the brief post-collision screen shake (see [build]'s shake
  /// wrapper around the [CustomPaint]). Needs its own vsync alongside the
  /// main game [Ticker], which is why this State uses
  /// [TickerProviderStateMixin] rather than the single-client
  /// [SingleTickerProviderStateMixin] the rest of the app would otherwise
  /// only need.
  late final AnimationController _shakeController;
  Duration _lastTick = Duration.zero;
  GameStatus _status = GameStatus.title;

  /// The current run's live score (pipes passed since the last restart).
  int _score = 0;

  /// Seconds of continuous play in the current run, driving the looping
  /// day/night sky via [dayNightT] (see [_dayNightT] and
  /// [GameConstants.dayNightCycleDuration]). Purely cosmetic -- only ever
  /// incremented in the [GameStatus.playing] branch of [_onTick], so it
  /// naturally freezes at whatever value it reached the instant a run
  /// ends, same as everything else on the frozen game-over scene, and
  /// resets to 0 on restart alongside [_score].
  double _playTime = 0;

  /// The current day/night amount (`0.0` = day, `1.0` = peak night),
  /// derived from [_playTime] via the looping [dayNightT] wave function --
  /// the single source of truth for that math, reused here (for the
  /// shooting-star field's spawn gate) and in [build] (for the painter)
  /// rather than duplicated inline in either place.
  double get _dayNightT =>
      dayNightT(_playTime, GameConstants.dayNightCycleDuration);

  /// The best score ever recorded, persisted across app restarts via
  /// [_highScoreStore]. Starts at 0 and is overwritten once [_loadBest]'s
  /// async load resolves, so a fresh app launch briefly reads 0 before the
  /// real saved value (if any) arrives.
  int _best = 0;

  /// Whether sound effects are currently silenced. In-memory only -- unlike
  /// [_best], persisting this across app restarts is out of scope for now.
  /// Kept in sync with [_soundManager]'s own `muted` field by every toggle.
  bool _muted = false;

  /// The real pixel size of the game canvas, refreshed on every [build] so
  /// collision detection (which needs actual pixel geometry, not just
  /// fractions) always has an up-to-date value.
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _pipeField = widget.pipeField ?? PipeField();
    _ticker = createTicker(_onTick);
    unawaited(_ticker.start());
    _shakeController = AnimationController(
      vsync: this,
      duration: GameConstants.shakeDuration,
    );
    unawaited(_loadBest());
  }

  /// Loads the persisted best score (if any) once [_highScoreStore]'s async
  /// read resolves, and applies it to [_best].
  ///
  /// Takes the max of the loaded value and whatever [_best] already holds,
  /// rather than blindly assigning it. In this app's actual reachable state
  /// space that ordering risk isn't real today -- reaching a game-over that
  /// sets [_best] requires a prior tap past the title screen plus real
  /// elapsed gameplay time, both far slower than this near-instant local
  /// read -- but taking the max costs nothing and keeps this correct even
  /// if that timing invariant is ever broken by a future change, rather
  /// than silently depending on it. If that race ever DID happen, the
  /// freshly-resolved max can exceed what's actually sitting in storage
  /// (a same-session game-over could have already saved a lower score
  /// before this load resolved) -- re-saving here closes that gap, so the
  /// store itself, not just this session's in-memory value, ends up
  /// correct too.
  Future<void> _loadBest() async {
    final saved = await _highScoreStore.load();
    if (!mounted) return;
    final resolved = math.max(_best, saved);
    setState(() {
      _best = resolved;
    });
    if (resolved > saved) {
      unawaited(_highScoreStore.save(resolved));
    }
  }

  void _onTick(Duration elapsed) {
    final dt =
        (elapsed - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = elapsed;
    // Skip the first frame and any large hitches so the physics stays stable.
    if (dt <= 0 || dt > 0.1) return;
    setState(() {
      // Ambient effects run regardless of game status: clouds drift
      // continuously (including on the title screen and while frozen at
      // game-over), and any in-flight particle burst or trail ghost keeps
      // aging/fading out rather than instantly vanishing on a status
      // change.
      _cloudField.update(dt);
      _particleField.update(dt);
      _trailField.update(dt);
      // Shooting stars only ever spawn NEW while the sky is dark enough
      // (see GameConstants.shootingStarVisibilityThreshold), but -- like
      // the ambient fields above -- always keep ageing/moving/getting
      // culled regardless of GameStatus, hence living in this
      // unconditional block rather than inside the `playing` case below.
      _shootingStarField.update(dt, _dayNightT);
      switch (_status) {
        case GameStatus.title:
          final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
          _turd.hover(t);
        case GameStatus.playing:
          _turd.update(dt);
          _playTime += dt;
          // Sample the motion trail only while actually playing -- a
          // frozen or hovering turd shouldn't leave a trail.
          _trailField.sample(_turd.y, _turd.tilt);
          _pipeField.update(dt);
          // Scoring and dying are independent per-frame events; tally any
          // pipes the turd has newly flown past before checking whether
          // this frame is also the one where it dies.
          final passedThisTick = countPipesPassed(_pipeField.pipes);
          if (passedThisTick > 0) {
            unawaited(_soundManager.playScore());
          }
          _score += passedThisTick;
          // Guards the impossible-in-practice case of a tick firing before
          // the first build/layout has ever run — the player can't reach
          // `playing` before at least one build (a tap is required first),
          // so this should never actually skip a real check.
          if (_size != Size.zero &&
              checkCollision(_turd, _pipeField.pipes, _size)) {
            _status = GameStatus.gameOver;
            _particleField.burstDeath(GameConstants.turdX, _turd.y);
            _turd.impact();
            unawaited(_shakeController.forward(from: 0));
            unawaited(_soundManager.playDeath());
            if (_score > _best) {
              _best = _score;
              unawaited(_highScoreStore.save(_best));
            }
          }
        case GameStatus.gameOver:
        // Frozen: no physics or pipe movement until the player taps to
        // restart.
      }
    });
  }

  /// Flap the turd and spawn a matching poof of particles at its current
  /// position. Shared by every tap that flaps -- the title/playing taps
  /// AND the game-over restart tap alike -- so a flap is always a flap.
  void _flap() {
    _turd.flap();
    _particleField.burstFlap(GameConstants.turdX, _turd.y);
    unawaited(_soundManager.playFlap());
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      if (_status == GameStatus.gameOver) {
        _turd.reset();
        _pipeField.reset();
        _particleField.reset();
        _trailField.reset();
        // The best score is NOT reset here -- it persists for the lifetime
        // of the running app, across as many runs as the player takes.
        _score = 0;
        _playTime = 0;
      }
      _status = GameStatus.playing;
      _flap();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shakeController.dispose();
    unawaited(_soundManager.dispose());
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

  /// Wraps the game scene in a small, fast, decaying jitter driven by
  /// [_shakeController]: strongest right at the moment of impact
  /// (`_shakeController.value == 0`), fading to nothing by the time the
  /// controller finishes. Only the scene itself shakes -- the
  /// overlay/HUD Stack children outside this widget are untouched.
  Widget _buildShakingScene(Widget scene) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final decay = 1 - t;
        final dx =
            math.sin(t * GameConstants.shakeFrequency) *
            GameConstants.shakeMagnitude *
            _size.width *
            decay;
        final dy =
            math.cos(t * GameConstants.shakeFrequency * 1.3) *
            GameConstants.shakeMagnitude *
            _size.height *
            decay;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: scene,
    );
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: GestureDetector(
        onTapDown: _onTapDown,
        child: Stack(
          children: [
            _buildShakingScene(
              CustomPaint(
                size: Size.infinite,
                painter: GamePainter(
                  turd: _turd,
                  pipes: _pipeField.pipes,
                  clouds: _cloudField.clouds,
                  trailSamples: _trailField.samples,
                  particles: _particleField.particles,
                  stars: _starField.stars,
                  shootingStars: _shootingStarField.shootingStars,
                  dayNightT: _dayNightT,
                  playTime: _playTime,
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedSwitcher(
                duration: GameConstants.overlayFadeDuration,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: _overlayForStatus(),
              ),
            ),
            if (_status == GameStatus.playing)
              _ScoreHud(key: const ValueKey('scoreHud'), score: _score),
            // Deliberately a direct Stack child -- NOT nested inside the
            // IgnorePointer wrapping the AnimatedSwitcher overlay above --
            // and always visible regardless of [_status], unlike that
            // overlay. An IconButton has its own internal tap recognizer,
            // which wins the gesture arena over the outer GestureDetector's
            // for any pointer down that lands on the button itself, so
            // tapping it does not also register as a flap/restart tap on
            // the game below (see the widget test covering exactly this).
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 4),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _muted = !_muted;
                      _soundManager.muted = _muted;
                    });
                  },
                  icon: Icon(
                    _muted ? Icons.volume_off : Icons.volume_up,
                    color: Palette.turdDark,
                  ),
                ),
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
/// Also shows a "Best: N" line beneath the hint, but only once there is an
/// actual best to show ([best] > 0) -- whether restored from a previous
/// session's persisted high score or set by a run that has already ended
/// this session -- since a genuinely fresh install with nothing saved and
/// nothing yet scored shouldn't advertise "Best: 0".
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
          ScaleTransition(
            scale: Tween<double>(
              begin: 1,
              end: 1.05,
            ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: const Text(
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
