import 'package:akillisletme/product/init/auth_side_effects.dart';
import 'package:akillisletme/product/service/service_locator.dart';
import 'package:akillisletme/product/state/auth/auth_cubit.dart';
import 'package:akillisletme/product/state/subscription/subscription_cubit.dart';
import 'package:akillisletme/product/theme/state/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// App-geneli cubit'ler. Uygulama omru boyunca yasarlar ve birden fazla ekran
/// tarafindan okunurlar.
final class StateInitialize extends StatelessWidget {
  const StateInitialize({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        // `lazy: false` sart: cubit oturum stream'ine abone oluyor ve kimligi
        // hata raporlamaya yansitiyor. Lazy birakilirsa bunlar ilk giris
        // ekrani acilana kadar hic calismaz.
        BlocProvider(create: (_) => AuthCubit(locator.auth), lazy: false),
        // `lazy: false`: acilista abonelik durumunu senkronlar. Lazy birakilirsa
        // premium kullanici paywall'a girene kadar ucretsiz gorunur.
        BlocProvider(
          create: (_) => SubscriptionCubit(
            purchaseService: locator.purchases,
            cache: locator.sharedCache,
          )..init(),
          lazy: false,
        ),
      ],
      child: AuthSideEffects(child: child),
    );
  }
}
