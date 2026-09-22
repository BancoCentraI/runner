import 'package:akillisletme/feature/login_process/auth/widget/auth_scaffold.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/const/app_semantic_keys.dart';
import 'package:akillisletme/product/enum/text_field_type.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/state/auth/auth_cubit.dart';
import 'package:akillisletme/product/utils/app_messenger.dart';
import 'package:akillisletme/product/utils/validator/app_validator.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:akillisletme/product/widget/app_semantics.dart';
import 'package:akillisletme/product/widget/app_text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    final result = await context.read<AuthCubit>().sendPasswordReset(
      _emailController.text,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);

    switch (result) {
      case AuthActionSuccess():
        context.showSuccessSnack(LocaleKeys.auth_resetLinkSent.tr());
        // Kullaniciyi bekletme — mesaj gonderildi, giris ekranina don.
        Navigator.of(context).pop();
      case AuthActionFailure(:final message):
        context.showErrorSnack(message);
      case AuthActionCanceled():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSemantics(
      semanticKey: AppSemanticKeys.forgotPasswordView,
      child: AuthScaffold(
        icon: Icons.lock_reset_rounded,
        title: LocaleKeys.auth_forgotTitle.tr(),
        subtitle: LocaleKeys.auth_forgotSubtitle.tr(),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppPaddings.m,
              children: [
                AppTextField(
                  controller: _emailController,
                  label: LocaleKeys.auth_email.tr(),
                  type: TextFieldType.email,
                  validator: Validators.email,
                  prefixIcon: Icons.mail_outline_rounded,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                AppPrimaryButton(
                  label: LocaleKeys.auth_sendResetLink.tr(),
                  onPressed: _isBusy ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
