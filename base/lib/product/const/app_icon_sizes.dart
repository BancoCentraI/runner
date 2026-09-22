import 'package:flutter/widgets.dart';

/// Ikon boyutlari. Ham `size: 20` yerine bunlar kullanilir.
@immutable
final class AppIconSizes {
  const AppIconSizes._();

  /// Rozet / etiket ici ikon.
  static const double xs = 14;

  /// Liste ogesi trailing ikonu, buton ikonu.
  static const double s = 18;

  /// Varsayilan — AppBar aksiyonu, ListTile leading.
  static const double m = 24;

  /// Vurgulu ikon — bos durum, dialog basligi.
  static const double l = 32;

  /// Illustrasyon yerine gecen buyuk ikon.
  static const double xl = 48;

  /// Bos ekran / hata ekrani gorseli.
  static const double xxl = 72;
}
