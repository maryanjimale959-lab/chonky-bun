// Seed sweep for the autopilot: `dart run tool/botbench.dart`.
// Finds runs that last long enough, and eat enough carrots, to film.
// ignore_for_file: avoid_print
import 'package:munchi_bun/game/bot.dart';
import 'package:munchi_bun/game/sim.dart';

class Result {
  Result(this.seed, this.frames, this.meters, this.carrots, this.placed, this.died);
  final int seed;
  final int frames;
  final int meters;
  final int carrots;
  final int placed;
  final String died;

  double get score => frames + carrots * 220;
}

Result play(int seed, int maxFrames) {
  final s = GameSim(seed: seed);
  final bot = Bot(s);
  var i = 0;
  for (; i < maxFrames && s.end == End.running; i++) {
    bot.step();
    s.update(1 / 60);
  }
  return Result(seed, i, (s.dist / 10).round(), s.carrotsEaten, s.carrotsPlaced,
      s.end == End.running ? 'filmed out' : s.end.name);
}

void main(List<String> args) {
  final count = int.tryParse(args.isNotEmpty ? args[0] : '') ?? 400;
  final cap = int.tryParse(args.length > 1 ? args[1] : '') ?? 60 * 200;
  final results = <Result>[];
  for (var seed = 1; seed <= count; seed++) {
    results.add(play(seed, cap));
  }
  results.sort((a, b) => b.score.compareTo(a.score));

  print('seed  seconds  meters  carrots  placed  outcome');
  for (final r in results.take(15)) {
    print('${r.seed.toString().padLeft(4)}  '
        '${(r.frames / 60).toStringAsFixed(1).padLeft(7)}  '
        '${r.meters.toString().padLeft(6)}  '
        '${r.carrots.toString().padLeft(7)}  '
        '${r.placed.toString().padLeft(6)}  ${r.died}');
  }

  final survived = results.where((r) => r.died == 'filmed out').length;
  final median = results.map((r) => r.frames).toList()..sort();
  final carrotRate = results
      .map((r) => r.placed > 0 ? r.carrots / r.placed : 0.0)
      .toList()
    ..sort();
  print('\nfilmed out (never died): $survived/$count');
  print('median run: ${(median[median.length ~/ 2] / 60).toStringAsFixed(1)}s');
  print('median carrot pickup rate: '
      '${(carrotRate[carrotRate.length ~/ 2] * 100).toStringAsFixed(0)}%');
  print('worst: seed ${results.last.seed} died at '
      '${(results.last.frames / 60).toStringAsFixed(1)}s ${results.last.died}');
  final short = results.where((r) => r.frames < 60 * 20).length;
  print('runs under 20s: $short');
  print('best run eats ${results.first.carrots} of ${results.first.placed} carrots');

  // Candidates for filming: long enough to be impressive, short enough to end
  // inside a clip so the result card appears on camera.
  final lo = int.tryParse(args.length > 2 ? args[2] : '') ?? 0;
  final hi = int.tryParse(args.length > 3 ? args[3] : '') ?? 0;
  if (lo > 0 && hi > lo) {
    final band = results
        .where((r) => r.frames >= 60 * lo && r.frames <= 60 * hi && r.died != 'filmed out')
        .toList();
    print('\n--- $lo..${hi}s deaths, most carrots first ---');
    for (final r in band.take(12)) {
      print('seed ${r.seed.toString().padLeft(4)}  '
          '${(r.frames / 60).toStringAsFixed(1).padLeft(5)}s  '
          '${r.meters.toString().padLeft(5)}m  '
          '${r.carrots.toString().padLeft(3)} carrots  ${r.died}');
    }
  }
}
