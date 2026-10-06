import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/palette.dart';
import '../game/painter.dart';
import '../state/save.dart';
import '../ui/kit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();
  late final AnimationController _t;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  @override
  void dispose() {
    _pages.dispose();
    _t.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await Save.markOnboarded();
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_i == 2) {
      _finish();
      return;
    }
    setState(() => _i += 1);
    _pages.animateToPage(_i,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final data = [
      [S.onb1Title, S.onb1TitleAr, S.onb1Body, S.onb1BodyAr],
      [S.onb2Title, S.onb2TitleAr, S.onb2Body, S.onb2BodyAr],
      [S.onb3Title, S.onb3TitleAr, S.onb3Body, S.onb3BodyAr],
    ];
    return Scaffold(
      backgroundColor: Pal.cream,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final time = _t.value * 6;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Caps('HOW TO PLAY', size: 9, color: Pal.grey),
                      GestureDetector(
                        onTap: _finish,
                        child: Caps(S.skip,
                            size: 9, color: Pal.grey, spacing: 2.2),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    physics: const PageScrollPhysics(),
                    onPageChanged: (i) => setState(() => _i = i),
                    itemCount: 3,
                    itemBuilder: (context, i) => _page(data[i], i, time),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 26),
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _i ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _i ? Pal.black : Pal.grey.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      const Spacer(),
                      PillButton(
                        label: _i == 2 ? S.gotIt : S.next,
                        labelAr: _i == 2 ? S.gotItAr : S.nextAr,
                        height: 54,
                        onTap: _next,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _page(List<String> d, int kind, double time) {
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth / box.maxHeight > 1.25;
      final art = Padding(
        padding: EdgeInsets.fromLTRB(28, 12, 28, 12),
        child: CustomPaint(
          painter: _OnbArt(kind: kind, t: time),
          child: SizedBox(
            width: double.infinity,
            height: wide ? box.maxHeight * 0.72 : box.maxHeight * 0.50,
          ),
        ),
      );
      final copy = Padding(
        padding: const EdgeInsets.fromLTRB(30, 6, 30, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Caps('${kind + 1} / 3', size: 9, color: Pal.accentDeep, spacing: 3),
            const SizedBox(height: 10),
            Text(d[0],
                style: const TextStyle(
                    fontFamily: Type.family,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Pal.black,
                    height: 1.05)),
            Text(d[1],
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontFamily: Type.family,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Pal.graphite)),
            const SizedBox(height: 12),
            Container(width: 42, height: 3, color: Pal.black),
            const SizedBox(height: 14),
            Text(d[2],
                style: const TextStyle(
                    fontFamily: Type.family,
                    fontSize: 14,
                    height: 1.5,
                    color: Pal.graphite)),
            const SizedBox(height: 4),
            Text(d[3],
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontFamily: Type.family,
                    fontSize: 14,
                    height: 1.6,
                    color: Pal.grey)),
          ],
        ),
      );
      if (wide) {
        return Row(
          children: [
            Expanded(child: art),
            Expanded(child: Center(child: SingleChildScrollView(child: copy))),
          ],
        );
      }
      return Column(
        children: [
          art,
          Expanded(
            child: Center(child: SingleChildScrollView(child: copy)),
          ),
        ],
      );
    });
  }
}

class _OnbArt extends CustomPainter {
  _OnbArt({required this.kind, required this.t});
  final int kind;
  final double t;

  late double s;
  late double cx;
  late double base;
  double bottom = 0;

  double X(double wx) => cx + wx * s;
  double Y(double wy) => base - wy * s;

  void _roof(Canvas c, double x0, double x1, double top) {
    final y = Y(top);
    c.drawRect(
      Rect.fromLTWH(X(x0), y, (x1 - x0) * s, bottom - y),
      Paint()..color = Pal.roof,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(X(x0) - 4, Y(top) - 6 * s, (x1 - x0) * s + 8, 6 * s),
        Radius.circular(2),
      ),
      Paint()..color = Pal.base,
    );
  }

  void _bun(Canvas c, double wx, double wy, double weight,
      {bool grounded = true, double vy = 0, double phase = 0}) {
    c.save();
    c.translate(X(wx), Y(wy));
    c.scale(s, -s);
    paintBun(c,
        BunPose(weight: weight, grounded: grounded, vy: vy, phase: phase));
    c.restore();
  }

  void _arrow(Canvas c, double wx, double from, double to, {Color? col}) {
    final p = Paint()
      ..color = col ?? Pal.black
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(X(wx), Y(from)), Offset(X(wx), Y(to)), p);
    c.drawLine(Offset(X(wx) - 5 * s, Y(to) + 7 * s), Offset(X(wx), Y(to)), p);
    c.drawLine(Offset(X(wx) + 5 * s, Y(to) + 7 * s), Offset(X(wx), Y(to)), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    s = math.min(size.width / 300, size.height / 210);
    cx = size.width / 2;
    bottom = size.height;
    base = size.height * 0.94;

    switch (kind) {
      case 0:
        _roof(canvas, -170, -34, 58);
        _roof(canvas, 46, 190, 46);
        final hop = 40 + 26 * math.sin(t * 1.6);
        _bun(canvas, 6, hop, 0.2, grounded: false, vy: 400, phase: t * 6);
        // tap ripple
        final k = (t % 1.6) / 1.6;
        canvas.drawCircle(
          Offset(X(-100), Y(150)),
          (10 + k * 26) * s,
          Paint()
            ..color = Pal.black.withValues(alpha: (1 - k) * 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * s,
        );
        _arrow(canvas, -100, 96, 132);
        break;
      case 1:
        _roof(canvas, -170, 190, 46);
        paintCarrot(canvas, X(-108), Y(120), s * 1.1);
        _bun(canvas, -108, 46, 0.08, phase: t * 7);
        _bun(canvas, -6, 46, 0.5, phase: t * 5);
        _bun(canvas, 112, 46, 0.97, phase: t * 3);
        _arrow(canvas, -60, 108, 176, col: Pal.black);
        _arrow(canvas, 52, 108, 150, col: Pal.grey);
        _arrow(canvas, 160, 108, 128, col: Pal.accentDeep);
        break;
      default:
        _roof(canvas, -190, 60, 52);
        _roof(canvas, 96, 210, 64);
        _bun(canvas, -120 + 6 * math.sin(t * 3), 52, 0.62, phase: t * 8);
        // goal flag
        final px = X(78);
        canvas.drawLine(Offset(px, Y(64)), Offset(px, Y(168)),
            Paint()..color = Pal.black..strokeWidth = 3 * s);
        final wave = 4 * math.sin(t * 3);
        canvas.drawPath(
          Path()
            ..moveTo(px, Y(168))
            ..lineTo(px + 40 * s, Y(152 + wave))
            ..lineTo(px, Y(136))
            ..close(),
          Paint()..color = Pal.accent,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _OnbArt old) => old.t != t || old.kind != kind;
}
