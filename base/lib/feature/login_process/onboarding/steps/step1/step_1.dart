import 'package:akillisletme/feature/settings/language_selection/widget/language_grid_content.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Onboarding Step 1 — Language Selection
class Step1 extends StatelessWidget {
  const Step1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPaddings.allXxl,
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                LocaleKeys.language_chooseYourLanguage.tr(),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8, width: double.infinity),
              Text(
                LocaleKeys.language_selectPreferredLanguage.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const LanguageGridContent(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
