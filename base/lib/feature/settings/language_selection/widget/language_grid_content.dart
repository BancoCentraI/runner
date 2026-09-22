import 'package:akillisletme/feature/settings/language_selection/widget/language_card.dart';
import 'package:akillisletme/product/init/language/language_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguageGridContent extends StatelessWidget {
  const LanguageGridContent({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemCount: LanguageItem.all.length,
      itemBuilder: (context, index) {
        final item = LanguageItem.all[index];
        final isSelected =
            item.locale.languageCode == currentLocale.languageCode;
        return LanguageCard(
          item: item,
          isSelected: isSelected,
          onTap: () async {
            await HapticFeedback.selectionClick();
            if (context.mounted) {
              await context.setLocale(item.locale);
            }
          },
        );
      },
    );
  }
}
