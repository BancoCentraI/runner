part of '../theme.dart';

SwitchThemeData _buildSwitchTheme(ColorScheme cs) => SwitchThemeData(
  thumbColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return cs.onPrimary;
    return cs.outline;
  }),
  trackColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return cs.primary;
    return cs.surfaceContainerHighest;
  }),
  trackOutlineColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return Colors.transparent;
    return cs.outline;
  }),
);
