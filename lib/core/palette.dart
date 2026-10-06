import 'package:flutter/painting.dart';

/// Bauhaus monochrome system lifted from the concept sheet.
/// 111111 / 333333 / 777777 / BE8DA8 / E6E1D7 / F6FAEE
class Pal {
  Pal._();

  static const Color black = Color(0xFF111111);
  static const Color graphite = Color(0xFF333333);
  static const Color grey = Color(0xFF777777);
  static const Color accent = Color(0xFFBE8DA8);
  static const Color paper = Color(0xFFE6E1D7);
  static const Color cream = Color(0xFFF6FAEE);

  /// Skyline layers, far -> near.
  static const Color far = Color(0xFFD8D3C8);
  static const Color mid = Color(0xFFB7B2A8);
  static const Color near = Color(0xFF8E8A82);
  static const Color roof = graphite;
  static const Color base = black;

  static const Color accentDeep = Color(0xFFA46E8C);
  static const Color ink10 = Color(0x1A111111);
  static const Color ink20 = Color(0x33111111);
  static const Color ink45 = Color(0x73111111);
  static const Color ink70 = Color(0xB3111111);
}

class Type {
  Type._();
  static const String family = 'Cairo';
}
