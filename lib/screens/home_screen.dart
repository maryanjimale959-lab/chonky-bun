import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/palette.dart';
import '../game/painter.dart';
import '../state/save.dart';
import '../ui/kit.dart';
import 'game_screen.dart';
import 'onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(
        vsync: this, duration: const Duration(seconds: 24))
      ..repeat();
    // ?play=1 opens straight into a run, ?guide=1 opens the how-to first
    final q = Uri.base.queryParameters;
    if (q['play'] == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    } else if (q['guide'] == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openOnboarding());
    } else if (!Save.seenOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openOnboarding());
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  Future<void> _openOnboarding() async {
    await Navigator.of(context).push(PageBuilderRoute(
        child: const OnboardingScreen(), alignment: AlignmentDirectional.centerStart));
  }

  void _play() {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => const GameScreen(),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pal.paper,
      body: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final time = _t.value * 24;
          return LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth / box.maxHeight > 1.18;
            final pad = MediaQuery.of(context).padding;
            final hero = _Hero(time: time, wide: wide);
            return SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                        painter: BackdropPainter(camX: time * 26, topBand: 0.72)),
                  ),
                  // solid ground band
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: wide ? 46 : 74,
                    child: const ColoredBox(color: Pal.base),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    top: pad.top > 0 ? 0 : 10,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Caps('ROOFTOP RUN · سطح', size: 9, color: Pal.graphite),
                        HatchBox(size: 26, gap: 5, color: Pal.graphite),
                      ],
                    ),
                  ),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: box.maxWidth * 0.56,
                          child: _copy(box.maxHeight * 0.34),
                        ),
                        Expanded(child: hero),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Expanded(
                          child: Align(
                              alignment: Alignment.bottomLeft,
                              child: _copy(box.maxHeight * 0.30)),
                        ),
                        SizedBox(height: box.maxHeight * 0.26, child: hero),
                      ],
                    ),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _copy(double scale) {
    final big = (scale * 0.30).clamp(38.0, 76.0);
    return Container(
      // paper plate: the type always sits on clean cream, never on the city
      color: Pal.cream,
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Caps(S.concept, size: 9, color: Pal.grey, spacing: 4.2),
          const SizedBox(height: 8),
          Text(
            'MUNCHI',
            style: TextStyle(
              fontFamily: Type.family,
              fontSize: big,
              height: 0.86,
              fontWeight: FontWeight.w800,
              color: Pal.black,
              letterSpacing: -1.2,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'BUN',
                style: TextStyle(
                  fontFamily: Type.family,
                  fontSize: big,
                  height: 0.86,
                  fontWeight: FontWeight.w400,
                  color: Pal.black,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: EdgeInsets.only(bottom: big * 0.18),
                child: Container(
                    width: big * 0.16,
                    height: big * 0.16,
                    decoration:
                        const BoxDecoration(color: Pal.accent, shape: BoxShape.circle)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            S.titleAr,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: Type.family,
              fontSize: (big * 0.36).clamp(16.0, 26.0),
              fontWeight: FontWeight.w600,
              color: Pal.graphite,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            S.tagline,
            style: TextStyle(
                fontFamily: Type.family,
                fontSize: 12,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
                color: Pal.black),
          ),
          Text(
            S.taglineAr,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
                fontFamily: Type.family,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Pal.grey),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, c) {
              final play = PillButton(
                  label: S.play,
                  labelAr: S.playAr,
                  height: 60,
                  expand: true,
                  onTap: _play);
              final how = PillButton(
                label: S.howToPlay,
                labelAr: S.howToPlayAr,
                height: 60,
                expand: true,
                filled: false,
                onTap: _openOnboarding,
              );
              if (c.maxWidth < 430) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [play, const SizedBox(height: 10), how],
                );
              }
              return Row(
                children: [
                  Expanded(child: play),
                  const SizedBox(width: 12),
                  Expanded(child: how),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat(S.best, '${Save.best}m'),
              const SizedBox(width: 26),
              _stat(S.carrots, '${Save.totalCarrots}'),
            ],
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  static Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Caps(label, size: 8.5, color: Pal.grey, spacing: 2.4),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontFamily: Type.family,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Pal.black,
              height: 1.0,
            ),
          ),
        ],
      );
}

/// The bun, standing on a rooftop lip with a carrot floating past.
class _Hero extends StatelessWidget {
  const _Hero({required this.time, required this.wide});
  final double time;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final w = wide ? 0.62 : 0.52;
    return CustomPaint(
      painter: _HeroPainter(time: time, weight: 0.62, k: w),
      size: Size.infinite,
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({required this.time, required this.weight, required this.k});
  final double time;
  final double weight;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.shortestSide / 260) * (0.9 + k * 0.5);
    final cx = size.width * 0.5;
    final base = size.height * 0.86;

    // rooftop slab the hero stands on
    final slabW = size.width * 0.78;
    canvas.drawRect(
      Rect.fromLTWH(cx - slabW / 2, base, slabW, size.height - base),
      Paint()..color = Pal.roof,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - slabW / 2 - 6, base - 7, slabW + 12, 8),
        Radius.circular(2),
      ),
      Paint()..color = Pal.base,
    );

    // floating carrot
    final bob = 12 * (0.5 + 0.5 * (time % 4) / 4);
    paintCarrot(
        canvas, cx + slabW * 0.34, base - 70 * scale - bob * 0.4, scale * 1.15,
        rot: 0.2);

    canvas.save();
    canvas.translate(cx - slabW * 0.06, base - 2);
    canvas.scale(scale, -scale);
    paintBun(
      canvas,
      BunPose(
        weight: weight,
        phase: time * 3.2,
        blink: (time % 5) > 4.86 ? 1 : 0,
      ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) =>
      old.time != time || old.k != k || old.weight != weight;
}

/// Shared fade+slide route used by the menu screens.
class PageBuilderRoute extends PageRouteBuilder {
  PageBuilderRoute({required Widget child, AlignmentDirectional alignment = AlignmentDirectional.centerStart})
      : super(
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, _, _) => child,
          transitionsBuilder: (_, anim, _, c) {
            final curved =
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.06), end: Offset.zero)
                    .animate(curved),
                child: c,
              ),
            );
          },
        );
}
