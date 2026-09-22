import 'dart:async';

import 'package:akillisletme/product/init/app_error_handler.dart';
import 'package:akillisletme/product/service/service_locator.dart';
import 'package:akillisletme/product/state/auth/auth_cubit.dart';
import 'package:akillisletme/product/state/subscription/subscription_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Oturum degisiminin uygulama genelindeki yan etkilerini tek yerde toplar.
///
/// `AuthCubit`'in icine konmadi: cubit'in odeme ve profil servislerini
/// tanimasi gereksiz bir baglilik olurdu. Burasi bir "kablo" katmanidir.
///
/// Yapilanlar:
/// - **RevenueCat kullanici kimligi** — baglanmazsa kullanici cihaz
///   degistirdiginde odedigi aboneligi kaybeder. En sik goruler RevenueCat
///   hatasi budur.
/// - **Analytics kimligi** ve giris olayi.
/// - **Profil upsert** — `users/{uid}` (Firebase kapaliyken no-op).
///
/// Yan etkilerin hicbiri oturumu bozmaz: hepsi ayri ayri yakalanip raporlanir.
class AuthSideEffects extends StatelessWidget {
  const AuthSideEffects({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      // Yalnizca kullanici kimligi degisince calis; ad/foto guncellemesi bu
      // yan etkileri tetiklemesin.
      listenWhen: (previous, current) => previous.uid != current.uid,
      listener: _onUserChanged,
      child: child,
    );
  }

  void _onUserChanged(BuildContext context, AuthState state) {
    final uid = state.uid;
    final subscriptions = context.read<SubscriptionCubit>();

    _guard(() => subscriptions.syncUser(uid));
    _guard(() => locator.analytics.setUserId(uid));

    if (uid == null) return;

    _guard(() => locator.analytics.logLogin(state.providerId ?? 'password'));

    final user = locator.auth.currentUser;
    if (user != null) {
      _guard(() => locator.userProfiles.upsertFromAuth(user));
    }
  }

  /// Yan etkiyi baslatir ve hatasini yutmadan raporlar.
  void _guard(Future<void> Function() action) {
    unawaited(action().catchError(AppErrorHandler.reportHandled));
  }
}
