import 'package:akillisletme/product/cache/shared_operation/shared_keys.dart';
import 'package:akillisletme/product/service/service_locator.dart';
import 'package:akillisletme/product/theme/app_theme_option.dart';
import 'package:akillisletme/product/theme/app_theme_variant.dart';
import 'package:akillisletme/product/theme/state/theme_state.dart';
import 'package:akillisletme/product/theme/theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState()) {
    _load();
  }

  void _load() {
    final cache = locator.sharedCache;
    final themeId = cache.getValue<String>(SharedKeys.themeVariant);
    final themeModeKey = cache.getValue<String>(SharedKeys.theme);
    final customSeed = cache.getValue<int>(SharedKeys.themeCustomSeed);
    final schemeVariant = cache.getValue<String>(SharedKeys.themeSchemeVariant);
    final contrast = cache.getValue<double>(SharedKeys.themeContrast);
    final useSystemColors = cache.getValue<bool>(
      SharedKeys.themeUseSystemColors,
    );

    emit(
      ThemeState(
        themeId: themeId ?? state.themeId,
        customSeedArgb: customSeed,
        schemeVariant: _schemeVariantFromName(schemeVariant),
        contrastLevel: contrast ?? state.contrastLevel,
        useSystemColors: useSystemColors ?? state.useSystemColors,
        themeMode: themeModeKey != null
            ? _themeModeFromKey(themeModeKey)
            : state.themeMode,
      ),
    );
  }

  /// Hazir bir tema sec (seed varyant veya nötr tema). Material You kapatilir.
  Future<void> selectTheme(String themeId) async {
    await _save(SharedKeys.themeVariant, themeId);
    await _save(SharedKeys.themeUseSystemColors, false);
    emit(state.copyWith(themeId: themeId, useSystemColors: false));
  }

  /// Geriye donuk uyum: seed varyant secimi (onboarding + eski tile'lar).
  Future<void> setVariant(AppThemeVariant variant) => selectTheme(variant.key);

  /// Kullanicinin sectigi serbest seed rengi uygula.
  Future<void> setCustomSeed(Color color) async {
    final argb = color.toARGB32();
    await _save(SharedKeys.themeVariant, AppThemeIds.custom);
    await _save(SharedKeys.themeCustomSeed, argb);
    await _save(SharedKeys.themeUseSystemColors, false);
    emit(
      state.copyWith(
        themeId: AppThemeIds.custom,
        customSeedArgb: argb,
        useSystemColors: false,
      ),
    );
  }

  Future<void> setSchemeVariant(DynamicSchemeVariant variant) async {
    await _save(SharedKeys.themeSchemeVariant, variant.name);
    emit(state.copyWith(schemeVariant: variant));
  }

  Future<void> setContrastLevel(double level) async {
    await _save(SharedKeys.themeContrast, level);
    emit(state.copyWith(contrastLevel: level));
  }

  Future<void> setUseSystemColors({required bool enabled}) async {
    await _save(SharedKeys.themeUseSystemColors, enabled);
    emit(state.copyWith(useSystemColors: enabled));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _save(SharedKeys.theme, mode.name);
    emit(state.copyWith(themeMode: mode));
  }

  /// Renk + mod presetini tek seferde uygula.
  Future<void> applyPreset(ThemePreset preset) async {
    await _save(SharedKeys.themeVariant, preset.themeId);
    await _save(SharedKeys.theme, preset.themeMode.name);
    await _save(SharedKeys.themeUseSystemColors, false);
    emit(
      state.copyWith(
        themeId: preset.themeId,
        themeMode: preset.themeMode,
        useSystemColors: false,
      ),
    );
  }

  Future<void> _save<T>(SharedKeys key, T value) =>
      locator.sharedCache.setValue<T>(key, value);

  static ThemeMode _themeModeFromKey(String key) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == key,
      orElse: () => ThemeMode.system,
    );
  }

  static DynamicSchemeVariant _schemeVariantFromName(String? name) {
    if (name == null) return DynamicSchemeVariant.tonalSpot;
    return DynamicSchemeVariant.values.firstWhere(
      (v) => v.name == name,
      orElse: () => DynamicSchemeVariant.tonalSpot,
    );
  }
}
