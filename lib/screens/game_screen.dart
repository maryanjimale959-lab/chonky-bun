import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/l10n.dart';
import '../core/palette.dart';
import '../game/bot.dart';
import '../game/painter.dart';
import '../game/sim.dart';
import '../state/save.dart';
import '../ui/kit.dart';

/// Lets the golden tests paint the overlays without waiting on real play.
enum DebugOverlay { none, paused, result }

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.debugOverlay = DebugOverlay.none,
    this.autoPlay = false,
    this.seed = 20261005,
  });

  final DebugOverlay debugOverlay;

  /// Let the autopilot play. Used to film demo footage, and as an attract mode
  /// on the web build (`?demo=1`).
  final bool autoPlay;

  /// Level seed. The world is generated deterministically from it.
  final int seed;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final GameSim sim = GameSim(seed: widget.seed);
  late final Bot _bot;
  late final AnimationController _c;
  int _lastUs = 0;
  double _now = 0;
  double _hint = 0;
  double _zoneToast = 0;
  bool paused = false;
  bool showResult = false;
  bool newBest = false;
  int runMeters = 0;
  Timer? _resultTimer;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _bot = Bot(sim);
    // The controller is only a frame ticker: its elapsed time drives the sim,
    // so the duration is a ceiling on session length, not an animation length.
    // A year keeps it from ever completing and freezing the loop.
    _c = AnimationController(vsync: this, duration: const Duration(days: 365))
      ..addListener(_tick)
      ..forward();
    if (widget.debugOverlay == DebugOverlay.paused) {
      paused = true;
    } else if (widget.debugOverlay == DebugOverlay.result) {
      // Play the run with the real autopilot so the card shows honest numbers.
      for (var i = 0; i < 60 * 44 && sim.end == End.running; i++) {
        _bot.step();
        sim.update(1 / 60);
      }
      runMeters = (sim.dist / 10).round();
      newBest = true;
      showResult = true;
    }
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    _c.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !paused && !showResult) {
      setState(() => paused = true);
    }
  }

  void _tick() {
    // Driven by the ticker, not a wall-clock Stopwatch, so the simulation
    // advances on the binding's clock. That keeps golden tests reproducible.
    final nowUs = (_c.lastElapsedDuration ?? Duration.zero).inMicroseconds;
    // Clamp before the sim sees it: a GC pause, or returning from a backgrounded
    // app, hands us a multi-second dt, and one integration step would carry the
    // rabbit straight through a roof into a pit.
    final dt = ((nowUs - _lastUs) / 1e6).clamp(0.0, 0.05);
    _lastUs = nowUs;
    _now += dt;

    if (!paused && !showResult) {
      if (widget.autoPlay) _bot.step();
      sim.update(dt);
      _hint += dt;
      if (_zoneToast > 0) _zoneToast -= dt;
      if (sim.zoneThisFrame) _zoneToast = 1.8;
      if (sim.ateThisFrame) HapticFeedback.selectionClick();
      if (sim.diedThisFrame) {
        HapticFeedback.heavyImpact();
        runMeters = (sim.dist / 10).round();
        _resultTimer = Timer(const Duration(milliseconds: 950), _finish);
      }
    }
  }

  Future<void> _finish() async {
    var isBest = false;
    // An autopilot run is footage, not a player's score: never record it, and
    // never claim a personal best for it either.
    if (!widget.autoPlay) {
      isBest = await Save.submitRun(meters: runMeters, carrots: sim.carrotsEaten);
    }
    if (!mounted) return;
    setState(() {
      newBest = isBest;
      showResult = true;
    });
  }

  void _press() {
    if (paused || showResult) return;
    sim.press();
  }

  void _release() {
    if (paused || showResult) return;
    sim.release();
  }

  void _restart() {
    _resultTimer?.cancel();
    sim.reset();
    _hint = 0;
    _zoneToast = 0;
    setState(() {
      showResult = false;
      paused = false;
      newBest = false;
    });
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    final jump = e.logicalKey == LogicalKeyboardKey.space ||
        e.logicalKey == LogicalKeyboardKey.enter ||
        e.logicalKey == LogicalKeyboardKey.arrowUp ||
        e.logicalKey == LogicalKeyboardKey.keyW;
    if (jump) {
      if (e is KeyDownEvent) {
        if (showResult) {
          _restart();
        } else {
          _press();
        }
      } else if (e is KeyUpEvent) {
        _release();
      }
      return KeyEventResult.handled;
    }
    if (e is KeyDownEvent &&
        (e.logicalKey == LogicalKeyboardKey.escape ||
            e.logicalKey == LogicalKeyboardKey.keyP)) {
      if (!showResult) setState(() => paused = !paused);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pal.paper,
      body: Focus(
        autofocus: true,
        onKeyEvent: _key,
        child: GestureDetector(
          onTapDown: (_) => _press(),
          onTapUp: (_) => _release(),
          onTapCancel: _release,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(painter: WorldPainter(sim: sim, time: _now)),
              ),
              SafeArea(
                bottom: false,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) => _hud(),
                ),
              ),
              if (paused) _pauseOverlay(),
              if (showResult) _resultOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ---- HUD -----------------------------------------------------------------
  Widget _hud() {
    final w = sim.weight;
    return Stack(
      children: [
        Positioned(left: 18, top: 14, child: _weightPanel(w)),
        Positioned(right: 16, top: 14, child: _topRight()),
        if (!showResult) Positioned(left: 18, bottom: 16, child: _bottomLeft()),
        if (_hint < 5.2 && !showResult && !paused) _hintOverlay(),
        if (_zoneToast > 0) _zoneBanner(),
      ],
    );
  }

  Widget _weightPanel(double w) {
    final pct = (w * 100).round();
    final danger = w > 0.8;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Bi(
            en: S.weight,
            ar: S.weightAr,
            enSize: 8.5,
            arSize: 11,
            color: Pal.graphite,
            arColor: Pal.grey),
        const SizedBox(height: 6),
        Container(
          width: 132,
          height: 13,
          decoration: BoxDecoration(
            color: Pal.cream,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Pal.black, width: 2),
          ),
          child: Stack(
            children: [
              AnimatedFraction(
                fraction: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: danger ? Pal.accentDeep : Pal.black,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text('$pct%',
                style: const TextStyle(
                    fontFamily: Type.family,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Pal.black)),
            const SizedBox(width: 8),
            _chip(S.stateOf(w), S.stateOfAr(w), danger),
          ],
        ),
      ],
    );
  }

  Widget _chip(String en, String ar, bool hot) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: hot ? Pal.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: hot ? Pal.accentDeep : Pal.grey, width: 1.2),
        ),
        child: Text('$en · $ar',
            style: TextStyle(
                fontFamily: Type.family,
                fontSize: 9.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: hot ? Pal.black : Pal.graphite)),
      );

  Widget _topRight() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Pal.cream.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Pal.black, width: 1.6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CarrotIcon(17),
                const SizedBox(width: 6),
                Text('x ${sim.carrotsEaten}',
                    style: const TextStyle(
                        fontFamily: Type.family,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Pal.black)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() => paused = true),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Pal.cream.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Pal.black, width: 1.8),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PauseBar(),
                    SizedBox(width: 4),
                    _PauseBar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _bottomLeft() => Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
        decoration: BoxDecoration(
          color: Pal.cream.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Pal.black, width: 1.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Caps(S.distance, size: 8, color: Pal.grey, spacing: 2.2),
                Text('${(sim.dist / 10).round()}m',
                    style: const TextStyle(
                        fontFamily: Type.family,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Pal.black,
                        height: 1.0)),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _chip('${S.zone} ${sim.zones + 1}', S.zoneAr, false),
            ),
          ],
        ),
      );

  Widget _hintOverlay() {
    final a = _hint < 4.2 ? 1.0 : (5.2 - _hint) / 1.0;
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: a.clamp(0.0, 1.0),
          child: Align(
            alignment: const Alignment(0, 0.55),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Pal.cream.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Pal.black, width: 1.6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulseRing(t: _now * 0.8, size: 26),
                  const SizedBox(width: 14),
                  const Bi(
                    en: S.tapToJump,
                    ar: S.tapToJumpAr,
                    enSize: 9.5,
                    arSize: 12,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _zoneBanner() {
    final k = clampd(_zoneToast / 1.8, 0, 1);
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: k > 0.7 ? 1.0 : k / 0.7,
            child: Transform.scale(
              scale: 0.9 + 0.2 * (1 - k),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Caps('${S.zone} ${sim.zones}',
                      size: 30, weight: FontWeight.w800, spacing: 6),
                  Text(S.zoneAr,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontFamily: Type.family,
                          fontSize: 17,
                          color: Pal.graphite)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- overlays ------------------------------------------------------------
  Widget _card({required List<Widget> children, double width = 340}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          decoration: BoxDecoration(
            color: Pal.cream,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Pal.black, width: 2.4),
            boxShadow: [
              BoxShadow(color: Pal.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: SingleChildScrollView(child: Column(children: children)),
        ),
      ),
    );
  }

  Widget _pauseOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Pal.black.withValues(alpha: 0.5),
        child: _card(children: [
          const Bi(
              en: S.paused,
              ar: S.pausedAr,
              enSize: 15,
              arSize: 16,
              crossAxisAlignment: CrossAxisAlignment.center),
          const SizedBox(height: 18),
          const StateStrip(scale: 0.9),
          const SizedBox(height: 18),
          PillButton(
              label: S.resume, labelAr: S.resumeAr, expand: true, height: 54, onTap: () => setState(() => paused = false)),
          const SizedBox(height: 10),
          PillButton(
              label: S.restart,
              labelAr: S.restartAr,
              expand: true,
              height: 54,
              filled: false,
              onTap: _restart),
          const SizedBox(height: 10),
          PillButton(
              label: S.home,
              labelAr: S.homeAr,
              expand: true,
              height: 54,
              filled: false,
              onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }

  Widget _resultOverlay() {
    final fell = sim.end == End.fell;
    return Positioned.fill(
      child: ColoredBox(
        color: Pal.black.withValues(alpha: 0.52),
        child: _card(
          width: 360,
          children: [
            BunPortrait(width: 92, weight: sim.weight, dizzy: true, phase: 1.2),
            const SizedBox(height: 6),
            Bi(
                en: fell ? S.fell : S.bumped,
                ar: fell ? S.fellAr : S.bumpedAr,
                enSize: 11.5,
                arSize: 14,
                crossAxisAlignment: CrossAxisAlignment.center,
                color: Pal.graphite,
                arColor: Pal.grey),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$runMeters',
                    style: const TextStyle(
                        fontFamily: Type.family,
                        fontSize: 58,
                        fontWeight: FontWeight.w800,
                        height: 0.9,
                        color: Pal.black)),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Caps('m', size: 15, spacing: 1),
                ),
              ],
            ),
            if (newBest)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: Pal.accent, borderRadius: BorderRadius.circular(20)),
                  child: Text('${S.newBest} · ${S.newBestAr}',
                      style: const TextStyle(
                          fontFamily: Type.family,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Pal.black)),
                ),
              ),
            const SizedBox(height: 16),
            _statRow([
              [S.carrots, S.carrotsAr, '${sim.carrotsEaten}'],
              [S.zone, S.zoneAr, '${sim.zones + 1}'],
              [S.weight, S.weightAr, S.pct(sim.weight)],
            ]),
            const SizedBox(height: 20),
            PillButton(
                label: S.again, labelAr: S.againAr, expand: true, height: 56, onTap: _restart),
            const SizedBox(height: 10),
            PillButton(
                label: S.home,
                labelAr: S.homeAr,
                expand: true,
                height: 52,
                filled: false,
                onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  Widget _statRow(List<List<String>> rows) => Row(
        children: [
          for (final r in rows)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Caps(r[0], size: 8, color: Pal.grey, spacing: 1.8),
                  Text(r[1],
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontFamily: Type.family, fontSize: 9.5, color: Pal.grey)),
                  const SizedBox(height: 4),
                  Text(r[2],
                      style: const TextStyle(
                          fontFamily: Type.family,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Pal.black)),
                ],
              ),
            ),
        ],
      );
}

class _PauseBar extends StatelessWidget {
  const _PauseBar();
  @override
  Widget build(BuildContext context) => Container(
      width: 3.4, height: 14, decoration: BoxDecoration(color: Pal.black, borderRadius: BorderRadius.circular(2)));
}

/// Weight gauge fill, inset inside the bordered track.
class AnimatedFraction extends StatelessWidget {
  const AnimatedFraction({required this.fraction, required this.child, super.key});
  final double fraction;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(1.6),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: clampd(fraction, 0, 1),
          child: child,
        ),
      );
}
