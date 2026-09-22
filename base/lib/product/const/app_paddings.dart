import 'package:flutter/material.dart';

/// Uygulama genelinde kullanilan sabit padding ve spacing degerleri.
/// Tasarim degisikliginde tek yerden guncellenir.
@immutable
final class AppPaddings {
  const AppPaddings._();

  // ── Padding degerleri ──────────────────────────────────────
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // ── Hazir EdgeInsets ───────────────────────────────────────
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allS = EdgeInsets.all(s);
  static const EdgeInsets allM = EdgeInsets.all(m);
  static const EdgeInsets allL = EdgeInsets.all(l);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);

  static const EdgeInsets horizontalL = EdgeInsets.symmetric(horizontal: l);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets horizontalXxl = EdgeInsets.symmetric(horizontal: xxl);

  static const EdgeInsets verticalS = EdgeInsets.symmetric(vertical: s);
  static const EdgeInsets verticalM = EdgeInsets.symmetric(vertical: m);
  static const EdgeInsets verticalL = EdgeInsets.symmetric(vertical: l);

  // ── Sayfa padding'i (yatay + dikey) ────────────────────────
  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: l,
    vertical: s,
  );
}
