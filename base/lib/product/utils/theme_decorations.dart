import 'package:flutter/material.dart';

extension ThemeDecorations on BuildContext {
  BoxDecoration get settingContainerDecoration {
    final cs = Theme.of(this).colorScheme;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          cs.primary.withValues(alpha: 0.15),
          cs.primary.withValues(alpha: 0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
    );
  }
}
