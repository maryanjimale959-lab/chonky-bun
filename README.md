# Munchi Bun

A chubby rooftop runner. You are a rabbit who eats carrots. Carrots are heavy. Being
heavy makes you jump lower, but the levels are generated so a fully stuffed rabbit can
still clear every gap - the challenge is rhythm, not luck.

Bauhaus monochrome art, bilingual English + Arabic interface, and a single-button
control scheme. Runs as a native Android app (APK) and in any browser (Flutter Web).

![Home](test/goldens/home_landscape.png)

## Controls

Hold to jump, release to cut the jump short. A tap just before landing triggers a jump
on the next frame. The rabbit can still jump for a few frames after walking off a roof
edge.

## Architecture

The simulation and the rendering are completely separate, which is what makes the game
testable and the feel tunable.

- `lib/game/sim.dart` - the entire game as deterministic pure Dart. It imports only
  `dart:math`. No Flutter types, no clock, no input. Every frame is `update(dt)`, so a
  run is reproducible from a seed and a physics regression is a unit test.
- `lib/game/painter.dart` - one `CustomPainter` that draws the world in a resolution
  independent unit space. Portrait and landscape share the same code path.
- `lib/screens/` - home, onboarding, and the in-game screen (HUD, pause, result card).
- `lib/core/l10n.dart` - bilingual strings rendered per line with the correct text
  direction.
- `lib/state/save.dart` - best score and career carrots, persisted with
  `shared_preferences`.

### Physics

Weight is a single scalar in `[0, 1]` that rises with every carrot. Jump velocity shrinks
with it:

```
jumpVel(w) = 1040 - 620w        gravity = 2500
```

The level generator solves that equation before it places a gap, so it never emits a gap
that the heaviest possible rabbit cannot clear. Fairness is a property of the generator,
not a hope.

On top of that: coyote time, jump buffering, and variable jump height.

## Running it

```
flutter pub get
flutter run                 # attached device or -d chrome
```

The Arabic-capable font (Cairo) is bundled, because Flutter Web and CanvasKit do not
ship an Arabic fallback.

## Tests

```
flutter test                # 22 tests
flutter analyze
```

- `test/sim_test.dart` - physics and generator invariants.
- `test/render_test.dart` - 12 golden screenshots across portrait and landscape,
  including the HUD and both overlays. Fonts are loaded explicitly in `setUpAll` because
  `flutter test` disables asset fonts by default.
- `test/icon_test.dart` - draws the launcher icon at every density using the game's own
  painters; runs only when `ICON_OUT=1` is set.

To play without a screen, drive an auto-jumping bot through the simulation:

```
dart run tool/playtest.dart
```

## Building

```
flutter build apk --release --split-per-abi    # arm64 is the one most phones need
flutter build web --release
```

The web build accepts two query parameters for direct entry: `?play=1` starts a run
immediately, `?guide=1` opens the onboarding.

## License notes

Cairo is bundled under the SIL Open Font License. Everything else in this repository is
original to the project.
