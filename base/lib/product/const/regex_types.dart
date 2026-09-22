import 'package:flutter/material.dart';

/// Uygulama genelinde kullanilan regex pattern'leri.
/// Form validation ve input formatlama icin.
@immutable
final class RegexTypes {
  const RegexTypes._();

  /// Ad Soyad — Turkce karakter destekli, en az 2+2 harf.
  static final RegExp fullName = RegExp(
    r'^[a-zA-ZçÇğĞıİöÖşŞüÜ]{2,}\s[a-zA-ZçÇğĞıİöÖşŞüÜ]{2,}$',
  );

  /// Email adresi.
  static final RegExp email = RegExp(r'^[\w.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  /// Ogrenci maili (.edu uzantili).
  static final RegExp studentEmail = RegExp(
    r'^[\w.-]+@[a-zA-Z0-9.-]+\.(edu|edu\.[a-zA-Z]{2,})$',
  );

  /// Sadece rakamlar — telefon numarasi formatlama icin.
  static final RegExp digitsOnly = RegExp('[^0-9]');

  /// Telefon numarasi — +90 5xx xxx xx xx formati.
  static final RegExp phoneNumber = RegExp(r'^\+?[0-9]{10,13}$');

  /// Sifre — en az 8 karakter, 1 harf + 1 rakam.
  static final RegExp password = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  /// Web adresi — sema opsiyonel.
  static final RegExp url = RegExp(
    r'^(https?:\/\/)?([\w-]+\.)+[a-zA-Z]{2,}(\/\S*)?$',
  );

  // ── Metin sadelestirme (`String.normalize`) ────────────────

  /// Herhangi bir bosluk karakteri — kelimelere bolmek icin.
  static final RegExp whitespace = RegExp(r'\s+');

  /// Ard arda gelen bosluk/tab — tek bosluga indirilir.
  static final RegExp multipleSpaces = RegExp(r'[ \t]+');

  /// Satir sonunun etrafindaki bosluklar — satir basi/sonu kirpilir.
  static final RegExp aroundLineBreaks = RegExp(r'[ \t]*\n[ \t]*');

  /// Uc ve uzeri satir sonu — iki satir sonuna indirilir.
  static final RegExp excessiveLineBreaks = RegExp(r'\n{3,}');
}
