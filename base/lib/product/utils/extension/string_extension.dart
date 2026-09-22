import 'package:akillisletme/product/const/regex_types.dart';
import 'package:flutter/services.dart';

/// Metin uzerinde sik tekrar eden islemler.
extension StringExtension on String {
  /// Kullanici girdisini sadelestirir:
  /// - basindaki/sonundaki bosluklari kaldirir,
  /// - birden fazla boslugu tek bosluga indirir,
  /// - uc ve uzeri satir sonunu iki satir sonuna indirir.
  ///
  /// Forma girilen cok satirli aciklamalari kaydetmeden once kullan.
  String get normalize => replaceAll(RegexTypes.multipleSpaces, ' ')
      .replaceAll(RegexTypes.aroundLineBreaks, '\n')
      .replaceAll(RegexTypes.excessiveLineBreaks, '\n\n')
      .trim();

  /// Fotografi olmayan kullanici icin avatar bas harfleri.
  /// → `'Ada Lovelace'.initials()` = `'AL'`, bos metinde `'?'`.
  String initials({int take = 2}) {
    final parts = trim()
        .split(RegexTypes.whitespace)
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0].toUpperCase()).take(take).join();
  }

  /// Kisa gosterim adi — ilk ad + soyad bas harfi.
  /// → `'Ada Lovelace'.shortDisplayName` = `'Ada L.'`
  String get shortDisplayName {
    final parts = trim()
        .split(RegexTypes.whitespace)
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts.last[0].toUpperCase()}.';
  }

  /// Sema icermeyen adrese `https://` ekler. `url_launcher` sema olmadan
  /// adresi acamaz.
  String get withHttps =>
      startsWith('http://') || startsWith('https://') ? this : 'https://$this';

  /// Ilk harfi buyutur, gerisine dokunmaz.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  bool get isValidEmail => RegexTypes.email.hasMatch(trim());

  bool get isValidPhone =>
      RegexTypes.phoneNumber.hasMatch(replaceAll(RegexTypes.digitsOnly, ''));

  /// Yalnizca rakamlar — telefon/kod alanlarini karsilastirmadan once.
  String get digitsOnly => replaceAll(RegexTypes.digitsOnly, '');

  Future<void> copyToClipboard() =>
      Clipboard.setData(ClipboardData(text: this));
}

extension NullableStringExtension on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  bool get isNotNullOrBlank => !isNullOrBlank;

  /// `null` veya bos ise [fallback], degilse kendisi.
  String orElse(String fallback) => isNullOrBlank ? fallback : this!;
}
