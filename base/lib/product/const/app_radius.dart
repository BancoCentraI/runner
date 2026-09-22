import 'package:flutter/widgets.dart';

/// Uygulama genelinde kullanilan kose yaricapi degerleri.
/// Ham `BorderRadius.circular(<sayi>)` yerine bunlar kullanilir.
@immutable
final class AppRadius {
  const AppRadius._();

  // ── Yaricap degerleri ──────────────────────────────────────
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 28;

  /// Tam yuvarlak (pill / stadium) icin yeterince buyuk sabit deger.
  static const double pill = 999;

  // ── Hazir BorderRadius ─────────────────────────────────────
  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allS = BorderRadius.all(Radius.circular(s));
  static const BorderRadius allM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius allL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));

  /// Kart ve liste ogeleri icin varsayilan.
  static const BorderRadius card = allL;

  /// Bottom sheet — yalnizca ust koseler yuvarlanir.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );

  /// Dialog govdesi.
  static const BorderRadius dialog = allXl;

  /// Buton — `AppPrimaryButton` ve tema `button_theme.dart` ile ayni deger.
  static const BorderRadius button = BorderRadius.all(Radius.circular(14));
}
