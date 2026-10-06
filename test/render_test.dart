import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munchi_bun/game/painter.dart';
import 'package:munchi_bun/game/sim.dart';
import 'package:munchi_bun/screens/game_screen.dart';
import 'package:munchi_bun/screens/home_screen.dart';
import 'package:munchi_bun/screens/onboarding_screen.dart';
import 'package:munchi_bun/state/save.dart';

void autoJump(GameSim s) {
  final g = s.ground;
  if (s.grounded && g != null && g.x1 - s.x < 14) {
    s.press();
    s.release();
  }
}

GameSim played(int seed, int frames, {double? forceWeight}) {
  final s = GameSim(seed: seed);
  for (var i = 0; i < frames; i++) {
    autoJump(s);
    if (forceWeight != null) s.weight = forceWeight;
    s.update(1 / 60);
    if (s.end != End.running) break;
  }
  return s;
}

Widget frame(Widget child, Size size) => MediaQuery(
      data: MediaQueryData(size: size),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: size.width, height: size.height, child: child)),
      ),
    );

Widget app(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFFE6E1D7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFBE8DA8)),
      ),
      home: child,
    );

/// `flutter test` forces Ahem (boxes for every glyph) unless the real font is
/// registered at runtime, so goldens would be unreadable without this.
Future<void> loadCairo() async {
  final loader = FontLoader('Cairo');
  for (final file in const [
    'Cairo-Regular.ttf',
    'Cairo-SemiBold.ttf',
    'Cairo-ExtraBold.ttf',
  ]) {
    final data = await rootBundle.load('assets/fonts/$file');
    loader.addFont(Future.value(data));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await loadCairo();
    Save.seenOnboarding = true;
    Save.best = 4820;
    Save.totalCarrots = 137;
  });

  Future<void> surface(WidgetTester t, Size s) async {
    await t.binding.setSurfaceSize(s);
    t.view.devicePixelRatio = 1.0;
  }

  testWidgets('world, lean bun', (t) async {
    await surface(t, const Size(900, 520));
    final sim = played(31, 420);
    await t.pumpWidget(frame(
        CustomPaint(painter: WorldPainter(sim: sim, time: 2.4), size: const Size(900, 520)),
        const Size(900, 520)));
    await expectLater(find.byType(CustomPaint), matchesGoldenFile('goldens/world_lean.png'));
  });

  testWidgets('world, heavy bun', (t) async {
    await surface(t, const Size(900, 520));
    final sim = played(31, 420, forceWeight: 0.88);
    await t.pumpWidget(frame(
        CustomPaint(painter: WorldPainter(sim: sim, time: 1.1), size: const Size(900, 520)),
        const Size(900, 520)));
    await expectLater(find.byType(CustomPaint), matchesGoldenFile('goldens/world_heavy.png'));
  });

  testWidgets('world, portrait phone', (t) async {
    await surface(t, const Size(400, 820));
    final sim = played(31, 300);
    await t.pumpWidget(frame(
        CustomPaint(painter: WorldPainter(sim: sim, time: 0.6), size: const Size(400, 820)),
        const Size(400, 820)));
    await expectLater(find.byType(CustomPaint), matchesGoldenFile('goldens/world_portrait.png'));
  });

  testWidgets('in-game HUD, landscape', (t) async {
    await surface(t, const Size(900, 520));
    await t.pumpWidget(app(const GameScreen()));
    await t.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(GameScreen), matchesGoldenFile('goldens/hud_landscape.png'));
  });

  testWidgets('in-game HUD, portrait', (t) async {
    await surface(t, const Size(400, 820));
    await t.pumpWidget(app(const GameScreen()));
    await t.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(GameScreen), matchesGoldenFile('goldens/hud_portrait.png'));
  });

  testWidgets('pause overlay', (t) async {
    await surface(t, const Size(900, 520));
    await t.pumpWidget(app(const GameScreen(
        debugOverlay: DebugOverlay.paused)));
    await t.pump(const Duration(milliseconds: 300));
    await expectLater(
        find.byType(GameScreen), matchesGoldenFile('goldens/overlay_pause.png'));
  });

  testWidgets('result overlay, portrait', (t) async {
    await surface(t, const Size(400, 820));
    await t.pumpWidget(app(const GameScreen(
        debugOverlay: DebugOverlay.result)));
    await t.pump(const Duration(milliseconds: 300));
    await expectLater(
        find.byType(GameScreen), matchesGoldenFile('goldens/overlay_result.png'));
  });

  testWidgets('home', (t) async {
    await surface(t, const Size(400, 820));
    await t.pumpWidget(app(const HomeScreen()));
    await t.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(HomeScreen), matchesGoldenFile('goldens/home_portrait.png'));
  });

  testWidgets('home landscape', (t) async {
    await surface(t, const Size(900, 520));
    await t.pumpWidget(app(const HomeScreen()));
    await t.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(HomeScreen), matchesGoldenFile('goldens/home_landscape.png'));
  });

  testWidgets('onboarding', (t) async {
    await surface(t, const Size(400, 820));
    await t.pumpWidget(app(const OnboardingScreen()));
    await t.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(OnboardingScreen), matchesGoldenFile('goldens/onboarding.png'));
  });

  testWidgets('onboarding pages 2 and 3', (t) async {
    await surface(t, const Size(400, 820));
    await t.pumpWidget(app(const OnboardingScreen()));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('NEXT'));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    await expectLater(
        find.byType(OnboardingScreen), matchesGoldenFile('goldens/onboarding_2.png'));
    await t.tap(find.text('NEXT'));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    await expectLater(
        find.byType(OnboardingScreen), matchesGoldenFile('goldens/onboarding_3.png'));
  });
}
