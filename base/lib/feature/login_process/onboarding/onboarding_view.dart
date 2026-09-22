import 'dart:async';

import 'package:akillisletme/feature/login_process/onboarding/cubit/onboarding_cubit.dart';
import 'package:akillisletme/feature/login_process/onboarding/onboarding_view_model.dart';
import 'package:akillisletme/feature/login_process/onboarding/steps/step1/step_1.dart';
import 'package:akillisletme/feature/login_process/onboarding/steps/step2/step_2.dart';
import 'package:akillisletme/feature/login_process/onboarding/steps/step3/step_3.dart';
import 'package:akillisletme/feature/login_process/onboarding/steps/step4/step_4.dart';
import 'package:akillisletme/feature/login_process/onboarding/steps/step_5.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

part 'widget/onboarding_nav_button.dart';

/// Onboarding akisi — 5 adimlik PageView.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends OnboardingViewModel {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingCubit>.value(
      value: cubit,
      child: Scaffold(
        body: Stack(
          children: [
            PageView(
              controller: pageController,
              onPageChanged: cubit.setPage,
              children: const [Step1(), Step2(), Step3(), Step4(), Step5()],
            ),
            _BottomNavigation(pageController: pageController, cubit: cubit),
          ],
        ),
      ),
    );
  }
}

/// Alt navigasyon: Sol ok + Indicator + Sag ok
class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.pageController, required this.cubit});

  final PageController pageController;
  final OnboardingCubit cubit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dotColor = cs.onSurface;

    return BlocBuilder<OnboardingCubit, int>(
      builder: (context, currentPage) {
        final isFirstPage = currentPage == 0;
        final isLastPage = currentPage == OnboardingCubit.totalPages - 1;

        return Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sol ok
                if (!isFirstPage)
                  OnboardingNavButton(
                    icon: Icons.arrow_back,
                    onPressed: cubit.previousPage,
                  )
                else
                  const SizedBox(width: 56),

                // Sayfa gostergesi
                SmoothPageIndicator(
                  controller: pageController,
                  count: OnboardingCubit.totalPages,
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 12,
                    activeDotColor: cs.primary,
                    dotColor: dotColor.withValues(alpha: 0.2),
                  ),
                ),

                // Sag ok
                OnboardingNavButton(
                  icon: Icons.arrow_forward,
                  isAccent: isLastPage,
                  onPressed: isLastPage
                      ? () => cubit.completeOnboarding(context)
                      : cubit.nextPage,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
