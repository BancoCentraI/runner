import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionTile extends StatelessWidget {
  const VersionTile({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : '...';

        return ListTile(
          leading: Icon(Icons.info_outline_rounded, color: cs.onSurfaceVariant),
          title: Text(LocaleKeys.settings_version.tr()),
          trailing: Text(version, style: TextStyle(color: cs.onSurfaceVariant)),
        );
      },
    );
  }
}
