import 'package:akillisletme/product/init/language/core_localize.dart';
import 'package:flutter/material.dart';

@immutable
class LanguageItem {
  const LanguageItem({
    required this.flag,
    required this.nativeName,
    required this.appLocale,
  });

  final String flag;
  final String nativeName;
  final AppLocale appLocale;

  Locale get locale => appLocale.locale;

  static const List<LanguageItem> all = [
    LanguageItem(flag: '🇹🇷', nativeName: 'Türkçe', appLocale: AppLocale.tr),
    LanguageItem(flag: '🇺🇸', nativeName: 'English', appLocale: AppLocale.en),
    LanguageItem(flag: '🇸🇦', nativeName: 'العربية', appLocale: AppLocale.ar),
    LanguageItem(flag: '🇩🇪', nativeName: 'Deutsch', appLocale: AppLocale.de),
    LanguageItem(flag: '🇪🇸', nativeName: 'Español', appLocale: AppLocale.es),
    LanguageItem(flag: '🇫🇷', nativeName: 'Français', appLocale: AppLocale.fr),
    LanguageItem(flag: '🇮🇳', nativeName: 'हिन्दी', appLocale: AppLocale.hi),
    LanguageItem(
      flag: '🇮🇩',
      nativeName: 'Indonesia',
      appLocale: AppLocale.id,
    ),
    LanguageItem(flag: '🇮🇹', nativeName: 'Italiano', appLocale: AppLocale.it),
    LanguageItem(flag: '🇯🇵', nativeName: '日本語', appLocale: AppLocale.ja),
    LanguageItem(flag: '🇰🇷', nativeName: '한국어', appLocale: AppLocale.ko),
    LanguageItem(
      flag: '🇧🇷',
      nativeName: 'Português',
      appLocale: AppLocale.pt,
    ),
    LanguageItem(flag: '🇷🇺', nativeName: 'Русский', appLocale: AppLocale.ru),
    LanguageItem(flag: '🇨🇳', nativeName: '中文', appLocale: AppLocale.zh),
  ];
}
