import 'package:akillisletme/feature/login_process/auth/register_view_model.dart';
import 'package:akillisletme/feature/login_process/auth/widget/auth_scaffold.dart';
import 'package:akillisletme/feature/login_process/auth/widget/social_sign_in_buttons.dart';
import 'package:akillisletme/product/const/app_config.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/const/app_semantic_keys.dart';
import 'package:akillisletme/product/enum/text_field_type.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/utils/validator/app_validator.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:akillisletme/product/widget/app_semantics.dart';
import 'package:akillisletme/product/widget/app_text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends RegisterViewModel {
  @override
  Widget build(BuildContext context) {
    return AppSemantics(
      semanticKey: AppSemanticKeys.registerView,
      child: AuthScaffold(
        icon: Icons.person_add_alt_1_outlined,
        title: LocaleKeys.auth_signUpTitle.tr(),
        subtitle: LocaleKeys.auth_signUpSubtitle.tr(),
        children: [
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppPaddings.m,
              children: [
                AppTextField(
                  controller: nameController,
                  label: LocaleKeys.auth_name.tr(),
                  type: TextFieldType.name,
                  validator: Validators.fullName,
                  prefixIcon: Icons.person_outline_rounded,
                ),
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
                  validator: Validators.password,
                ),
                AppTextField(
                  controller: passwordAgainController,
                  label: LocaleKeys.auth_passwordAgain.tr(),
                  type: TextFieldType.password,
                  validator: Validators.match(() => passwordController.text),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => submit(),
                ),
                AppSemantics(
                  semanticKey: AppSemanticKeys.registerSubmitButton,
                  child: AppPrimaryButton(
                    label: LocaleKeys.auth_signUp.tr(),
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
            question: LocaleKeys.auth_haveAccount.tr(),
            actionLabel: LocaleKeys.auth_signIn.tr(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
