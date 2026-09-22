import 'dart:io';

import 'package:akillisletme/feature/settings/widget/about_tile.dart';
import 'package:akillisletme/feature/settings/widget/background_animation_tile.dart';
import 'package:akillisletme/feature/settings/widget/contact_us_tile.dart';
import 'package:akillisletme/feature/settings/widget/language_tile.dart';
import 'package:akillisletme/feature/settings/widget/overlay_tile.dart';
import 'package:akillisletme/feature/settings/widget/rate_app_tile.dart';
import 'package:akillisletme/feature/settings/widget/settings_section.dart';
import 'package:akillisletme/feature/settings/widget/share_app_tile.dart';
import 'package:akillisletme/feature/settings/widget/theme_tile.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale; // Dil degisiminde rebuild tetiklemek icin

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.settings_title.tr())),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          SettingsSection(
            title: LocaleKeys.settings_appearance.tr(),
            children: const [
              ThemeTile(),
              LanguageTile(),
              BackgroundAnimationTile(),
            ],
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: AppPaddings.l),
            SettingsSection(
              title: LocaleKeys.settings_android.tr(),
              children: const [OverlayTile()],
            ),
          ],
          const SizedBox(height: AppPaddings.l),
          SettingsSection(
            title: LocaleKeys.settings_support.tr(),
            children: const [ContactUsTile(), RateAppTile(), ShareAppTile()],
          ),
          const SizedBox(height: AppPaddings.l),
          SettingsSection(
            title: LocaleKeys.settings_aboutTitle.tr(),
            children: const [AboutTile()],
          ),
        ],
      ),
    );
  }
}
