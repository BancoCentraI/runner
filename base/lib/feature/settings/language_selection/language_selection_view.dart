import 'package:akillisletme/feature/settings/language_selection/widget/language_grid_content.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageSelectionView extends StatelessWidget {
  const LanguageSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale; // Dil degisiminde rebuild tetiklemek icin

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.language_chooseYourLanguage.tr())),
      body: SingleChildScrollView(
        padding: AppPaddings.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Text(
              LocaleKeys.language_selectPreferredLanguage.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const LanguageGridContent(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
