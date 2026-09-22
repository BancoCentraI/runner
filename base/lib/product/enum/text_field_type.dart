import 'package:flutter/services.dart';

/// Bir metin alaninin turu — klavye, otomatik doldurma, girdi filtresi ve
/// karakter siniri bundan turetilir.
///
/// Cagri yerinde `keyboardType`, `inputFormatters`, `autofillHints` ve
/// `maxLength` ayri ayri verilmez; tur secilir, geri kalani buradan gelir.
enum TextFieldType {
  /// Serbest kisa metin — ad, baslik.
  text,

  /// Cok satirli aciklama.
  multiline,

  email,
  password,
  phone,

  /// Yalnizca rakam — miktar, adet, kod.
  number,

  /// Web adresi.
  url,

  /// Kisi adi — otomatik doldurma ipucu ad-soyad olur.
  name,

  /// Arama alani.
  search;

  TextInputType get keyboardType => switch (this) {
    TextFieldType.multiline => TextInputType.multiline,
    TextFieldType.email => TextInputType.emailAddress,
    TextFieldType.password => TextInputType.visiblePassword,
    TextFieldType.phone => TextInputType.phone,
    TextFieldType.number => TextInputType.number,
    TextFieldType.url => TextInputType.url,
    TextFieldType.name => TextInputType.name,
    TextFieldType.text || TextFieldType.search => TextInputType.text,
  };

  List<TextInputFormatter>? get formatters => switch (this) {
    TextFieldType.number => [FilteringTextInputFormatter.digitsOnly],
    TextFieldType.phone => [
      FilteringTextInputFormatter.allow(RegExp(r'[\d\s()+-]')),
    ],
    _ => null,
  };

  List<String>? get autofillHints => switch (this) {
    TextFieldType.email => const [AutofillHints.email],
    TextFieldType.password => const [AutofillHints.password],
    TextFieldType.phone => const [AutofillHints.telephoneNumber],
    TextFieldType.name => const [AutofillHints.name],
    TextFieldType.url => const [AutofillHints.url],
    _ => null,
  };

  /// Platform sinirlarina ve alan anlamina gore ustsinir.
  /// `null` ise sinir yoktur (ve sayac gosterilmez).
  int? get maxLength => switch (this) {
    TextFieldType.text || TextFieldType.name => 100,
    TextFieldType.email || TextFieldType.url => 254,
    TextFieldType.password => 64,
    TextFieldType.phone => 20,
    TextFieldType.number => 12,
    TextFieldType.multiline => 1000,
    TextFieldType.search => null,
  };

  bool get isObscured => this == TextFieldType.password;

  bool get isMultiline => this == TextFieldType.multiline;
}
