import 'package:flutter_test/flutter_test.dart';
import 'package:munchi_bun/game/sim.dart';

/// Jumps right before the edge - the dumbest possible player.
void autoJump(GameSim s) {
  final g = s.ground;
  if (s.grounded && g != null && g.x1 - s.x < 14) {
    s.press();
    s.release();
  }
}

void main() {
  test('heavier buns jump lower, and the curve is steep', () {
    final a0 = GameSim.jumpApex(0);
    final a5 = GameSim.jumpApex(0.5);
    final a1 = GameSim.jumpApex(1);
    expect(a0, inInclusiveRange(190, 230));
    expect(a0, greaterThan(a5));
    expect(a5, greaterThan(a1));
    expect(a1, lessThan(45));
  });

  test('a full jump rises, falls and lands back on a roof', () {
    final s = GameSim(seed: 11);
    final startY = s.y;
    s.press();
    var peak = startY;
    for (var i = 0; i < 200; i++) {
      s.update(1 / 60);
      if (s.y > peak) peak = s.y;
      if (i > 20 && s.grounded) break;
    }
    expect(peak - startY, closeTo(GameSim.jumpApex(s.weight), 12));
    expect(s.grounded, isTrue);
    expect(s.end, End.running);
  });

  test('short taps give a shorter hop', () {
    final full = GameSim(seed: 11);
    full.press();
    var fullPeak = 0.0;
    for (var i = 0; i < 200; i++) {
      full.update(1 / 60);
      fullPeak = full.y > fullPeak ? full.y : fullPeak;
    }
    final tap = GameSim(seed: 11);
    tap.press();
    tap.update(1 / 60);
    tap.release();
    var tapPeak = 0.0;
    for (var i = 0; i < 200; i++) {
      tap.update(1 / 60);
      tapPeak = tap.y > tapPeak ? tap.y : tapPeak;
    }
    expect(tapPeak, lessThan(fullPeak));
  });

  test('eating a carrot adds weight and is counted', () {
    final s = GameSim(seed: 3);
    final w0 = s.weight;
    final n0 = s.carrotsEaten;
    s.carrots.first.eaten = false;
    s.x = s.carrots.first.x;
    s.y = s.carrots.first.y - 26;
    s.grounded = false;
    s.update(1 / 60);
    expect(s.carrotsEaten, n0 + 1);
    expect(s.weight, greaterThan(w0));
    expect(s.ateThisFrame, isTrue);
  });

  test('weight burns off while running', () {
    final s = GameSim(seed: 3);
    s.weight = 0.5;
    final before = s.weight;
    for (var i = 0; i < 120; i++) {
      s.update(1 / 60);
    }
    expect(s.weight, lessThan(before));
  });

  test('dropping into a gap ends the run as a fall', () {
    final s = GameSim(seed: 9);
    s.grounded = false;
    s.ground = null;
    s.vy = -400;
    // park the bun in the void just past the first roof
    s.x = 900 + 20;
    s.y = 120;
    for (var i = 0; i < 240 && s.end == End.running; i++) {
      s.update(1 / 60);
    }
    expect(s.end, isNot(End.running));
  });

  test('running into a taller wall ends the run', () {
    final s = GameSim(seed: 9);
    final target = s.roofs[1];
    s.x = target.x0 - 6;
    s.y = target.top - 60; // well below its roof line
    s.grounded = true;
    s.ground = s.roofs[0];
    for (var i = 0; i < 120 && s.end == End.running; i++) {
      s.update(1 / 60);
    }
    expect(s.end, isNot(End.running));
  });

  test('crossing the flag advances the zone', () {
    final s = GameSim(seed: 21);
    var guard = 0;
    while (s.zones == 0 && guard++ < 60 * 60) {
      autoJump(s);
      s.update(1 / 60);
      if (s.end != End.running) fail('died before the first flag: ${s.end}');
    }
    expect(s.zones, 1);
  });

  test('a greedy bot is eventually caught by its own weight', () {
    final times = <double>[];
    for (final seed in [101, 7, 22, 345, 998, 1234, 555, 7777]) {
      final s = GameSim(seed: seed);
      var i = 0;
      for (; i < 60 * 240; i++) {
        autoJump(s);
        s.update(1 / 60);
        if (s.end != End.running) break;
      }
      expect(s.end, isNot(End.running), reason: 'seed $seed never died');
      times.add(i / 60);
    }
    times.sort();
    // a careless player should be gone in under a minute, but not in seconds
    expect(times.first, greaterThan(15));
    expect(times.last, lessThan(150));
  });

  test('a lean bun can clear everything the generator builds', () {
    // same bot, but the diet is enforced: this measures generator fairness
    final s = GameSim(seed: 4);
    for (var i = 0; i < 60 * 240; i++) {
      autoJump(s);
      s.weight = 0;
      s.update(1 / 60);
      if (s.end != End.running) {
        fail('lean bun died at ${(s.dist / 10).round()}m: ${s.end}');
      }
    }
    expect(s.dist / 10, greaterThan(10000));
  });

  test('roofs stay inside the reach envelope of an honest jump', () {
    final s = GameSim(seed: 55);
    for (var i = 0; i < 60 * 60; i++) {
      autoJump(s);
      s.update(1 / 60);
      if (s.end != End.running) break;
    }
    final leanReach = GameSim.jumpReach(0, 490);
    for (var i = 1; i < s.roofs.length; i++) {
      final prev = s.roofs[i - 1];
      final r = s.roofs[i];
      final gap = r.x0 - prev.x1;
      expect(gap, lessThanOrEqualTo(200), reason: 'gap $gap is unjumpable');
      expect(r.top - prev.top, lessThanOrEqualTo(62), reason: 'step up too tall');
      expect(leanReach, greaterThan(gap));
      // the roof must catch a full lean jump taken at the previous edge
      expect(r.x1, greaterThan(prev.x1 + gap + 60));
    }
  });
}
