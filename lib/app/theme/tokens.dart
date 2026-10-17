import 'package:flutter/material.dart';

/// Tokens de design centralizados. Não use valores soltos nas telas.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class Radii {
  static const double card = 20;
  static const double field = 14;
  static const double chip = 12;
}

abstract final class Brand {
  /// Azul principal.
  static const Color blue = Color(0xFF2563EB);
  static const Color blueDark = Color(0xFF1D4ED8);
  static const Color blueDeep = Color(0xFF1E3A8A);
  static const Color blueSoft = Color(0xFFE8F0FE);
  static const Color background = Color(0xFFF5F8FF);
  static const double maxContentWidth = 640;

  static const LinearGradient gradient = LinearGradient(
    colors: [Color(0xFF3B82F6), blueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
