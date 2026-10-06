import 'dart:math' as math;

/// Why the run ended.
enum End { running, fell, bumped }

class Roof {
  Roof(this.x0, this.x1, this.top, this.seed);
  final double x0;
  final double x1;
  final double top;
  final int seed;

  bool spans(double x) => x >= x0 && x <= x1;
}

class Carrot {
  Carrot(this.x, this.y);
  final double x;
  final double y;
  bool eaten = false;
  double get r => 13;
}

class Particle {
  Particle(this.x, this.y, this.vx, this.vy, this.maxLife, this.size, this.kind)
      : life = maxLife;
  double x, y, vx, vy, size;
  final double maxLife;
  double life;
  final int kind; // 0 dust, 1 sparkle, 2 puff
  double get age => 1 - (life / maxLife);
}

/// Pure-Dart rooftop runner simulation.
///
/// World units: y grows upward, the visible band is roughly 0..520 units tall
/// and 700 units wide. All physics is resolution independent; the painter
/// scales the world to the device.
class GameSim {
  GameSim({int seed = 7}) : _rng = math.Random(seed) {
    reset();
  }

  // ---- tuning -------------------------------------------------------------
  static const double gravity = 2500;
  static const double baseSpeed = 300;
  static const double zoneLen = 1500;
  static const double carrotWeight = 0.05;
  static const double burnPerSecond = 0.008;
  static const double burnOnWeight = 0.05;
  static const double floorY = -90;

  static double jumpVelFor(double weight) => 1040 - 620 * weight.clamp(0.0, 1.0);

  /// Peak height of a full jump at a given weight (units).
  static double jumpApex(double weight) {
    final v = jumpVelFor(weight);
    return (v * v) / (2 * gravity);
  }

  /// Horizontal reach of a full jump at a given weight (units).
  static double jumpReach(double weight, double speed) {
    return (2 * jumpVelFor(weight) / gravity) * speed;
  }

  // ---- state --------------------------------------------------------------
  final math.Random _rng;

  final List<Roof> roofs = [];
  final List<Carrot> carrots = [];
  final List<Particle> particles = [];

  double x = 60;
  double y = 170;
  double vy = 0;
  double weight = 0;
  double dist = 0;
  double time = 0;
  double speed = baseSpeed;
  int zones = 0;
  int carrotsEaten = 0;
  int carrotsPlaced = 0;
  End end = End.running;

  bool grounded = true;
  Roof? ground;
  bool get holding => _holding;
  double _coyote = 0;
  double _buffered = 0;
  bool _holding = false;
  double _squash = 0; // >0 land squash, <0 jump stretch
  double _airTime = 0;
  double _wobble = 0;
  double _eatPulse = 0;
  double _startX = 60;
  double _frontierX = 900;
  double _lastTop = 170;

  // one-frame event flags consumed by the view layer
  bool ateThisFrame = false;
  bool landedThisFrame = false;
  bool jumpedThisFrame = false;
  bool zoneThisFrame = false;
  bool diedThisFrame = false;
  double deathTime = -1;

  double get airTime => _airTime;
  double get squash => _squash;
  double get wobble => _wobble;
  double get eatPulse => _eatPulse;
  double get speedNorm => ((speed - baseSpeed) / 190).clamp(0.0, 1.0);

  void reset() {
    roofs.clear();
    carrots.clear();
    particles.clear();
    x = 60;
    y = 170;
    vy = 0;
    weight = 0;
    dist = 0;
    time = 0;
    speed = baseSpeed;
    zones = 0;
    carrotsEaten = 0;
    carrotsPlaced = 0;
    end = End.running;
    grounded = true;
    _coyote = 0;
    _buffered = 0;
    _holding = false;
    _squash = 0;
    _airTime = 0;
    _wobble = 0;
    _eatPulse = 0;
    _startX = 60;
    deathTime = -1;
    final first = Roof(-600, 900, 170, 1);
    roofs.add(first);
    ground = first;
    _frontierX = 900;
    _lastTop = 170;
    _extend();
  }

  // ---- input --------------------------------------------------------------
  void press() {
    _holding = true;
    _buffered = 0.12;
  }

  void release() {
    _holding = false;
    if (vy > 260) vy *= 0.52; // variable jump height
  }

  // ---- per frame ----------------------------------------------------------
  void update(double dt) {
    if (dt <= 0) return;
    final step = math.min(dt, 1 / 30);
    time += step;

    ateThisFrame = false;
    landedThisFrame = false;
    jumpedThisFrame = false;
    zoneThisFrame = false;
    diedThisFrame = false;

    _decayTimers(step);
    _updateParticles(step);

    if (end != End.running) {
      // keep tumbling for the death animation, camera freezes in the painter
      vy -= gravity * step;
      y += vy * step;
      return;
    }

    speed = baseSpeed + math.min(190, dist * 0.045);
    _wobble += step * (grounded ? speed / 26 : 6);
    _squash = _approach(_squash, 0, step * 6);
    _eatPulse = _approach(_eatPulse, 0, step * 3.2);

    _tryJump();

    final prevY = y;
    if (!grounded) {
      _airTime += step;
      vy -= gravity * step;
      y += vy * step;
      _checkLanding(prevY);
    } else {
      _airTime = 0;
      final g = ground!;
      if (x > g.x1) {
        grounded = false;
        _coyote = 0.10;
        vy = 0;
        y = g.top;
      } else {
        y = g.top;
      }
    }

    x += speed * step;
    dist = x - _startX;

    _checkWalls();
    if (end == End.running) {
      // heavier buns burn off more - the weight curve settles instead of
      // only ever going up
      weight = math.max(0, weight - (burnPerSecond + burnOnWeight * weight) * step);
      _collect();
      _extend();
      _cull();

      final z = (dist / zoneLen).floor();
      if (z > zones) {
        zones = z;
        zoneThisFrame = true;
      }
      if (y < floorY) {
        _die(End.fell);
      }
    }
  }

  void _decayTimers(double step) {
    _buffered = math.max(0, _buffered - step);
    _coyote = math.max(0, _coyote - step);
  }

  void _tryJump() {
    if (_buffered <= 0) return;
    if (!(grounded || _coyote > 0)) return;
    vy = jumpVelFor(weight);
    grounded = false;
    ground = null;
    _coyote = 0;
    _buffered = 0;
    _squash = -0.55;
    jumpedThisFrame = true;
    _spawnDust(6, 0.9);
  }

  void _checkLanding(double prevY) {
    if (vy > 0) return;
    for (final r in roofs) {
      if (!r.spans(x)) continue;
      if (prevY >= r.top - 0.6 && y <= r.top) {
        y = r.top;
        vy = 0;
        grounded = true;
        ground = r;
        _airTime = 0;
        _squash = 0.6;
        landedThisFrame = true;
        _spawnDust(9, 1.2);
        return;
      }
    }
  }

  void _checkWalls() {
    for (final r in roofs) {
      if (x < r.x0 - 2 || x > r.x1) continue;
      final lip = r.top - y;
      if (lip > 14) {
        x = r.x0 - 3;
        grounded = false;
        ground = null;
        vy = math.min(vy, -120);
        _die(End.bumped);
        return;
      }
      if (grounded && lip > -14 && lip != 0) {
        y = r.top;
        ground = r;
        return;
      }
    }
  }

  void _die(End why) {
    if (end != End.running) return;
    end = why;
    deathTime = time;
    diedThisFrame = true;
    _spawnPuff(14);
  }

  void _collect() {
    final cy = y + 26;
    for (final c in carrots) {
      if (c.eaten) continue;
      if ((c.x - x).abs() > c.r + 26) continue;
      if ((c.y - cy).abs() > c.r + 20) continue;
      c.eaten = true;
      carrotsEaten += 1;
      weight = math.min(1, weight + carrotWeight);
      ateThisFrame = true;
      _eatPulse = 1;
      _spawnSparkle(8);
    }
  }

  // ---- procedural level ---------------------------------------------------
  /// Speed the runner will actually have at a given world x.
  double speedAtWorldX(double wx) =>
      baseSpeed + math.min(190, math.max(0, wx - _startX) * 0.045);

  void _extend() {
    var guard = 0;
    while (_frontierX < x + 1900 && guard++ < 40) {
      final prevEdge = _frontierX;
      final prevTop = _lastTop;
      final diff = math.min(1, (prevEdge - _startX) / 4500);
      final spd = speedAtWorldX(prevEdge);

      // How high the next roof may be: a fat bun cannot lift itself far.
      final maxUp = 58 * (1 - 0.62 * weight);
      var top = prevTop + (_rng.nextDouble() * 2 - 1) * (44 + 40 * diff);
      if (top - prevTop > maxUp) top = prevTop + maxUp;
      if (prevTop - top > 85) top = prevTop - 85;
      top = top.clamp(112.0, 300.0);

      // Gap width is the difficulty curve. It is sized by distance travelled,
      // never by how fat the bun currently is - that is the whole punishment
      // for eating. A light bun clears everything, a heavy one does not.
      final gapMax = 62 + 150 * diff;
      final gap = (46 + _rng.nextDouble() * (gapMax - 46)).clamp(44.0, 196.0);

      final x0 = prevEdge + gap;
      final width = math.max(150.0, 250 - 60 * diff + _rng.nextDouble() * 190);

      // A full jump taken at the previous edge must land ON this roof, so the
      // roof extends past the longest arc a lean bun can produce. Landing is
      // never the unfair part; clearing the gap is.
      final v = jumpVelFor(0);
      final drop = math.max(0.0, prevTop - top);
      final tLand = (v + math.sqrt(v * v + 2 * gravity * drop)) / gravity;
      final landX = prevEdge + spd * tLand;

      final r = Roof(x0, math.max(x0 + width, landX + 150), top,
          _rng.nextInt(1 << 20));
      roofs.add(r);
      _placeCarrots(r, prevTop, prevEdge, gap, landX);
      _frontierX = r.x1;
      _lastTop = top;
    }
  }

  void _placeCarrots(Roof r, double prevTop, double prevEdge, double gap,
      double landX) {
    final roll = _rng.nextDouble();
    if (roll < 0.15 && gap > 62) {
      // greedy arc over the gap: only reached if you hop on purpose
      const n = 2;
      for (var i = 0; i < n; i++) {
        final t = (i + 1) / (n + 1);
        final cx = prevEdge + gap * t;
        final hi = math.max(prevTop, r.top);
        final lift = math.sin(math.pi * t) * (54 + 30 * _rng.nextDouble());
        carrots.add(Carrot(cx, hi + 30 + lift));
        carrotsPlaced++;
      }
      return;
    }
    if (roll < 0.32) return; // an empty roof is a gift
    final n = roll < 0.82 ? 1 : 2;
    // only the stretch after the ballistic landing point is guaranteed to be
    // run over, so that is where the food has to sit
    final from = math.max(r.x0 + 55, landX + 25);
    final to = r.x1 - 55;
    if (to - from < 50) return;
    final start = from + _rng.nextDouble() * math.max(0, to - from - n * 46);
    for (var i = 0; i < n; i++) {
      final cx = start + i * 46;
      if (cx > to) break;
      carrots.add(Carrot(cx, r.top + 30));
      carrotsPlaced++;
    }
  }

  void _cull() {
    final back = x - 1400;
    roofs.removeWhere((ro) => ro.x1 < back && ro != ground);
    carrots.removeWhere((c) => c.x < back - 100);
  }

  // ---- particles ----------------------------------------------------------
  void _spawnDust(int n, double power) {
    for (var i = 0; i < n; i++) {
      final dir = -0.6 - _rng.nextDouble() * 0.8;
      particles.add(Particle(
        x - 14 + _rng.nextDouble() * 10,
        y + 4,
        dir * (60 + _rng.nextDouble() * 90) * power,
        (20 + _rng.nextDouble() * 70) * power,
        0.34 + _rng.nextDouble() * 0.2,
        4 + _rng.nextDouble() * 7,
        0,
      ));
    }
  }

  void _spawnSparkle(int n) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      particles.add(Particle(
        x + 10,
        y + 30,
        math.cos(a) * (70 + _rng.nextDouble() * 110),
        math.sin(a) * (70 + _rng.nextDouble() * 110) + 40,
        0.3 + _rng.nextDouble() * 0.28,
        3 + _rng.nextDouble() * 4,
        1,
      ));
    }
  }

  void _spawnPuff(int n) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      particles.add(Particle(
        x + 8,
        y + 24,
        math.cos(a) * (90 + _rng.nextDouble() * 160),
        math.sin(a) * (90 + _rng.nextDouble() * 160),
        0.45 + _rng.nextDouble() * 0.35,
        6 + _rng.nextDouble() * 10,
        2,
      ));
    }
  }

  void _updateParticles(double step) {
    for (final p in particles) {
      p.life -= step;
      p.x += p.vx * step;
      p.y += p.vy * step;
      p.vy -= (p.kind == 1 ? 260 : 60) * step;
      p.vx *= 0.98;
    }
    particles.removeWhere((p) => p.life <= 0);
    if (particles.length > 220) particles.removeRange(0, particles.length - 220);
  }

  static double _approach(double v, double target, double rate) {
    if (v > target) return math.max(target, v - rate);
    return math.min(target, v + rate);
  }

  // ---- helpers for the view ----------------------------------------------
  double get bodyHalf => 26 + 8 * weight;
  Roof? roofAt(double wx) {
    for (final r in roofs) {
      if (r.spans(wx)) return r;
    }
    return null;
  }

  /// Roof the goal flag for the next zone stands on, or null if not spawned.
  Roof? zoneRoof(int zoneIndex) {
    final wx = zoneIndex * zoneLen + _startX;
    for (final r in roofs) {
      if (r.spans(wx)) return r;
    }
    return null;
  }

  double zoneWorldX(int zoneIndex) => zoneIndex * zoneLen + _startX;
}
