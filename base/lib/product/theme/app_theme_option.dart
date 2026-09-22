import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/theme/app_theme_variant.dart';
import 'package:flutter/material.dart';

/// Tema secim sayfasinda gosterilen hazir tema secenegi.
///
/// Her secenek bir [id] (SharedPreferences'ta saklanan `themeId`),
/// lokalize bir [labelKey] ve onizleme rengi tasir. Custom seed temasi
/// kullanici girdisine bagli oldugu icin bu katalogda yer almaz; UI'da
/// ayri bir kart olarak ele alinir.
@immutable
final class AppThemeOption {
  const AppThemeOption({
    required this.id,
    required this.labelKey,
    required this.previewColor,
  });

  final String id;
  final String labelKey;
  final Color previewColor;
}

/// Built-in tema kimlikleri. Seed varyantlari `AppThemeVariant.key` ile
/// ayni stringtir; ozel temalar kendi sabitlerine sahiptir.
abstract final class AppThemeIds {
  static const monochrome = 'monochrome';
  static const amoled = 'amoled';
  static const custom = 'custom';

  /// Verilen id seed varyanti mi (8 renkten biri) yoksa ozel tema mi?
  static bool isSeed(String id) =>
      id != monochrome && id != amoled && id != custom;
}

/// Tema kataloglari.
abstract final class AppThemeCatalog {
  /// 8 seed renk varyanti.
  static final List<AppThemeOption> colors = AppThemeVariant.values
      .map(
        (v) => AppThemeOption(
          id: v.key,
          labelKey: _seedLabelKey(v),
          previewColor: v.previewColor,
        ),
      )
      .toList();

  /// Nötr / ozel temalar.
  static const List<AppThemeOption> neutrals = [
    AppThemeOption(
      id: AppThemeIds.monochrome,
      labelKey: LocaleKeys.theme_name_monochrome,
      previewColor: Color(0xFF6F6F6F),
    ),
    AppThemeOption(
      id: AppThemeIds.amoled,
      labelKey: LocaleKeys.theme_name_amoled,
      previewColor: Colors.black,
    ),
  ];

  static String _seedLabelKey(AppThemeVariant v) => switch (v) {
    AppThemeVariant.purple => LocaleKeys.theme_name_purple,
    AppThemeVariant.blue => LocaleKeys.theme_name_blue,
    AppThemeVariant.green => LocaleKeys.theme_name_green,
    AppThemeVariant.orange => LocaleKeys.theme_name_orange,
    AppThemeVariant.red => LocaleKeys.theme_name_red,
    AppThemeVariant.black => LocaleKeys.theme_name_black,
    AppThemeVariant.teal => LocaleKeys.theme_name_teal,
    AppThemeVariant.indigo => LocaleKeys.theme_name_indigo,
  };
}
