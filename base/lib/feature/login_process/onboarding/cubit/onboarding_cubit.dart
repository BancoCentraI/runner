import 'package:akillisletme/product/service/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Onboarding sayfa navigasyonunu yoneten Cubit.
/// State olarak mevcut sayfa index'ini tutar.
class OnboardingCubit extends Cubit<int> {
  OnboardingCubit() : super(0);

  PageController? pageController;

  static const int totalPages = 5;

  // ── Sayfa Navigasyonu ────────────────────────────────────

  void setPage(int page) => emit(page);

  bool get isFirstPage => state == 0;

  bool get isLastPage => state == totalPages - 1;

  /// Sonraki sayfaya gec
  void nextPage() {
    if (pageController?.hasClients ?? false) {
      if (state < totalPages - 1) {
        pageController?.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// Onceki sayfaya gec
  void previousPage() {
    if (pageController?.hasClients ?? false) {
      if (state > 0) {
        pageController?.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // ── Tamamlama ────────────────────────────────────────────

  /// Onboarding'i tamamla ve ana sayfaya yonlendir
  Future<void> completeOnboarding(BuildContext context) async {
    await locator.sharedCache.setOnboardingCompleted(value: true);
    if (context.mounted) {
      context.go('/');
    }
  }

  @override
  Future<void> close() {
    pageController = null;
    return super.close();
  }
}
