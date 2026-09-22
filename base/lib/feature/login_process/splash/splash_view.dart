import 'package:akillisletme/feature/login_process/splash/state/splash_cubit.dart';
import 'package:akillisletme/product/const/app_icon_sizes.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/const/app_radius.dart';
import 'package:akillisletme/product/const/app_semantic_keys.dart';
import 'package:akillisletme/product/const/app_string.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/navigation/app_router.dart';
import 'package:akillisletme/product/service/service_locator.dart';
import 'package:akillisletme/product/utils/extension/context_extension.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:akillisletme/product/widget/app_semantics.dart';
import 'package:akillisletme/product/widget/state/app_error_view.dart';
import 'package:akillisletme/product/widget/state/app_loading_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

part 'widgets/update_required_view.dart';

final class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SplashBody();
  }
}

final class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return AppSemantics(
      semanticKey: AppSemanticKeys.splashView,
      child: Scaffold(
        body: BlocConsumer<SplashCubit, SplashState>(
          listener: (context, state) {
            state.whenOrNull(
              success: () {
                // Splash yalnizca kapidir; nereye gidilecegine burada karar
                // verilir. Ilk acilista onboarding, sonrasinda ana ekran.
                if (locator.sharedCache.isOnboardingCompleted) {
                  const HomeRoute().go(context);
                } else {
                  const OnboardingRoute().go(context);
                }
              },
            );
          },
          builder: (context, state) {
            final retry = context.read<SplashCubit>().retry;

            return state.when(
              initial: () => const AppLoadingView(showMessage: true),
              checking: () => const AppLoadingView(showMessage: true),
              // Yonlendirme listener'da yapiliyor; burada bos kalir.
              success: () => const SizedBox.shrink(),
              updateRequired: (currentVersion, minimumVersion) {
                return _UpdateRequiredView(
                  currentVersion: currentVersion,
                  minimumVersion: minimumVersion,
                );
              },
              offline: () => AppErrorView.offline(onRetry: retry),
              error: (message) =>
                  AppErrorView(message: message, onRetry: retry),
            );
          },
        ),
      ),
    );
  }
}
