import 'package:akillisletme/feature/login_process/auth/login_view_model.dart';
import 'package:akillisletme/feature/login_process/auth/widget/auth_scaffold.dart';
import 'package:akillisletme/feature/login_process/auth/widget/social_sign_in_buttons.dart';
import 'package:akillisletme/product/const/app_config.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/const/app_semantic_keys.dart';
import 'package:akillisletme/product/enum/text_field_type.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/navigation/app_router.dart';
import 'package:akillisletme/product/utils/validator/app_validator.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:akillisletme/product/widget/app_semantics.dart';
import 'package:akillisletme/product/widget/app_text_button.dart';
import 'package:akillisletme/product/widget/app_text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends LoginViewModel {
  @override
  Widget build(BuildContext context) {
    return AppSemantics(
      semanticKey: AppSemanticKeys.loginView,
      child: AuthScaffold(
        icon: Icons.lock_outline_rounded,
        title: LocaleKeys.auth_signInTitle.tr(),
        subtitle: LocaleKeys.auth_signInSubtitle.tr(),
        children: [
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppPaddings.m,
              children: [
                AppTextField(
                  controller: emailController,
                  label: LocaleKeys.auth_email.tr(),
                  type: TextFieldType.email,
                  validator: Validators.email,
                  prefixIcon: Icons.mail_outline_rounded,
                ),
                AppTextField(
                  controller: passwordController,
                  label: LocaleKeys.auth_password.tr(),
                  type: TextFieldType.password,
                  // Girişte sifre KURALI dogrulanmaz, yalnizca bosluk kontrolu
                  // yapilir: mevcut sifre kurallar degismeden once
                  // olusturulmus olabilir ve "sifre cok zayif" demek yanlis
                  // olurdu. Kural yalnizca kayitta uygulanir.
                  validator: Validators.required,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => submit(),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AppTextButton(
                    label: LocaleKeys.auth_forgotPassword.tr(),
                    onPressed: () =>
                        const ForgotPasswordRoute().push<void>(context),
                  ),
                ),
                AppSemantics(
                  semanticKey: AppSemanticKeys.loginSubmitButton,
                  child: AppPrimaryButton(
                    label: LocaleKeys.auth_signIn.tr(),
                    onPressed: isBusy ? null : submit,
                  ),
                ),
              ],
            ),
          ),
          if (AppConfig.hasSocialSignIn) ...[
            AuthDivider(label: LocaleKeys.auth_orDivider.tr()),
            SocialSignInButtons(isBusy: isBusy, onResult: handleResult),
          ],
          AuthFooterAction(
            question: LocaleKeys.auth_noAccount.tr(),
            actionLabel: LocaleKeys.auth_signUp.tr(),
            onPressed: () => const RegisterRoute().push<void>(context),
          ),
        ],
      ),
    );
  }
}
