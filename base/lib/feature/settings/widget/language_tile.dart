import 'package:akillisletme/product/init/language/language_item.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/navigation/app_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentLocale = context.locale;

    final currentItem = LanguageItem.all.firstWhere(
      (item) => item.locale.languageCode == currentLocale.languageCode,
      orElse: () => LanguageItem.all.first,
    );

    return ListTile(
      leading: Icon(Icons.language, color: cs.onSurfaceVariant),
      title: Text(LocaleKeys.settings_language.tr()),
      trailing: Text(
        '${currentItem.flag} ${currentItem.nativeName}',
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      onTap: () => const LanguageSelectionRoute().push<void>(context),
    );
  }
}
