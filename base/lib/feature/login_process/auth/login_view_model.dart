import 'package:akillisletme/feature/login_process/auth/login_view.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/state/auth/auth_cubit.dart';
import 'package:akillisletme/product/utils/app_messenger.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LoginViewModel extends State<LoginView> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isBusy = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isBusy = true);
    final result = await context.read<AuthCubit>().signInWithEmail(
      emailController.text,
      passwordController.text,
    );
    if (!mounted) return;
    setState(() => isBusy = false);

    handleResult(result);
  }

  /// Sonucu tek yerde ele alir.
  ///
  /// Basarida **hicbir sey yapilmaz**: oturum `authStateChanges` stream'inden
  /// akar, router `refreshListenable` ile yonlendirmeyi kendisi yapar. Burada
  /// elle `go`/`pop` cagirmak cift yonlendirmeye yol acardi.
  ///
  /// Iptalde de sessiz kalinir — kullanici zaten bilincli olarak vazgecti.
  void handleResult(AuthActionResult result) {
    if (result case AuthActionFailure(:final message)) {
      context.showErrorSnack(message);
    }
  }

  Future<void> sendResetLink(String email) async {
    final result = await context.read<AuthCubit>().sendPasswordReset(email);
    if (!mounted) return;

    switch (result) {
      case AuthActionSuccess():
        context.showSuccessSnack(LocaleKeys.auth_resetLinkSent.tr());
      case AuthActionFailure(:final message):
        context.showErrorSnack(message);
      case AuthActionCanceled():
        break;
    }
  }
}
