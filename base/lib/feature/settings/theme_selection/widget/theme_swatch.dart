import 'package:flutter/material.dart';

/// Tema secim sayfasinda kullanilan renk dairesi + etiket karti.
///
/// Secili oldugunda renk dairesine bir onay ikonu biner; ikon rengi,
/// `estimateBrightnessForColor` ile arkaplana gore otomatik secilir
/// (acik renklerde siyah, koyu renklerde beyaz) — kontrast garantisi.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// Daire icinde gosterilecek istege bagli ikon (or. custom icin palet).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_rounded, color: onColor, size: 18)
                else if (icon != null)
                  Icon(icon, color: onColor, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
