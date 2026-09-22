import 'package:akillisletme/product/theme/app_theme_colors.dart';
import 'package:akillisletme/product/theme/spec/theme_spec.dart';
import 'package:akillisletme/product/theme/state/theme_state.dart';
import 'package:flutter/material.dart';

part 'base/color_schemes.dart';
part 'parts/card_theme.dart';
part 'parts/button_theme.dart';
part 'parts/input_theme.dart';
part 'parts/appbar_theme.dart';
part 'parts/chip_theme.dart';
part 'parts/slider_theme.dart';
part 'parts/switch_theme.dart';
part 'base/dark_theme.dart';
part 'base/light_theme.dart';
part 'parts/text_theme.dart';

final class AppTheme {
  AppTheme._();

  /// Dark `ThemeData`. [dynamicScheme] verilir ve [ThemeState.useSystemColors]
  /// aciksa Material You (sistem) renkleri kullanilir.
  static ThemeData darkTheme(ThemeState state, {ColorScheme? dynamicScheme}) {
    final spec = state.spec;
    return _buildDarkTheme(
      _resolveScheme(state, spec, Brightness.dark, dynamicScheme),
      fontFamily: spec.fontFamily,
    );
  }

  /// Light `ThemeData`.
  static ThemeData lightTheme(ThemeState state, {ColorScheme? dynamicScheme}) {
    final spec = state.spec;
    return _buildLightTheme(
      _resolveScheme(state, spec, Brightness.light, dynamicScheme),
      fontFamily: spec.fontFamily,
    );
  }
}
