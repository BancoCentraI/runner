part of '../theme.dart';

SliderThemeData _buildSliderTheme(ColorScheme cs) => SliderThemeData(
  activeTrackColor: cs.primary,
  inactiveTrackColor: cs.onSurface.withValues(alpha: 0.1),
  thumbColor: cs.primary,
  overlayColor: cs.primary.withValues(alpha: 0.2),
);
