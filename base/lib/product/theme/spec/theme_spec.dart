import 'package:akillisletme/product/theme/app_theme_variant.dart';
import 'package:flutter/material.dart';

/// Bir temanin `ColorScheme` uretme stratejisini soyutlar.
///
/// Eski mimaride varyant yalnizca bir seed renk verirdi. Yeni temalar
/// (custom seed, monochrome/neutral, AMOLED) ya tam bir `ColorScheme` ister
/// ya da ek parametreler (scheme variant + contrast) gerektirir. Bu yuzden
/// her tema, brightness'a gore kendi `ColorScheme`'ini ureten bir
/// [ThemeSpec] ile temsil edilir.
///
/// `AppTheme.lightTheme/darkTheme` bu spec'i kullanarak `ThemeData` kurar.
sealed class ThemeSpec {
  const ThemeSpec();

  /// Verilen [brightness] icin renk semasini uretir.
  ColorScheme schemeFor(Brightness brightness);

  /// Tema'ya ozel font ailesi (or. hacker/terminal monospace).
  /// `null` ise varsayilan tipografi (Poppins + Inter) kullanilir.
  String? get fontFamily => null;
}

/// M3 seed-bazli tema (mevcut 8 renk varyanti). Istege bagli kontrast.
final class SeedThemeSpec extends ThemeSpec {
  const SeedThemeSpec(this.variant, {this.contrastLevel = 0});

  final AppThemeVariant variant;
  final double contrastLevel;

  @override
  ColorScheme schemeFor(Brightness brightness) {
    if (contrastLevel == 0) {
      return brightness == Brightness.dark
          ? variant.darkColorScheme
          : variant.lightColorScheme;
    }
    return ColorScheme.fromSeed(
      seedColor: variant.seedColor,
      brightness: brightness,
      contrastLevel: contrastLevel,
    );
  }
}

/// Kullanicinin sectigi serbest seed renkten uretilen tema.
/// `dynamicSchemeVariant` ile monochrome/neutral/vibrant gibi modlar,
/// `contrastLevel` ile erisilebilirlik desteklenir.
final class CustomSeedThemeSpec extends ThemeSpec {
  const CustomSeedThemeSpec({
    required this.seed,
    this.schemeVariant = DynamicSchemeVariant.tonalSpot,
    this.contrastLevel = 0,
  });

  final Color seed;
  final DynamicSchemeVariant schemeVariant;
  final double contrastLevel;

  @override
  ColorScheme schemeFor(Brightness brightness) => ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: schemeVariant,
    contrastLevel: contrastLevel,
  );
}

/// Tam kontrollu, hazir `ColorScheme`'ler (AMOLED saf siyah, hacker modu).
/// `fromSeed` otomatigine birakilmaz; kontrast elle ayarlanir.
final class RawSchemeThemeSpec extends ThemeSpec {
  const RawSchemeThemeSpec({
    required this.light,
    required this.dark,
    this.fontFamily,
  });

  final ColorScheme light;
  final ColorScheme dark;

  @override
  final String? fontFamily;

  @override
  ColorScheme schemeFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// AMOLED "saf siyah" temasi: dark modda tum surface'ler #000000'a cekilir
/// (OLED pil tasarrufu), light modda nötr gri bir palet kullanilir.
ThemeSpec amoledThemeSpec() {
  final baseDark = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1A1A1A),
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.neutral,
  );
  final pureBlack = baseDark.copyWith(
    surface: Colors.black,
    surfaceContainerLowest: Colors.black,
    surfaceContainerLow: const Color(0xFF0A0A0A),
    surfaceContainer: const Color(0xFF121212),
    surfaceContainerHigh: const Color(0xFF1C1C1C),
    surfaceContainerHighest: const Color(0xFF242424),
  );
  final light = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1A1A1A),
    dynamicSchemeVariant: DynamicSchemeVariant.neutral,
  );
  return RawSchemeThemeSpec(light: light, dark: pureBlack);
}
