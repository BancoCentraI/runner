import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/theme/app_theme_option.dart';
import 'package:flutter/material.dart';

/// Renk + mod kombinasyonunu tek dokunusla uygulayan adlandirilmis preset.
///
/// (Orijinal planda harita stili de iceriyordu; clean_start'ta harita modulu
/// olmadigi icin presetler renk + mod ile sinirli tutuldu.)
@immutable
final class ThemePreset {
  const ThemePreset({
    required this.labelKey,
    required this.themeId,
    required this.themeMode,
    required this.previewColor,
  });

  final String labelKey;
  final String themeId;
  final ThemeMode themeMode;
  final Color previewColor;

  static const all = <ThemePreset>[
    ThemePreset(
      labelKey: LocaleKeys.theme_preset_minimal,
      themeId: AppThemeIds.monochrome,
      themeMode: ThemeMode.light,
      previewColor: Color(0xFF9E9E9E),
    ),
    ThemePreset(
      labelKey: LocaleKeys.theme_preset_ocean,
      themeId: 'blue',
      themeMode: ThemeMode.system,
      previewColor: Color(0xFF2196F3),
    ),
    ThemePreset(
      labelKey: LocaleKeys.theme_preset_sunset,
      themeId: 'orange',
      themeMode: ThemeMode.dark,
      previewColor: Color(0xFFFF9800),
    ),
    ThemePreset(
      labelKey: LocaleKeys.theme_preset_amoled,
      themeId: AppThemeIds.amoled,
      themeMode: ThemeMode.dark,
      previewColor: Color(0xFF000000),
    ),
  ];
}
