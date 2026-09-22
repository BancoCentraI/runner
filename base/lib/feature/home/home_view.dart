import 'dart:io';

import 'package:akillisletme/feature/home/home_view_mode.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/navigation/app_router.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:akillisletme/product/widget/app_secondary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends HomeViewMode {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.home_title.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => const SettingsRoute().push<void>(context),
          ),
        ],
      ),
      body: Padding(
        padding: AppPaddings.allL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppPaddings.l,
          children: [
            AppPrimaryButton(
              label: 'Material Widgets',
              icon: Icons.widgets_outlined,
              onPressed: () => const MaterialWidgetsRoute().push<void>(context),
            ),
            AppSecondaryButton(
              label: 'Cupertino Widgets',
              icon: Icons.phone_iphone,
              onPressed: () =>
                  const CupertinoWidgetsRoute().push<void>(context),
            ),
            if (Platform.isAndroid) ...[
              const Divider(),
              AppSecondaryButton(
                label: LocaleKeys.androidModules_title.tr(),
                icon: Icons.android,
                onPressed: () =>
                    const AndroidModulesRoute().push<void>(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
