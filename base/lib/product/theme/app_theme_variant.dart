import 'package:flutter/material.dart';

/// Uygulama tema renk paletleri.
/// Her variant dark + light ColorScheme icerir.
enum AppThemeVariant {
  purple(
    key: 'purple',
    label: 'Purple',
    seedColor: Color(0xFF7C4DFF),
    previewColor: Color(0xFF7C4DFF),
  ),
  blue(
    key: 'blue',
    label: 'Blue',
    seedColor: Color(0xFF2196F3),
    previewColor: Color(0xFF2196F3),
  ),
  green(
    key: 'green',
    label: 'Green',
    seedColor: Color(0xFF4CAF50),
    previewColor: Color(0xFF4CAF50),
  ),
  orange(
    key: 'orange',
    label: 'Orange',
    seedColor: Color(0xFFFF9800),
    previewColor: Color(0xFFFF9800),
  ),
  red(
    key: 'red',
    label: 'Red',
    seedColor: Color(0xFFE91E63),
    previewColor: Color(0xFFE91E63),
  ),
  black(
    key: 'black',
    label: 'Black',
    seedColor: Color(0xFF212121),
    previewColor: Color(0xFF212121),
  ),
  teal(
    key: 'teal',
    label: 'Teal',
    seedColor: Color(0xFF009688),
    previewColor: Color(0xFF009688),
  ),
  indigo(
    key: 'indigo',
    label: 'Indigo',
    seedColor: Color(0xFF3F51B5),
    previewColor: Color(0xFF3F51B5),
  );

  const AppThemeVariant({
    required this.key,
    required this.label,
    required this.seedColor,
    required this.previewColor,
  });

  /// Varsayilan tema kimligi (const baglamlarda kullanilir).
  static const purpleKey = 'purple';

  final String key;
  final String label;
  final Color seedColor;
  final Color previewColor;

  ColorScheme get darkColorScheme =>
      ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark);

  ColorScheme get lightColorScheme =>
      ColorScheme.fromSeed(seedColor: seedColor);

  static AppThemeVariant fromKey(String key) => AppThemeVariant.values
      .firstWhere((v) => v.key == key, orElse: () => AppThemeVariant.purple);
}
