part of '../theme.dart';

InputDecorationTheme _buildInputDecorationTheme(
  ColorScheme cs,
  Brightness brightness,
) {
  final isDark = brightness == Brightness.dark;
  return InputDecorationTheme(
    filled: true,
    fillColor: isDark ? cs.surfaceContainerHighest : cs.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: 2),
    ),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    floatingLabelStyle: TextStyle(
      fontWeight: FontWeight.w500,
      color: cs.primary,
    ),
    hintStyle: TextStyle(
      color: cs.onSurface.withValues(alpha: 0.5),
      fontWeight: FontWeight.w400,
    ),
    labelStyle: TextStyle(
      color: cs.onSurface.withValues(alpha: 0.7),
      fontWeight: FontWeight.w500,
    ),
  );
}
