import 'package:akillisletme/feature/login_process/onboarding/cubit/onboarding_cubit.dart';
import 'package:akillisletme/feature/login_process/onboarding/onboarding_view.dart';
import 'package:flutter/material.dart';

abstract class OnboardingViewModel extends State<OnboardingView> {
  late final PageController pageController;
  late final OnboardingCubit cubit;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    cubit = OnboardingCubit()..pageController = pageController;
  }

  @override
  void dispose() {
    pageController.dispose();
    cubit.close();
    super.dispose();
  }
}
