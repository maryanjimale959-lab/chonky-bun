import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../game/painter.dart';

/// Letter-spaced latin caps, the voice of the concept sheet.
class Caps extends StatelessWidget {
  const Caps(this.text,
      {this.size = 10,
      this.color = Pal.black,
      this.weight = FontWeight.w600,
      this.spacing = 2.6,
      super.key});

  final String text;
  final double size;
  final Color color;
  final FontWeight weight;
  final double spacing;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: Type.family,
          fontSize: size,
          color: color,
          fontWeight: weight,
          letterSpacing: spacing,
          height: 1.1,
        ),
      );
}

/// English line with its Arabic line under it.
class Bi extends StatelessWidget {
  const Bi({
    required this.en,
    required this.ar,
    this.enSize = 10,
    this.arSize = 13,
    this.color = Pal.black,
    this.arColor = Pal.graphite,
    this.weight = FontWeight.w600,
    this.spacing = 2.6,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    super.key,
  });

  final String en;
  final String ar;
  final double enSize;
  final double arSize;
  final Color color;
  final Color arColor;
  final FontWeight weight;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Caps(en, size: enSize, color: color, weight: weight, spacing: spacing),
          const SizedBox(height: 2),
          Text(
            ar,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: Type.family,
              fontSize: arSize,
              color: arColor,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      );
}

/// Dark filled pill with English over Arabic.
class PillButton extends StatelessWidget {
  const PillButton({
    required this.label,
    required this.labelAr,
    required this.onTap,
    this.icon,
    this.height = 62,
    this.expand = false,
    this.filled = true,
    super.key,
  });

  final String label;
  final String labelAr;
  final VoidCallback onTap;
  final Widget? icon;
  final double height;
  final bool expand;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: height,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: expand ? 22 : 30),
        decoration: BoxDecoration(
          color: filled ? Pal.black : Colors.transparent,
          borderRadius: BorderRadius.circular(height / 2),
          border: filled ? null : Border.all(color: Pal.black, width: 1.6),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 12)],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: expand ? Alignment.centerLeft : Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      expand ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: Type.family,
                        fontSize: height * 0.235,
                        letterSpacing: 3.4,
                        fontWeight: FontWeight.w800,
                        color: filled ? Pal.cream : Pal.black,
                        height: 1.05,
                      ),
                    ),
                    Text(
                      labelAr,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: Type.family,
                        fontSize: height * 0.19,
                        fontWeight: FontWeight.w600,
                        color: filled
                            ? Pal.cream.withValues(alpha: 0.72)
                            : Pal.graphite,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small carrot glyph drawn with the game's own art.
class CarrotIcon extends StatelessWidget {
  const CarrotIcon(this.size, {this.dark = false, super.key});
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _CarrotIconPainter(size, dark),
      );
}

class _CarrotIconPainter extends CustomPainter {
  _CarrotIconPainter(this.size, this.dark);
  final double size;
  final bool dark;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.translate(s.width / 2, s.height / 2);
    paintCarrot(canvas, 0, 0, size / 34.0);
  }

  @override
  bool shouldRepaint(covariant _CarrotIconPainter old) =>
      old.size != size || old.dark != dark;
}

/// Static bun portrait used on home / onboarding / result cards.
class BunPortrait extends StatelessWidget {
  const BunPortrait({
    required this.width,
    this.weight = 0,
    this.phase = 0,
    this.grounded = true,
    this.vy = 0,
    this.dizzy = false,
    super.key,
  });

  final double width;
  final double weight;
  final double phase;
  final bool grounded;
  final double vy;
  final bool dizzy;

  @override
  Widget build(BuildContext context) {
    final scale = width / 120.0;
    return CustomPaint(
      size: Size(width, width * 0.95),
      painter: _BunPortraitPainter(scale, weight, phase, grounded, vy, dizzy),
    );
  }
}

class _BunPortraitPainter extends CustomPainter {
  _BunPortraitPainter(this.k, this.weight, this.phase, this.grounded, this.vy,
      this.dizzy);

  final double k;
  final double weight;
  final double phase;
  final bool grounded;
  final double vy;
  final bool dizzy;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.46, size.height * 0.92);
    canvas.scale(k, -k);
    paintBun(
      canvas,
      BunPose(
        weight: weight,
        phase: phase,
        vy: vy,
        grounded: grounded,
        dizzy: dizzy,
      ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BunPortraitPainter old) =>
      old.k != k ||
      old.weight != weight ||
      old.phase != phase ||
      old.grounded != grounded ||
      old.vy != vy ||
      old.dizzy != dizzy;
}

/// The three weight states, as in the concept sheet's CAT STATE row.
class StateStrip extends StatelessWidget {
  const StateStrip({this.scale = 1, this.active = -1, super.key});
  final double scale;
  final int active;

  @override
  Widget build(BuildContext context) {
    Widget cell(double w, String en, String ar, int i) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BunPortrait(width: 46 * scale, weight: w),
            SizedBox(height: 4 * scale),
            Caps(en, size: 8 * scale, color: Pal.graphite, spacing: 1.4),
            Text(ar,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                    fontFamily: Type.family,
                    fontSize: 10 * scale,
                    color: Pal.grey,
                    fontWeight: FontWeight.w600)),
          ],
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        cell(0.08, 'LIGHT', 'خفيف', 0),
        SizedBox(width: 10 * scale),
        cell(0.5, 'PUFFY', 'نفوخ', 1),
        SizedBox(width: 10 * scale),
        cell(0.95, 'HEAVY', 'ثقيل', 2),
      ],
    );
  }
}

/// Thin ring pulse, used behind the tap hint.
class PulseRing extends StatelessWidget {
  const PulseRing({required this.t, required this.size, super.key});
  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    final k = t - (t.floorToDouble());
    return Transform.scale(
      scale: 0.7 + k * 0.7,
      child: Opacity(
        opacity: (1 - k).clamp(0.0, 1.0),
        child: CustomPaint(size: Size.square(size), painter: _RingPainter()),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2,
      Paint()
        ..color = Pal.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width * 0.16,
      Paint()..color = Pal.black,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => false;
}

/// Diagonal hatch block, a small Bauhaus garnish.
class HatchBox extends StatelessWidget {
  const HatchBox({required this.size, this.gap = 6, this.color = Pal.black, super.key});
  final double size;
  final double gap;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: Size.square(size), painter: _HatchPainter(gap: gap, color: color));
}

class _HatchPainter extends CustomPainter {
  _HatchPainter({required this.gap, required this.color});
  final double gap;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter old) =>
      old.gap != gap || old.color != color;
}

double clampd(double v, double lo, double hi) => math.min(hi, math.max(lo, v));
