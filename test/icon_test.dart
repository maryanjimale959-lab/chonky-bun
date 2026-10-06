// Draws the launcher icon with the game's own art primitives, so the icon can
// never drift from the rabbit in the build.
//
//   ICON_OUT=1 flutter test test/icon_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart' show CustomPainter;
import 'package:flutter_test/flutter_test.dart';
import 'package:munchi_bun/core/palette.dart';
import 'package:munchi_bun/game/painter.dart';

class _IconPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final k = size.width / 512.0;
    c.drawRect(Offset.zero & size, Paint()..color = Pal.paper);

    // low sun disc, upper left
    c.drawCircle(Offset(150 * k, 140 * k), 92 * k,
        Paint()..color = Pal.cream.withValues(alpha: 0.85));
    c.drawCircle(
      Offset(150 * k, 140 * k),
      92 * k,
      Paint()
        ..color = Pal.black.withValues(alpha: 0.12)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2 * k,
    );

    // rooftop slab
    final top = 400.0 * k;
    c.drawRect(Rect.fromLTWH(0, top, size.width, size.height - top),
        Paint()..color = Pal.roof);
    c.drawRect(Rect.fromLTWH(26 * k, top - 12 * k, size.width - 52 * k, 12 * k),
        Paint()..color = Pal.base);
    // windows
    final win = Paint()..color = Pal.base;
    for (var i = 0; i < 6; i++) {
      for (var j = 0; j < 2; j++) {
        if ((i + j) % 3 == 0) continue;
        c.drawRect(
          Rect.fromLTWH(58 * k + i * 72 * k, top + 34 * k + j * 44 * k, 16 * k, 26 * k),
          win,
        );
      }
    }

    // the bun, feet on the slab
    c.save();
    c.translate(200 * k, top - 12 * k);
    c.scale(3.05 * k, -3.05 * k);
    paintBun(
        c, BunPose(weight: 0.52, grounded: true, phase: math.pi * 0.35));
    c.restore();

    // carrot, upper right
    paintCarrot(c, 404 * k, 214 * k, 3.4 * k, rot: 0.35);
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes launcher icons', () async {
    if (Platform.environment['ICON_OUT'] == null) return;
    const sizes = <String, int>{
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };
    final painter = _IconPainter();
    for (final e in sizes.entries) {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      painter.paint(c, Size(e.value.toDouble(), e.value.toDouble()));
      final img = await rec.endRecording().toImage(e.value, e.value);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('android/app/src/main/res/${e.key}')
        ..createSync(recursive: true);
      File('${dir.path}/ic_launcher.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    }
    // full size master, for the store listing / web
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    painter.paint(c, const Size(512, 512));
    final img = await rec.endRecording().toImage(512, 512);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/ic_master_512.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}
