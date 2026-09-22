import 'package:akillisletme/feature/login_process/auth/register_view.dart';
import 'package:akillisletme/product/state/auth/auth_cubit.dart';
import 'package:akillisletme/product/utils/app_messenger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class RegisterViewModel extends State<RegisterView> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordAgainController = TextEditingController();

  bool isBusy = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordAgainController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isBusy = true);
    final result = await context.read<AuthCubit>().register(
      email: emailController.text,
      password: passwordController.text,
      name: nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => isBusy = false);

    handleResult(result);
  }

  /// Basarida yonlendirme yapilmaz — oturum stream'den akar, router
  /// `refreshListenable` ile kendisi yonlendirir.
  void handleResult(AuthActionResult result) {
    if (result case AuthActionFailure(:final message)) {
      context.showErrorSnack(message);
    }
  }
}
