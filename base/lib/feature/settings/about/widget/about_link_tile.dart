import 'package:akillisletme/product/service/service_locator.dart';
import 'package:flutter/material.dart';

class AboutLinkTile extends StatelessWidget {
  const AboutLinkTile({
    required this.title,
    required this.url,
    required this.icon,
    super.key,
  });

  final String title;
  final String url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(title),
      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
      onTap: () => locator.urlLauncher.openInApp(url),
    );
  }
}
