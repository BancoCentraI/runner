part of '../theme.dart';

/// Aktif tema durumuna gore `ColorScheme` cozumler.
///
/// Material You acik ve sistem semasi mevcutsa onu, aksi halde tema spec'inin
/// urettigi semayi dondurur.
ColorScheme _resolveScheme(
  ThemeState state,
  ThemeSpec spec,
  Brightness brightness,
  ColorScheme? dynamicScheme,
) {
  if (state.useSystemColors && dynamicScheme != null) {
    return dynamicScheme;
  }
  return spec.schemeFor(brightness);
}
