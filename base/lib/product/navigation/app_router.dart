import 'package:akillisletme/feature/home/android_modules/android_modules_view.dart';
import 'package:akillisletme/feature/home/cupertino_widgets/cupertino_widgets_view.dart';
import 'package:akillisletme/feature/home/home_view.dart';
import 'package:akillisletme/feature/home/material_widgets/material_widgets_view.dart';
import 'package:akillisletme/feature/login_process/auth/email_verification_view.dart';
import 'package:akillisletme/feature/login_process/auth/forgot_password_view.dart';
import 'package:akillisletme/feature/login_process/auth/login_view.dart';
import 'package:akillisletme/feature/login_process/auth/register_view.dart';
import 'package:akillisletme/feature/login_process/onboarding/onboarding_view.dart';
import 'package:akillisletme/feature/login_process/splash/splash_view.dart';
import 'package:akillisletme/feature/login_process/splash/state/splash_cubit.dart';
import 'package:akillisletme/feature/settings/about/about_view.dart';
import 'package:akillisletme/feature/settings/language_selection/language_selection_view.dart';
import 'package:akillisletme/feature/settings/settings_view.dart';
import 'package:akillisletme/feature/settings/theme_selection/theme_selection_view.dart';
import 'package:akillisletme/product/const/app_config.dart';
import 'package:akillisletme/product/navigation/route_transitions.dart';
import 'package:akillisletme/product/navigation/router_refresh.dart';
import 'package:akillisletme/product/service/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'app_router.g.dart';

@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<SettingsRoute>(
      path: 'settings',
      routes: [
        TypedGoRoute<AboutRoute>(path: 'about'),
        TypedGoRoute<LanguageSelectionRoute>(path: 'language'),
        TypedGoRoute<ThemeSelectionRoute>(path: 'theme'),
      ],
    ),
    TypedGoRoute<MaterialWidgetsRoute>(path: 'material-widgets'),
    TypedGoRoute<CupertinoWidgetsRoute>(path: 'cupertino-widgets'),
    TypedGoRoute<AndroidModulesRoute>(path: 'android-modules'),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return fadeTransition(key: state.pageKey, child: const HomeView());
  }
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const SettingsView(),
    );
  }
}

class AboutRoute extends GoRouteData with $AboutRoute {
  const AboutRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(key: state.pageKey, child: const AboutView());
  }
}

class LanguageSelectionRoute extends GoRouteData with $LanguageSelectionRoute {
  const LanguageSelectionRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const LanguageSelectionView(),
    );
  }
}

class ThemeSelectionRoute extends GoRouteData with $ThemeSelectionRoute {
  const ThemeSelectionRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const ThemeSelectionView(),
    );
  }
}

class MaterialWidgetsRoute extends GoRouteData with $MaterialWidgetsRoute {
  const MaterialWidgetsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const MaterialWidgetsView(),
    );
  }
}

class CupertinoWidgetsRoute extends GoRouteData with $CupertinoWidgetsRoute {
  const CupertinoWidgetsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const CupertinoWidgetsView(),
    );
  }
}

class AndroidModulesRoute extends GoRouteData with $AndroidModulesRoute {
  const AndroidModulesRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const AndroidModulesView(),
    );
  }
}

/// Acilis kapisi — zorunlu guncelleme kontrolu burada yapilir, sonra
/// onboarding ya da ana ekrana yonlendirir.
@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return fadeTransition(
      key: state.pageKey,
      child: BlocProvider(
        create: (_) =>
            SplashCubit(versionSource: locator.versionSource)..checkApp(),
        child: const SplashView(),
      ),
    );
  }
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return fadeTransition(key: state.pageKey, child: const OnboardingView());
  }
}

@TypedGoRoute<LoginRoute>(
  path: '/auth/login',
  routes: [
    TypedGoRoute<RegisterRoute>(path: 'register'),
    TypedGoRoute<ForgotPasswordRoute>(path: 'forgot-password'),
  ],
)
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(key: state.pageKey, child: const LoginView());
  }
}

class RegisterRoute extends GoRouteData with $RegisterRoute {
  const RegisterRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const RegisterView(),
    );
  }
}

class ForgotPasswordRoute extends GoRouteData with $ForgotPasswordRoute {
  const ForgotPasswordRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const ForgotPasswordView(),
    );
  }
}

@TypedGoRoute<EmailVerificationRoute>(path: '/auth/verify-email')
class EmailVerificationRoute extends GoRouteData with $EmailVerificationRoute {
  const EmailVerificationRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return fadeTransition(
      key: state.pageKey,
      child: const EmailVerificationView(),
    );
  }
}

/// App router configuration
final class AppRouter {
  AppRouter._();

  /// Oturum isteyen rota onekleri.
  ///
  /// Liste **bilincli olarak dar**: misafir uygulamayi gezebilir
  /// (`AppConfig.allowGuestBrowsing`). Kayit duvari donusumu dusurur — once
  /// degeri goster, hesaba baglanan yerde giris iste. Yeni korumali rota
  /// gerektiginde onekini buraya eklemek yeterlidir.
  static const List<String> protectedPrefixes = ['/profile'];

  /// Auth ekranlarinin oneki — oturumlu kullanici buraya donemez.
  static const String _authPrefix = '/auth';

  /// Merkezi auth-guard.
  ///
  /// Yonlendirme karari tek yerdedir; ekranlarda `if (loggedIn) ...` yazilmaz.
  /// Oturum degisimi [GoRouterRefreshStream] ile aninda yeniden degerlendirilir
  /// (cikis yapilinca korumali sayfadan otomatik cikarilir).
  ///
  /// **Kural:** guard'li rotalara daima `go` ile gidilir. `push` imperative'dir;
  /// declarative URI degismedigi icin `refreshListenable` tetiklendiginde
  /// pushed sayfanin redirect'i bir daha calismaz ve giris ekrani ekranda
  /// takili kalir.
  static String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    // Splash ve onboarding kapi oncesi ekranlardir; guard onlara karismaz,
    // yoksa acilista birbirini ezen iki yonlendirme olusur.
    if (location == const SplashRoute().location ||
        location == const OnboardingRoute().location) {
      return null;
    }

    final user = locator.auth.currentUser;
    final isLoggedIn = user != null;
    final isAuthRoute = location.startsWith(_authPrefix);

    if (!isLoggedIn) {
      if (isAuthRoute) return null;
      final needsLogin =
          !AppConfig.allowGuestBrowsing ||
          protectedPrefixes.any(location.startsWith);
      return needsLogin ? const LoginRoute().location : null;
    }

    // E-posta dogrulamasi zorunluysa, dogrulanmamis kullanici yalnizca
    // dogrulama ekranini gorebilir.
    if (AppConfig.requireEmailVerification && !user.emailVerified) {
      final verifyLocation = const EmailVerificationRoute().location;
      return location == verifyLocation ? null : verifyLocation;
    }

    // Oturumlu kullanici giris ekranlarina donemez.
    if (isAuthRoute) return const HomeRoute().location;

    return null;
  }

  static final GoRouter router = GoRouter(
    // Her acilis splash'tan gecer: zorunlu guncelleme kapisi orada calisir ve
    // onboarding/ana ekran karari orada verilir.
    initialLocation: const SplashRoute().location,
    refreshListenable: GoRouterRefreshStream(locator.auth.authStateChanges()),
    redirect: _redirect,
    routes: $appRoutes,
  );
}
