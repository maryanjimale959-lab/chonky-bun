// Films the real game screen, frame by frame, into a PNG sequence that
// tool/make_video.sh (ffmpeg) turns into a clip.
//
//   DEMO_OUT=build/demo flutter test test/demo_capture_test.dart
//
// Deliberately not a screen recording. The widget tree is pumped at exactly
// 1/60 of a second per frame and every frame is rasterised by the same Skia
// that ships the game, so the result has no dropped frames, no cursor, no
// browser chrome and no jitter - and it is reproducible from the seed alone.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munchi_bun/screens/game_screen.dart';

/// Vertical social format.
const Size kFilmSize = Size(1080, 1920);

/// Seconds of footage: a 43.8s curated run, the death animation, and the card.
const int kFilmSeconds = 50;

Future<void> _loadCairo() async {
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
  final out = Platform.environment['DEMO_OUT'];

  testWidgets('film the demo', (t) async {
    if (out == null) return; // ordinary `flutter test` run: nothing to do
    Directory(out).createSync(recursive: true);
    await _loadCairo();

    await t.binding.setSurfaceSize(kFilmSize);
    t.view.devicePixelRatio = 1.0;

    final frame = GlobalKey();
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFFE6E1D7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFBE8DA8)),
      ),
      home: RepaintBoundary(
        key: frame,
        child: const GameScreen(autoPlay: true, seed: 69),
      ),
    ));

    // One frame for layout before anything is grabbed.
    await t.pump(const Duration(milliseconds: 33));

    final boundary = frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    // DEMO_FRAMES exists so the pipeline can be tried on a handful of frames
    // before committing to the full film.
    final total = int.tryParse(Platform.environment['DEMO_FRAMES'] ?? '') ??
        kFilmSeconds * 60;
    // DEMO_FROM skips the PNG work on early frames while still pumping them, so
    // a copy change can be re-filmed as a tail instead of as another 30 minutes.
    final from = int.tryParse(Platform.environment['DEMO_FROM'] ?? '') ?? 0;
    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < total; i++) {
      await t.pump(const Duration(microseconds: 16667));
      if (i < from) continue;
      // Rasterising is real asynchronous work, and the test binding runs the
      // body inside a fake-async zone where such a future never settles.
      // runAsync steps outside that zone for the duration of the capture.
      final bytes = await t.runAsync<Uint8List>(() async {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (data == null) throw StateError('PNG encoding returned nothing');
        return data.buffer.asUint8List();
      });
      // runAsync answers null if the test ends underneath it.
      if (bytes == null) throw StateError('capture interrupted at frame $i');
      File('$out/${i.toString().padLeft(5, '0')}.png').writeAsBytesSync(bytes);
      if (i % 300 == 0) {
        print('frame $i/$total  ${stopwatch.elapsed.inSeconds}s elapsed');
      }
    }
    print('wrote ${total - from} of $total frames to $out '
        'in ${stopwatch.elapsed.inSeconds}s');
  }, timeout: const Timeout(Duration(minutes: 30)));
}
