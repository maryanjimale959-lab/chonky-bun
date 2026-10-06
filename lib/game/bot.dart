import 'dart:math' as math;

import 'sim.dart';

/// A competent autopilot, used to film demo footage and to benchmark level
/// generation. Unlike the deliberately naive player in `tool/playtest.dart`,
/// this one solves the jump it is about to make.
///
/// The physics make the decision tractable. A jump always leaves the ground at
/// full velocity for the current weight, and releasing halves it mid-flight, so
/// the only real choice is *when to leave the ground*.
///
/// Height gained after travelling `d` units is
///
///     h(d) = v * (d/speed) - gravity * (d/speed)^2 / 2
///
/// which is a parabola in `d`. Clearing the next roof means crossing its wall
/// while `h` is above that roof's top, so the takeoff points that work form a
/// window: too early and you are already falling below the lip, too late and
/// you never got high enough. The bot jumps at the late edge of that window,
/// padded, because a later takeoff lands sooner and the roof on the far side is
/// usually short enough that an early one sails past it and into the next pit.
class Bot {
  Bot(this.sim, {this.pad = 26, this.landingLead = 34, this.clearance = 10});

  final GameSim sim;

  /// Units of margin inside the safe takeoff window.
  final double pad;

  /// Units past the far roof's lip at which the jump is cut short.
  final double landingLead;

  /// How far above the next roof top to cross its wall.
  final double clearance;

  /// Advance the autopilot by one frame. Call before [GameSim.update].
  void step() {
    final s = sim;
    if (s.end != End.running) return;

    if (s.grounded) {
      final g = s.ground;
      if (g == null) return;
      final target = _after(s, g);
      if (target == null) return;

      final v = GameSim.jumpVelFor(s.weight);
      final reach = GameSim.jumpReach(s.weight, s.speed);
      final step = target.top - g.top;
      final d0 = target.x0 - s.x; // how far the wall still is

      // Late edge of the window: the largest height requirement is met exactly
      // `clearance` above the lip, solved for the smaller of the two roots.
      final req = math.max(1.0, step + clearance);
      final disc = v * v - 2 * GameSim.gravity * req;
      final lateEdge = disc <= 0
          ? double.infinity // the step is unclimbable at this weight
          : s.speed * (v - math.sqrt(disc)) / GameSim.gravity;

      final mustClearWall = d0 <= lateEdge + pad;
      // Do not leave the ground so early that the arc bottoms out short of the
      // far lip; that is a fall, not a jump.
      final landsPastWall = reach * 0.85 >= d0;
      final atLip = g.x1 - s.x <= 6;

      if (atLip || (mustClearWall && landsPastWall)) s.press();
      return;
    }

    // Airborne: cut the jump once the roof we aimed for is under us, so a short
    // roof does not throw us into the pit behind it.
    if (s.holding) {
      final land = _reachable(s);
      if (land != null && s.x > land.x0 + landingLead) s.release();
    }
  }

  /// First roof starting after [g], or null if none is generated yet.
  static Roof? _after(GameSim s, Roof g) {
    Roof? best;
    for (final r in s.roofs) {
      if (r.x0 <= g.x1) continue;
      if (best == null || r.x0 < best.x0) best = r;
    }
    return best;
  }

  /// Any roof still extending past the bot - one it could land on.
  static Roof? _reachable(GameSim s) {
    Roof? best;
    for (final r in s.roofs) {
      if (r.x1 <= s.x) continue;
      if (best == null || r.x0 < best.x0) best = r;
    }
    return best;
  }
}
