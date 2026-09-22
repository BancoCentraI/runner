import 'package:flutter/material.dart';

enum AppLocale {
  tr(Locale('tr', 'TR')),
  en(Locale('en', 'US')),
  ar(Locale('ar', 'SA')),
  de(Locale('de', 'DE')),
  es(Locale('es', 'ES')),
  fr(Locale('fr', 'FR')),
  hi(Locale('hi', 'IN')),
  id(Locale('id', 'ID')),
  it(Locale('it', 'IT')),
  ja(Locale('ja', 'JP')),
  ko(Locale('ko', 'KR')),
  pt(Locale('pt', 'BR')),
  ru(Locale('ru', 'RU')),
  zh(Locale('zh', 'CN'));

  const AppLocale(this.locale);
  final Locale locale;
}

@immutable
class CoreLocalize {
  const CoreLocalize();

  static const initialPath = 'assets/translations';
  static final startLocale = AppLocale.tr.locale;
  static final List<Locale> supportedItems = AppLocale.values
      .map((e) => e.locale)
      .toList();
}
