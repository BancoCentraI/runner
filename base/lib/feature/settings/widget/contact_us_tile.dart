import 'package:akillisletme/product/const/app_string.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/service/service_locator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ContactUsTile extends StatelessWidget {
  const ContactUsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(Icons.mail_outline_rounded, color: cs.onSurfaceVariant),
      title: Text(LocaleKeys.settings_contactUs.tr()),
      onTap: () => locator.urlLauncher.sendEmail(to: AppString.contactEmail),
    );
  }
}
