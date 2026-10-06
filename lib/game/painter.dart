import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart' show CustomPainter;

import '../core/palette.dart';
import 'sim.dart';

/// Maps world units (y up, baseline at world y = -40) to the canvas.
class View {
  View(this.size) {
    final tall = size.height > size.width * 1.1;
    // A phone held upright shows less horizontal road, so the world is drawn
    // larger and the action band is lifted off the bottom edge.
    s = math.min(size.width / (tall ? 560 : 700), size.height / 520);
    viewW = size.width / s;
    final band = 560 * s;
    anchor = size.height - math.max(0.0, (size.height - band) * 0.22);
  }

  final Size size;
  late final double s;
  late final double viewW;
  late final double anchor;
  double camX = 0;

  double x(double wx) => (wx - camX) * s;
  double y(double wy) => anchor - (wy + 40) * s;
  Offset p(double wx, double wy) => Offset(x(wx), y(wy));
  double get left => camX;
  double get right => camX + viewW;
}

class BunPose {
  const BunPose({
    required this.weight,
    this.phase = 0,
    this.squash = 0,
    this.vy = 0,
    this.grounded = true,
    this.blink = 0,
    this.dizzy = false,
    this.pulse = 0,
  });

  final double weight;
  final double phase;
  final double squash;
  final double vy;
  final bool grounded;
  final double blink;
  final bool dizzy;
  final double pulse;
}

/// Draws the rabbit at the origin: feet at (0, 0), y pointing UP in world
/// units, facing +x. The caller owns the canvas transform.
void paintBun(Canvas c, BunPose pose) {
  final w = pose.weight;
  final bodyLen = 46.0 + 26.0 * w;
  final bodyH = 40.0 + 15.0 * w;
  final bob = pose.grounded ? math.sin(pose.phase * 2) * 1.8 : 0.0;
  final belly = 1 + 0.05 * w * math.sin(pose.phase * 1.4);

  var sxScale = 1.0;
  var syScale = 1.0;
  if (pose.squash > 0) {
    sxScale = 1 + pose.squash * 0.20;
    syScale = 1 - pose.squash * 0.17;
  } else if (pose.squash < 0) {
    sxScale = 1 + pose.squash * 0.15;
    syScale = 1 - pose.squash * 0.24;
  }
  if (pose.pulse > 0) {
    sxScale *= 1 + pose.pulse * 0.05;
    syScale *= 1 + pose.pulse * 0.05;
  }

  c.save();
  c.scale(sxScale, syScale);
  c.translate(0, bob);

  final hipY = bodyH * 0.46;
  final headR = 15.0 + 3.5 * w;
  final headX = bodyLen * 0.44;
  final headY = bodyH * 0.80 + 2;
  final air = !pose.grounded;
  final lift = math.max(-1.0, math.min(1.0, pose.vy / 900));

  // ---- legs ----------------------------------------------------------------
  // angle 0 = straight down, positive = foot swings forward (+x)
  void leg(double hx, double hy, double ang, double len, double wd, Color col) {
    c.save();
    c.translate(hx, hy);
    c.rotate(ang);
    final r = RRect.fromRectAndRadius(
      Rect.fromLTRB(-wd / 2, -len, wd / 2, 0),
      Radius.circular(wd / 2),
    );
    c.drawRRect(r, Paint()..color = col);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-wd / 2, -len, wd / 2, 0),
        Radius.circular(wd / 2),
      ),
      Paint()
        ..color = Pal.black
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    c.restore();
  }

  final ph = pose.phase;
  final swingA = air ? 0.80 - 0.45 * lift : math.sin(ph) * 0.62;
  final swingB = air ? -0.70 - 0.45 * lift : math.sin(ph + math.pi) * 0.62;
  // the hip sits at hipY, so a leg of this length puts the foot on the ground
  final legLen = hipY - 1.5;
  final legW = 8.0 + 2.6 * w;
  leg(-bodyLen * 0.30, hipY - 2, swingB * 0.9, legLen * 0.98, legW, Inky.furShade);
  leg(bodyLen * 0.16, hipY - 4, swingA * 0.8, legLen * 0.92, legW * 0.86,
      Inky.furShade);

  // ---- body silhouette -----------------------------------------------------
  final parts = <Path>[
    Path()
      ..addOval(Rect.fromLTWH(-bodyLen * 0.58, hipY - bodyH * 0.44 * belly,
          bodyLen * 0.86, bodyH * 0.90 * belly)),
    Path()
      ..addOval(Rect.fromLTWH(
          -bodyLen * 0.05, hipY - bodyH * 0.30, bodyLen * 0.60, bodyH * 0.66)),
    Path()..addOval(Rect.fromCircle(center: Offset(headX, headY), radius: headR)),
    Path()
      ..addOval(Rect.fromCircle(
          center: Offset(headX + headR * 0.72, headY - headR * 0.28),
          radius: headR * 0.55)),
  ];
  if (w > 0.3) {
    parts.add(Path()
      ..addOval(Rect.fromLTWH(
          -bodyLen * 0.42, hipY - bodyH * 0.42, bodyLen * 0.80, bodyH * 0.52)));
  }
  var body = parts.first;
  for (var i = 1; i < parts.length; i++) {
    body = Path.combine(PathOperation.union, body, parts[i]);
  }

  final fur = Paint()..color = Pal.cream;
  final line = Paint()
    ..color = Pal.black
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeJoin = ui.StrokeJoin.round;

  // tail puff
  c.drawCircle(
      Offset(-bodyLen * 0.60, hipY + bodyH * 0.10), 7.0 + 1.5 * w, fur);
  c.drawCircle(
      Offset(-bodyLen * 0.60, hipY + bodyH * 0.10), 7.0 + 1.5 * w, line);

  // ears, swept by vertical speed
  final earLen = 31.0 - 7.0 * w;
  for (var i = 0; i < 2; i++) {
    c.save();
    c.translate(headX - 3.0 + i * 6.5, headY + headR * 0.72);
    final sweep = 0.26 + 0.95 * lift + i * 0.20 +
        (pose.grounded ? math.sin(ph * 0.9 + i) * 0.10 : 0.0);
    c.rotate(sweep);
    final ear = Path()
      ..addOval(Rect.fromLTWH(-3.4 - i * 0.4, 0, 7.0 + i * 0.8, earLen));
    c.drawPath(ear, fur);
    c.drawPath(ear, line);
    if (i == 1) {
      c.drawOval(
        Rect.fromLTWH(-1.5, 6.0, 3.0, earLen - 13),
        Paint()..color = Pal.accent.withValues(alpha: 0.5),
      );
    }
    c.restore();
  }

  c.drawPath(body, fur);
  if (w > 0.55) {
    // heavy belly shadow
    c.save();
    c.clipPath(body);
    c.drawOval(
      Rect.fromLTWH(-bodyLen * 0.40, hipY - bodyH * 0.40, bodyLen * 0.78, bodyH * 0.42),
      Paint()..color = Inky.furShade.withValues(alpha: 0.45),
    );
    c.restore();
  }

  // ---- black patches, clipped to the silhouette ----------------------------
  c.save();
  c.clipPath(body);
  void patch(double cx, double cy, double rx, double ry, [double rot = 0]) {
    c.save();
    c.translate(cx, cy);
    c.rotate(rot);
    c.drawOval(Rect.fromLTWH(-rx, -ry, rx * 2, ry * 2), Paint()..color = Pal.black);
    c.restore();
  }

  patch(-bodyLen * 0.26, hipY + bodyH * 0.40, bodyLen * 0.20, bodyH * 0.20, -0.25);
  patch(-bodyLen * 0.50, hipY + bodyH * 0.02, bodyLen * 0.14, bodyH * 0.16, 0.3);
  patch(headX + headR * 0.10, headY + headR * 0.55, headR * 0.62, headR * 0.52, 0.2);
  c.restore();

  c.drawPath(body, line);

  // front legs ride on top of the patches, so they read as legs and not holes
  leg(-bodyLen * 0.02, hipY - 2, swingA * 0.95, legLen, legW, Pal.cream);
  leg(bodyLen * 0.30, hipY - 4, swingB * 1.05, legLen * 0.90, legW * 0.88,
      Pal.cream);

  // ---- face ----------------------------------------------------------------
  final eyeX = headX + headR * 0.42;
  final eyeY = headY + headR * 0.16;
  if (pose.dizzy) {
    final e = Paint()
      ..color = Pal.black
      ..strokeWidth = 1.8
      ..style = ui.PaintingStyle.stroke;
    c.drawLine(Offset(eyeX - 3, eyeY - 3), Offset(eyeX + 3, eyeY + 3), e);
    c.drawLine(Offset(eyeX - 3, eyeY + 3), Offset(eyeX + 3, eyeY - 3), e);
  } else if (pose.blink > 0.5) {
    c.drawLine(Offset(eyeX - 2.6, eyeY), Offset(eyeX + 2.6, eyeY),
        Paint()..color = Pal.black..strokeWidth = 1.8);
  } else {
    c.drawCircle(Offset(eyeX, eyeY), 2.5, Paint()..color = Pal.black);
    c.drawCircle(Offset(eyeX + 0.9, eyeY + 0.9), 0.8, Paint()..color = Pal.cream);
  }

  final noseX = headX + headR * 1.16;
  final noseY = headY - headR * 0.26;
  c.drawCircle(Offset(noseX, noseY), 2.0, Paint()..color = Pal.black);
  final whisker = Paint()
    ..color = Pal.black
    ..strokeWidth = 1.0;
  for (var i = -1; i <= 1; i++) {
    c.drawLine(Offset(noseX + 1, noseY + i * 1.6),
        Offset(noseX + 11, noseY + i * 4.4), whisker);
  }
  // mouth
  c.drawArc(
    Rect.fromCircle(center: Offset(noseX - 2.4, noseY - 2.6), radius: 3.0),
    3.6,
    1.2,
    false,
    whisker,
  );

  c.restore();
}

class Inky {
  Inky._();
  static const Color furShade = Color(0xFFD9D5C9);
  static const Color windowDark = Color(0xFF1C1C1C);
  static const Color windowLit = Color(0xFFEDE8DC);
}

// ---- shared backdrop (also used by the menus) ----------------------------------------------------------
void paintSky(Canvas c, View v) {
  final rect = Offset.zero & v.size;
  c.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        const [Pal.cream, Pal.paper, Color(0xFFDBD6CA)],
        [0.0, 0.5, 1.0],
      ),
  );
  // low sun disc, barely parallaxed
  final sx = v.x(0) + v.size.width * 0.72;
  final sy = v.size.height * (v.size.height > v.size.width ? 0.2 : 0.16);
  c.drawCircle(
    Offset(sx, sy),
    v.s * 74,
    Paint()..color = Pal.cream.withValues(alpha: 0.9),
  );
  c.drawCircle(
    Offset(sx, sy),
    v.s * 74,
    Paint()
      ..color = Pal.black.withValues(alpha: 0.10)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
}

void paintClouds(Canvas c, View v) {
  final off = v.camX * 0.16;
  for (var i = 0; i < 9; i++) {
    final r = math.Random(i * 313 + 5);
    final wx = i * 340 + r.nextDouble() * 200 - off;
    final wy = 380 + r.nextDouble() * 150;
    final wdt = 90 + r.nextDouble() * 130;
    final x0 = ((wx % (v.viewW + 900)) + v.viewW + 900) % (v.viewW + 900) - 300;
    final p = Paint()..color = Pal.cream.withValues(alpha: 0.55);
    final cx = v.x(x0 + v.camX);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - wdt / 2 * v.s, v.y(wy), wdt * v.s, 16 * v.s),
        Radius.circular(9 * v.s),
      ),
      p,
    );
    c.drawCircle(Offset(cx + wdt * 0.18 * v.s, v.y(wy + 8)), 13 * v.s, p);
    c.drawCircle(Offset(cx - wdt * 0.16 * v.s, v.y(wy + 6)), 9 * v.s, p);
  }
}

void paintSkyline(Canvas c, View v, double par, Color col, double hMin, double hMax,
    double tile, bool windows, int seed) {
  final off = v.camX * par;
  final i0 = ((off - 300) / tile).floor();
  final i1 = ((off + v.viewW + 300) / tile).floor();
  for (var i = i0; i <= i1; i++) {
    final r = math.Random(i * 7919 + seed);
    final h = hMin + r.nextDouble() * (hMax - hMin);
    final wdt = tile * (0.66 + r.nextDouble() * 0.32);
    final wx = i * tile + r.nextDouble() * (tile - wdt);
    final top = v.y(h);
    final rect = Rect.fromLTWH(
      (wx - off) * v.s,
      top,
      wdt * v.s,
      v.size.height - top + 20,
    );
    c.drawRect(rect, Paint()..color = col);
    // roof cap
    c.drawRect(
      Rect.fromLTWH(rect.left - 2 * v.s, rect.top, rect.width + 4 * v.s, 5 * v.s),
      Paint()..color = Color.lerp(col, Pal.black, 0.22)!,
    );
    if (r.nextDouble() < 0.35) {
      // antenna / mast
      final mx = rect.left + rect.width * (0.2 + r.nextDouble() * 0.6);
      final mh = (18 + r.nextDouble() * 34) * v.s;
      c.drawLine(
        Offset(mx, rect.top),
        Offset(mx, rect.top - mh),
        Paint()
          ..color = Color.lerp(col, Pal.black, 0.4)!
          ..strokeWidth = 2.0 * v.s,
      );
    }
    if (windows) {
      paintWindows(c, v, rect, col, r, dark: false);
    }
  }
}

void paintWindows(Canvas c, View v, Rect b, Color col, math.Random r, {required bool dark}) {
  final stepX = 27 * v.s;
  final stepY = 32 * v.s;
  final cols = (b.width / stepX).floor();
  final rows = (b.height / stepY).floor();
  if (cols < 1 || rows < 1) return;
  final wW = 7.5 * v.s, wH = 12.5 * v.s;
  final x0 = b.left + (b.width - (cols - 1) * stepX) / 2;
  final y0 = b.top + stepY * 0.5;
  for (var i = 0; i < cols; i++) {
    for (var j = 0; j < rows; j++) {
      final lit = r.nextDouble() < 0.18;
      final paint = Paint()
        ..color = dark
            ? (lit ? Inky.windowLit : Inky.windowDark)
            : Color.lerp(col, lit ? Inky.windowLit : Pal.black, 0.5)!;
      c.drawRect(
        Rect.fromCenter(
          center: Offset(x0 + i * stepX, y0 + j * stepY),
          width: wW,
          height: wH,
        ),
        paint,
      );
    }
  }
}



class WorldPainter extends CustomPainter {
  WorldPainter({required this.sim, required this.time});

  final GameSim sim;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final v = View(size);
    v.camX = sim.x - v.viewW * 0.30;

    paintSky(canvas, v);
    paintClouds(canvas, v);
    paintSkyline(canvas, v, 0.28, Pal.far, 150, 300, 168, false, 11);
    paintSkyline(canvas, v, 0.48, Pal.mid, 130, 330, 150, true, 23);
    paintSkyline(canvas, v, 0.72, Pal.near, 120, 320, 138, true, 37);
    _buildings(canvas, v);
    _zoneFlags(canvas, v);
    _carrots(canvas, v);
    _particles(canvas, v, 0);
    _shadow(canvas, v);
    _bun(canvas, v);
    _particles(canvas, v, 1);
    _speedLines(canvas, v);
  }

  // ---- play layer ----------------------------------------------------------
  void _buildings(Canvas c, View v) {
    for (final r in sim.roofs) {
      if (r.x1 < v.left - 200 || r.x0 > v.right + 200) continue;
      final left = v.x(r.x0);
      final right = v.x(r.x1);
      final top = v.y(r.top);
      final body = Rect.fromLTWH(left, top, right - left, v.size.height - top + 4);
      c.drawRect(body, Paint()..color = Pal.roof);
      // overhanging slab
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left - 7 * v.s, top - 7 * v.s, (right - left) + 14 * v.s, 8 * v.s),
          Radius.circular(2 * v.s),
        ),
        Paint()..color = Pal.base,
      );
      paintWindows(c, v, body.shift(Offset(0, 10 * v.s)), Pal.roof,
          math.Random(r.seed),
          dark: true);
      _roofKit(c, v, r);
      // building base shadow band, always run down to the bottom edge
      final baseTop = v.y(-6);
      c.drawRect(
        Rect.fromLTWH(left, baseTop, right - left, v.size.height - baseTop + 40),
        Paint()..color = Pal.base,
      );
    }
  }

  void _roofKit(Canvas c, View v, Roof r) {
    final rnd = math.Random(r.seed);
    final top = v.y(r.top);
    final x0 = v.x(r.x0);
    final w = (r.x1 - r.x0) * v.s;

    // door block
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x0 + w * 0.12, top - 22 * v.s, 16 * v.s, 22 * v.s),
        Radius.circular(2 * v.s),
      ),
      Paint()..color = Pal.base,
    );

    if (rnd.nextDouble() < 0.62) {
      // water tower
      final cx = x0 + w * (0.55 + rnd.nextDouble() * 0.3);
      final h = 46.0;
      final tankW = 30.0;
      final base = top - 16 * v.s;
      final leg = Paint()
        ..color = Pal.base
        ..strokeWidth = 2.4 * v.s;
      c.drawLine(Offset(cx - tankW * 0.36 * v.s, base), Offset(cx - tankW * 0.28 * v.s, base - h * 0.6 * v.s), leg);
      c.drawLine(Offset(cx + tankW * 0.36 * v.s, base), Offset(cx + tankW * 0.28 * v.s, base - h * 0.6 * v.s), leg);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - tankW / 2 * v.s, base - h * v.s, tankW * v.s, h * 0.66 * v.s),
          Radius.circular(4 * v.s),
        ),
        Paint()..color = Pal.base,
      );
      c.drawPath(
        Path()
          ..moveTo(cx - tankW / 2 * v.s, base - h * v.s)
          ..lineTo(cx, base - (h + 13) * v.s)
          ..lineTo(cx + tankW / 2 * v.s, base - h * v.s)
          ..close(),
        Paint()..color = Pal.graphite,
      );
    }

    if (rnd.nextDouble() < 0.5) {
      // vent / AC unit
      final cx = x0 + w * (0.28 + rnd.nextDouble() * 0.2);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, top - 15 * v.s, 22 * v.s, 15 * v.s),
          Radius.circular(2 * v.s),
        ),
        Paint()..color = Pal.base,
      );
      final slat = Paint()
        ..color = Inky.windowLit.withValues(alpha: 0.5)
        ..strokeWidth = 1.2 * v.s;
      for (var i = 1; i < 4; i++) {
        c.drawLine(Offset(cx + 3 * v.s, top - 15 * v.s + i * 3.4 * v.s),
            Offset(cx + 19 * v.s, top - 15 * v.s + i * 3.4 * v.s), slat);
      }
    }

    if (rnd.nextDouble() < 0.42 && w > 200 * v.s) {
      // vertical shop sign with abstract glyph marks
      final cx = x0 + w * (0.62 + rnd.nextDouble() * 0.25);
      final sw = 20.0, sh = 62.0;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, top - (sh + 20) * v.s, sw * v.s, sh * v.s),
          Radius.circular(3 * v.s),
        ),
        Paint()..color = Pal.paper,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, top - (sh + 20) * v.s, sw * v.s, sh * v.s),
          Radius.circular(3 * v.s),
        ),
        Paint()
          ..color = Pal.base
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.0 * v.s,
      );
      c.drawRect(
        Rect.fromLTWH(cx + sw * 0.44 * v.s, top - 20 * v.s, 2.4 * v.s, 20 * v.s),
        Paint()..color = Pal.base,
      );
      final glyph = Paint()..color = Pal.base;
      var gy = top - (sh + 20) * v.s + 8 * v.s;
      for (var i = 0; i < 4; i++) {
        final gw = (6 + rnd.nextDouble() * 8) * v.s;
        c.drawRect(Rect.fromLTWH(cx + (sw * 0.5) * v.s - gw / 2, gy, gw, 2.6 * v.s), glyph);
        if (i == 1) {
          c.drawCircle(Offset(cx + sw * 0.5 * v.s, gy + 5 * v.s), 2.6 * v.s, glyph);
        }
        gy += 12 * v.s;
      }
    }

    if (rnd.nextDouble() < 0.35) {
      // railing along part of the edge
      final rx0 = x0 + w * (0.05 + rnd.nextDouble() * 0.4);
      final len = w * (0.12 + rnd.nextDouble() * 0.16);
      final rail = Paint()
        ..color = Pal.base
        ..strokeWidth = 1.6 * v.s;
      for (var k = 0; k < 5; k++) {
        final px = rx0 + k * len / 4;
        c.drawLine(Offset(px, top), Offset(px, top - 11 * v.s), rail);
      }
      c.drawLine(Offset(rx0, top - 11 * v.s), Offset(rx0 + len, top - 11 * v.s), rail);
    }
  }

  // ---- objects -------------------------------------------------------------
  void _zoneFlags(Canvas c, View v) {
    for (var z = sim.zones; z <= sim.zones + 2; z++) {
      if (z <= 0) continue;
      final wx = sim.zoneWorldX(z);
      final r = sim.zoneRoof(z);
      if (r == null) continue;
      final px = v.x(wx);
      final base = v.y(r.top);
      final pole = Paint()
        ..color = Pal.base
        ..strokeWidth = 3.0 * v.s;
      c.drawLine(Offset(px, base), Offset(px, base - 130 * v.s), pole);
      final passed = sim.x > wx;
      c.drawPath(
        Path()
          ..moveTo(px, base - 130 * v.s)
          ..lineTo(px + 44 * v.s, base - 118 * v.s)
          ..lineTo(px, base - 104 * v.s)
          ..close(),
        Paint()..color = passed ? Pal.grey : Pal.accent,
      );
      c.drawCircle(Offset(px, base - 132 * v.s), 3.2 * v.s, Paint()..color = Pal.base);
    }
  }

  void _carrots(Canvas c, View v) {
    for (final c0 in sim.carrots) {
      if (c0.eaten) continue;
      if (c0.x < v.left - 100 || c0.x > v.right + 100) continue;
      final bob = math.sin(time * 2.4 + c0.x * 0.05) * 3.0;
      paintCarrot(c, v.x(c0.x), v.y(c0.y + bob), v.s, rot: math.sin(time * 1.6 + c0.x) * 0.16);
    }
  }

  void _shadow(Canvas c, View v) {
    final r = sim.roofAt(sim.x);
    final h = r == null ? 999.0 : math.max(0, sim.y - r.top);
    final k = math.max(0.15, 1 - h / 220);
    final gy = r != null ? r.top : (sim.ground?.top ?? sim.y);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(v.x(sim.x), v.y(gy) - 2 * v.s),
        width: (58 + 26 * sim.weight) * v.s * k,
        height: 9 * v.s * k,
      ),
      Paint()..color = Pal.black.withValues(alpha: 0.22 * k),
    );
  }

  void _bun(Canvas c, View v) {
    c.save();
    c.translate(v.x(sim.x), v.y(sim.y));
    final tilt = sim.end == End.running
        ? (sim.grounded ? 0.0 : (-sim.vy / 2600)).clamp(-0.16, 0.20)
        : 0.35;
    c.rotate(tilt);
    c.scale(v.s, -v.s);
    paintBun(
      c,
      BunPose(
        weight: sim.weight,
        phase: sim.wobble,
        squash: sim.squash,
        vy: sim.vy,
        grounded: sim.grounded,
        blink: math.sin(time * 1.7) > 0.985 ? 1 : 0,
        dizzy: sim.end != End.running,
        pulse: sim.eatPulse,
      ),
    );
    c.restore();
  }

  void _speedLines(Canvas c, View v) {
    if (!sim.grounded || sim.speedNorm < 0.25) return;
    final p = Paint()
      ..color = Pal.black.withValues(alpha: 0.22 + 0.2 * sim.speedNorm)
      ..strokeWidth = 1.6 * v.s;
    for (var i = 0; i < 3; i++) {
      final y = v.y(sim.y + 14 + i * 12);
      final x1 = v.x(sim.x - 46 - i * 6);
      final len = (16 + 14 * sim.speedNorm + 6 * math.sin(time * 9 + i)) * v.s;
      c.drawLine(Offset(x1 - len, y), Offset(x1, y), p);
    }
  }

  void _particles(Canvas c, View v, int layer) {
    for (final p in sim.particles) {
      final isSpark = p.kind == 1;
      if ((layer == 0) == isSpark) continue;
      final a = math.max(0.0, p.life / p.maxLife);
      if (p.kind == 1) {
        c.save();
        c.translate(v.x(p.x), v.y(p.y));
        c.rotate(a * 3.0);
        c.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size * v.s, height: p.size * v.s),
          Paint()..color = Pal.accentDeep.withValues(alpha: a),
        );
        c.restore();
      } else if (p.kind == 2) {
        c.drawCircle(Offset(v.x(p.x), v.y(p.y)), p.size * v.s * (0.6 + a * 0.6),
            Paint()..color = Pal.cream.withValues(alpha: a * 0.9));
        c.drawCircle(Offset(v.x(p.x), v.y(p.y)), p.size * v.s * (0.6 + a * 0.6),
            Paint()
              ..color = Pal.black.withValues(alpha: a * 0.5)
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1.2 * v.s);
      } else {
        c.drawCircle(Offset(v.x(p.x), v.y(p.y)), p.size * v.s * (0.5 + a),
            Paint()..color = Pal.black.withValues(alpha: a * 0.28));
      }
    }
  }

  @override
  bool shouldRepaint(covariant WorldPainter old) => true;
}

/// A carrot: tapered root in the accent colour plus dark leaves.
void paintCarrot(Canvas c, double cx, double cy, double s, {double rot = 0}) {
  c.save();
  c.translate(cx, cy);
  c.rotate(rot);
  final body = Path()
    ..moveTo(-5.2 * s, -9 * s)
    ..quadraticBezierTo(6.4 * s, -8 * s, 5.0 * s, 1.0 * s)
    ..quadraticBezierTo(4.0 * s, 10.0 * s, 0.4 * s, 14.4 * s)
    ..quadraticBezierTo(-3.4 * s, 9.0 * s, -5.4 * s, 0.0 * s)
    ..close();
  c.drawPath(body, Paint()..color = Pal.accent);
  c.drawPath(
    body,
    Paint()
      ..color = Pal.black
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.8 * s,
  );
  final ring = Paint()
    ..color = Pal.accentDeep
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.1 * s;
  c.drawLine(Offset(-3.4 * s, -3.0 * s), Offset(3.6 * s, -2.2 * s), ring);
  c.drawLine(Offset(-2.6 * s, 2.6 * s), Offset(3.0 * s, 3.2 * s), ring);
  final leaf = Paint()
    ..color = Pal.black
    ..strokeWidth = 2.0 * s
    ..strokeCap = ui.StrokeCap.round;
  c.drawLine(Offset(-1.0 * s, -9 * s), Offset(-5.4 * s, -17 * s), leaf);
  c.drawLine(Offset(0.2 * s, -9.4 * s), Offset(0.6 * s, -18.6 * s), leaf);
  c.drawLine(Offset(1.6 * s, -9 * s), Offset(6.0 * s, -16.4 * s), leaf);
  c.restore();
}

/// Slow drifting city backdrop for menus, cards and onboarding art.
class BackdropPainter extends CustomPainter {
  BackdropPainter({required this.camX, this.topBand = 1.0});

  final double camX;
  final double topBand;

  @override
  void paint(Canvas canvas, Size size) {
    final v = View(size);
    v.camX = camX;
    paintSky(canvas, v);
    paintClouds(canvas, v);
    paintSkyline(canvas, v, 0.28, Pal.far, 150 * topBand, 300 * topBand, 168, false, 11);
    paintSkyline(canvas, v, 0.48, Pal.mid, 130 * topBand, 330 * topBand, 150, true, 23);
    paintSkyline(canvas, v, 0.72, Pal.near, 120 * topBand, 320 * topBand, 138, true, 37);
  }

  @override
  bool shouldRepaint(covariant BackdropPainter old) =>
      old.camX != camX || old.topBand != topBand;
}
