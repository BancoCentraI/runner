part of '../theme.dart';

ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme cs) =>
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );

FilledButtonThemeData _buildFilledButtonTheme(ColorScheme cs) =>
    FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );

OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme cs) =>
    OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: cs.primary),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );

final _dialogTheme = DialogThemeData(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  elevation: 8,
  alignment: Alignment.center,
  titleTextStyle: const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
  ),
  contentTextStyle: const TextStyle(
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.25,
  ),
  actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
);
