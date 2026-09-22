import 'package:akillisletme/product/const/app_config.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/state/auth/auth_cubit.dart';
import 'package:akillisletme/product/widget/app_secondary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Acik olan sosyal saglayicilarin butonlari.
///
/// Hangi butonun cizilecegini `AppConfig` bayraklari belirler — kurulum akisi
/// (`doc/guides/auth_setup.md`) yalnizca o bayraklari cevirir, bu dosyaya
/// dokunmaz.
///
/// Apple butonu yalnizca **iOS/macOS**'ta cizilir: `sign_in_with_apple`
/// Android'de de calisir ama web akisina duser ve Android kullanicisi icin
/// gereksiz surtunmedir.
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({
    required this.onResult,
    super.key,
    this.isBusy = false,
  });

  /// Giris denemesi bittiginde cagrilir — ekran geri bildirimi gosterir.
  final void Function(AuthActionResult result) onResult;

  /// Baska bir islem surerken butonlari pasif tutar.
  final bool isBusy;

  static bool get _showApple =>
      AppConfig.enableAppleSignIn &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasSocialSignIn) return const SizedBox.shrink();

    final cubit = context.read<AuthCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppPaddings.m,
      children: [
        if (AppConfig.enableGoogleSignIn)
          AppSecondaryButton(
            label: LocaleKeys.auth_continueWithGoogle.tr(),
            icon: FontAwesomeIcons.google,
            onPressed: isBusy
                ? null
                : () async => onResult(await cubit.signInWithGoogle()),
          ),
        if (_showApple)
          AppSecondaryButton(
            label: LocaleKeys.auth_continueWithApple.tr(),
            icon: FontAwesomeIcons.apple,
            onPressed: isBusy
                ? null
                : () async => onResult(await cubit.signInWithApple()),
          ),
      ],
    );
  }
}
