import 'package:akillisletme/feature/settings/about/widget/about_link_tile.dart';
import 'package:akillisletme/feature/settings/about/widget/version_tile.dart';
import 'package:akillisletme/feature/settings/widget/settings_section.dart';
import 'package:akillisletme/product/const/app_string.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale; // Dil degisiminde rebuild tetiklemek icin

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.settings_aboutTitle.tr())),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          SettingsSection(
            title: LocaleKeys.settings_legalAndPolicies.tr(),
            children: [
              AboutLinkTile(
                title: LocaleKeys.settings_privacyPolicy.tr(),
                url: AppString.privacyPolicyUrl,
                icon: Icons.privacy_tip_outlined,
              ),
              AboutLinkTile(
                title: LocaleKeys.settings_termsOfService.tr(),
                url: AppString.termsOfServiceUrl,
                icon: Icons.description_outlined,
              ),
              AboutLinkTile(
                title: LocaleKeys.settings_kvkkClarification.tr(),
                url: AppString.kvkkClarificationUrl,
                icon: Icons.people_outline_rounded,
              ),
              AboutLinkTile(
                title: LocaleKeys.settings_consentDeclaration.tr(),
                url: AppString.consentDeclarationUrl,
                icon: Icons.check_circle_outline_rounded,
              ),
              AboutLinkTile(
                title: LocaleKeys.settings_acceptableUsePolicy.tr(),
                url: AppString.acceptableUsePolicyUrl,
                icon: Icons.article_outlined,
              ),
              AboutLinkTile(
                title: LocaleKeys.settings_refundPolicy.tr(),
                url: AppString.refundPolicyUrl,
                icon: Icons.currency_exchange_rounded,
              ),
              AboutLinkTile(
                title: LocaleKeys.settings_copyrightNotice.tr(),
                url: AppString.copyrightNoticeUrl,
                icon: Icons.copyright_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SettingsSection(children: [VersionTile()]),
        ],
      ),
    );
  }
}
