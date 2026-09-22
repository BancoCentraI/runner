import 'dart:io';

import 'package:akillisletme/product/const/app_string.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareAppTile extends StatelessWidget {
  const ShareAppTile({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(Icons.share_rounded, color: cs.onSurfaceVariant),
      title: Text(LocaleKeys.settings_shareApp.tr()),
      onTap: () async {
        final url = Platform.isIOS
            ? AppString.appStoreUrl
            : AppString.playStoreUrl;
        try {
          await SharePlus.instance.share(ShareParams(text: url));
        } on MissingPluginException {
          // Simulator'da share desteklenmeyebilir
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(url)));
          }
        }
      },
    );
  }
}
