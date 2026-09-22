import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Aktif temayi canli gosteren onizleme karti.
///
/// Sayfanin tamami zaten aktif temayla cizilir; bu kart ornek bir AppBar +
/// buton + switch + chip + metin bir araya getirerek secimin etkisini tek
/// bakista, uygulamadan cikmadan gosterir.
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ornek AppBar
          Container(
            height: 48,
            color: cs.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.menu_rounded, color: cs.onPrimary, size: 20),
                const SizedBox(width: 12),
                Text(
                  LocaleKeys.theme_preview.tr(),
                  style: textTheme.titleMedium?.copyWith(color: cs.onPrimary),
                ),
                const Spacer(),
                Icon(Icons.more_vert_rounded, color: cs.onPrimary, size: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.theme_previewHeadline.tr(),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleKeys.theme_previewBody.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () {},
                      child: Text(LocaleKeys.theme_previewAction.tr()),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      child: Text(LocaleKeys.theme_previewAction.tr()),
                    ),
                    const Spacer(),
                    Switch(value: true, onChanged: (_) {}),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(LocaleKeys.theme_name_custom.tr()),
                      backgroundColor: cs.secondaryContainer,
                    ),
                    Chip(
                      label: Text(LocaleKeys.theme_preview.tr()),
                      backgroundColor: cs.tertiaryContainer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
