import 'package:shared_preferences/shared_preferences.dart';

/// Tiny persistence layer: best distance and whether onboarding was seen.
class Save {
  Save._();

  static const String _kBest = 'mb.best.v1';
  static const String _kCarrots = 'mb.carrots.v1';
  static const String _kSeenOnboarding = 'mb.onboarded.v1';

  static int best = 0;
  static int totalCarrots = 0;
  static bool seenOnboarding = false;

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      best = p.getInt(_kBest) ?? 0;
      totalCarrots = p.getInt(_kCarrots) ?? 0;
      seenOnboarding = p.getBool(_kSeenOnboarding) ?? false;
    } catch (_) {
      // storage unavailable (incognito web, etc.) - run in memory
    }
  }

  /// Returns true when a new record was set.
  static Future<bool> submitRun({required int meters, required int carrots}) async {
    totalCarrots += carrots;
    final isBest = meters > best;
    if (isBest) best = meters;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kBest, best);
      await p.setInt(_kCarrots, totalCarrots);
    } catch (_) {}
    return isBest;
  }

  static Future<void> markOnboarded() async {
    seenOnboarding = true;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kSeenOnboarding, true);
    } catch (_) {}
  }
}
