import 'package:akillisletme/feature/home/widget/home_background.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/service/service_locator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BackgroundAnimationTile extends StatelessWidget {
  const BackgroundAnimationTile({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: HomeBackground.enabledNotifier,
      builder: (context, enabled, _) {
        return SwitchListTile(
          secondary: Icon(Icons.animation, color: cs.onSurfaceVariant),
          title: Text(LocaleKeys.settings_backgroundAnimation.tr()),
          value: enabled,
          onChanged: (value) {
            HomeBackground.enabledNotifier.value = value;
            locator.sharedCache.setBackgroundAnimation(enabled: value);
          },
        );
      },
    );
  }
}
