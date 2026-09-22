part of '../theme.dart';

ChipThemeData _buildChipTheme(ColorScheme cs) => ChipThemeData(
  selectedColor: cs.primary,
  checkmarkColor: cs.onPrimary,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  side: BorderSide(color: cs.outlineVariant),
);
