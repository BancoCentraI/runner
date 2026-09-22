import 'package:akillisletme/feature/login_process/auth/widget/auth_scaffold.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/const/app_semantic_keys.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/state/auth/auth_cubit.dart';
import 'package:akillisletme/product/utils/app_messenger.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:akillisletme/product/widget/app_secondary_button.dart';
import 'package:akillisletme/product/widget/app_semantics.dart';
import 'package:akillisletme/product/widget/app_text_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// `AppConfig.requireEmailVerification` acikken, dogrulanmamis kullanicinin
/// yonlendirildigi ekran.
///
/// Kullanici baglantiya **uygulama disinda** tikladigi icin dogrulama durumu
/// stream'e dusmez; "Dogruladim" butonu sunucudan elle tazeler.
class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({super.key});

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  bool _isBusy = false;

  Future<void> _check() async {
    setState(() => _isBusy = true);
    final verified = await context.read<AuthCubit>().reloadEmailVerified();
    if (!mounted) return;
    setState(() => _isBusy = false);

    // Dogrulandiysa yonlendirmeyi router yapar (guard yeniden degerlendirilir).
    if (!verified) {
      context.showInfoSnack(LocaleKeys.auth_verifyStillPending.tr());
    }
  }

  Future<void> _resend() async {
    setState(() => _isBusy = true);
    final result = await context.read<AuthCubit>().sendEmailVerification();
    if (!mounted) return;
    setState(() => _isBusy = false);

    switch (result) {
      case AuthActionSuccess():
        context.showSuccessSnack(LocaleKeys.auth_verifyResent.tr());
      case AuthActionFailure(:final message):
        context.showErrorSnack(message);
      case AuthActionCanceled():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthCubit, String?>(
      (cubit) => cubit.state.email,
    );

    return AppSemantics(
      semanticKey: AppSemanticKeys.emailVerificationView,
      child: AuthScaffold(
        showBackButton: false,
        icon: Icons.mark_email_unread_outlined,
        title: LocaleKeys.auth_verifyTitle.tr(),
        subtitle: LocaleKeys.auth_verifyMessage.tr(args: [email ?? '']),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppPaddings.m,
            children: [
              AppPrimaryButton(
                label: LocaleKeys.auth_verifyCheck.tr(),
                onPressed: _isBusy ? null : _check,
              ),
              AppSecondaryButton(
                label: LocaleKeys.auth_verifyResend.tr(),
                onPressed: _isBusy ? null : _resend,
              ),
              AppTextButton(
                label: LocaleKeys.auth_signOut.tr(),
                onPressed: context.read<AuthCubit>().signOut,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
