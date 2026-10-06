// Headless balance harness: run with `dart run tool/playtest.dart`.
// ignore_for_file: avoid_print
// Headless playtest: `dart run tool/playtest.dart`
// Drives the dumbest possible player and reports exactly how it died.
import 'dart:math' as math;

import 'package:munchi_bun/game/sim.dart';

void autoJump(GameSim s) {
  final g = s.ground;
  if (s.grounded && g != null && g.x1 - s.x < 14) {
    s.press();
    s.release();
  }
}

void main(List<String> args) {
  final seeds = [101, 7, 22, 345, 998, 1234, 555, 7777];
  final times = <double>[];
  final dists = <double>[];
  for (final seed in seeds) {
    final s = GameSim(seed: seed);
    var i = 0;
    const maxFrames = 60 * 240;
    final trace = <String>[];
    for (; i < maxFrames; i++) {
      autoJump(s);
      s.update(1 / 60);
      if (s.x > 4900) {
        if (s.jumpedThisFrame) {
          trace.add('jump @${s.x.round()} y=${s.y.round()} vy=${s.vy.round()} w=${s.weight.toStringAsFixed(2)}');
        }
        if (s.landedThisFrame) trace.add('  land @${s.x.round()} y=${s.y.round()}');
        if (s.grounded && s.x > 5150 && s.x < 5230) {
          trace.add('  run @${s.x.round()} edge=${s.ground?.x1.round()}');
        }
      }
      if (s.end != End.running) break;
    }
    if (s.end != End.running && seed == 22) {
      for (final t in trace.sublist(math.max(0, trace.length - 14))) {
        print(t);
      }
    }
    final secs = i / 60;
    times.add(secs);
    dists.add(s.dist / 10);
    if (s.end != End.running) {
      Roof? before;
      Roof? after;
      for (final r in s.roofs) {
        if (r.x1 < s.x) before = r;
        if (after == null && r.x0 > s.x) after = r;
      }
      print('seed $seed  died ${s.end.name} at ${secs.toStringAsFixed(1)}s '
          '${(s.dist / 10).round()}m  w=${s.weight.toStringAsFixed(2)} '
          'carrots=${s.carrotsEaten}/${s.carrotsPlaced}');
      print('   x=${s.x.round()} y=${s.y.round()} vy=${s.vy.round()} '
          'grounded=${s.grounded} speed=${s.speed.round()}');
      print('   apex=${GameSim.jumpApex(s.weight).round()} '
          'reach=${GameSim.jumpReach(s.weight, s.speed).round()}');
      if (before != null) {
        print('   before: x0=${before.x0.round()} x1=${before.x1.round()} top=${before.top.round()}');
      }
      if (after != null) {
        print('   after : x0=${after.x0.round()} x1=${after.x1.round()} top=${after.top.round()}'
            ' gap=${(after.x0 - (before?.x1 ?? after.x0)).round()}'
            ' step=${(after.top - (before?.top ?? after.top)).round()}');
      }
    } else {
      print('seed $seed  survived ${secs.toStringAsFixed(0)}s ${(s.dist / 10).round()}m '
          'w=${s.weight.toStringAsFixed(2)} carrots=${s.carrotsEaten}/${s.carrotsPlaced} '
          'placed/km=${(s.carrotsPlaced / (s.dist / 1000)).round()}');
    }
  }
  times.sort();
  dists.sort();
  print('median survival: ${times[times.length ~/ 2].toStringAsFixed(1)}s, '
      'median distance: ${dists[dists.length ~/ 2].round()}m');
}
