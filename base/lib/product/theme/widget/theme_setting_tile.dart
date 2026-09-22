import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/navigation/app_router.dart';
import 'package:akillisletme/product/theme/state/theme_cubit.dart';
import 'package:akillisletme/product/utils/theme_decorations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Uygulama tema secim tile'i (buyuk, gradient kart). Tam tema sayfasini acar.
class ThemeSettingTile extends StatelessWidget {
  const ThemeSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final previewColor = context.watch<ThemeCubit>().state.previewColor;
    return GestureDetector(
      onTap: () => const ThemeSelectionRoute().push<void>(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: context.settingContainerDecoration,
        child: Row(
          children: [
            Icon(Icons.palette_rounded, color: previewColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                LocaleKeys.settings_appTheme.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: previewColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
