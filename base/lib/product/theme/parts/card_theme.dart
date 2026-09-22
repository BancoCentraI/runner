part of '../theme.dart';

final _lightCardTheme = CardThemeData(
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  color: const Color.fromARGB(255, 250, 250, 250),
  shadowColor: Colors.black.withValues(alpha: 0.08),
  margin: const EdgeInsets.symmetric(vertical: 4),
);

final _darkCardTheme = CardThemeData(
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  color: const Color(0xFF1E1E1E),
  shadowColor: Colors.black.withValues(alpha: 0.3),
  margin: const EdgeInsets.symmetric(vertical: 4),
);
