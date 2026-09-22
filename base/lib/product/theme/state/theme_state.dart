import 'package:akillisletme/product/theme/app_theme_option.dart';
import 'package:akillisletme/product/theme/app_theme_variant.dart';
import 'package:akillisletme/product/theme/spec/theme_spec.dart';
import 'package:flutter/material.dart';

/// Tema & kisisellestirme durumu.
///
/// Eski modelde yalnizca `variant` + `themeMode` vardi. Yeni model, seed
/// varyantlarinin yani sira custom seed, nötr (monochrome/AMOLED), kontrast
/// seviyesi ve Material You (sistem renkleri) seceneklerini de tasir.
@immutable
class ThemeState {
  const ThemeState({
    this.themeId = AppThemeVariant.purpleKey,
    this.customSeedArgb,
    this.schemeVariant = DynamicSchemeVariant.tonalSpot,
    this.contrastLevel = 0,
    this.useSystemColors = false,
    this.themeMode = ThemeMode.system,
  });

  /// Aktif tema kimligi: bir seed varyant key'i (`purple`...), `monochrome`,
  /// `amoled` veya `custom`.
  final String themeId;

  /// `custom` temasi icin kullanicinin sectigi seed renk (ARGB int).
  final int? customSeedArgb;

  /// Custom/nötr temalarda M3 scheme varyanti.
  final DynamicSchemeVariant schemeVariant;

  /// Kontrast seviyesi (-1..1). 0 = standart, 1 = yuksek kontrast.
  final double contrastLevel;

  /// Material You: duvar kagidindan sistem renklerini kullan (Android 12+).
  final bool useSystemColors;

  /// Tema modu (system/light/dark).
  final ThemeMode themeMode;

  /// Aktif tema icin `ColorScheme` ureten spec.
  ThemeSpec get spec {
    if (themeId == AppThemeIds.amoled) return amoledThemeSpec();
    if (themeId == AppThemeIds.monochrome) {
      return CustomSeedThemeSpec(
        seed: const Color(0xFF6F6F6F),
        schemeVariant: DynamicSchemeVariant.monochrome,
        contrastLevel: contrastLevel,
      );
    }
    if (themeId == AppThemeIds.custom) {
      return CustomSeedThemeSpec(
        seed: Color(customSeedArgb ?? _defaultSeedArgb),
        schemeVariant: schemeVariant,
        contrastLevel: contrastLevel,
      );
    }
    return SeedThemeSpec(
      AppThemeVariant.fromKey(themeId),
      contrastLevel: contrastLevel,
    );
  }

  /// Onboarding ve eski tile'lar icin geriye donuk uyum. Seed olmayan
  /// temalarda varsayilana (purple) duser.
  AppThemeVariant get variant => AppThemeVariant.fromKey(themeId);

  /// Tile/onizleme noktasi rengi.
  Color get previewColor {
    if (themeId == AppThemeIds.amoled) return Colors.black;
    if (themeId == AppThemeIds.monochrome) return const Color(0xFF6F6F6F);
    if (themeId == AppThemeIds.custom) {
      return Color(customSeedArgb ?? _defaultSeedArgb);
    }
    return AppThemeVariant.fromKey(themeId).previewColor;
  }

  static int get _defaultSeedArgb =>
      AppThemeVariant.purple.seedColor.toARGB32();

  ThemeState copyWith({
    String? themeId,
    int? customSeedArgb,
    DynamicSchemeVariant? schemeVariant,
    double? contrastLevel,
    bool? useSystemColors,
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      themeId: themeId ?? this.themeId,
      customSeedArgb: customSeedArgb ?? this.customSeedArgb,
      schemeVariant: schemeVariant ?? this.schemeVariant,
      contrastLevel: contrastLevel ?? this.contrastLevel,
      useSystemColors: useSystemColors ?? this.useSystemColors,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          themeId == other.themeId &&
          customSeedArgb == other.customSeedArgb &&
          schemeVariant == other.schemeVariant &&
          contrastLevel == other.contrastLevel &&
          useSystemColors == other.useSystemColors &&
          themeMode == other.themeMode;

  @override
  int get hashCode => Object.hash(
    themeId,
    customSeedArgb,
    schemeVariant,
    contrastLevel,
    useSystemColors,
    themeMode,
  );
}
