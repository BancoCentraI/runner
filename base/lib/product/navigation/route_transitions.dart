import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Sağdan sola kayarak açılan sayfa geçişi.
/// Yeni sayfa slide ile gelirken fade in olur, arka plan animasyonu korunur.
Page<dynamic> slideRightTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Yeni sayfa: slide + fade in
      final offsetAnimation = Tween(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

      final fadeIn = CurvedAnimation(parent: animation, curve: Curves.easeOut);

      // Eski sayfa: fade out
      final fadeOut = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
      );

      return FadeTransition(
        opacity: fadeOut,
        child: FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(position: offsetAnimation, child: child),
        ),
      );
    },
  );
}

/// Yumuşak fade geçişi.
/// Eski sayfa fade out, yeni sayfa fade in — sıralı interval ile üst üste binme önlenir.
Page<dynamic> fadeTransition({required LocalKey key, required Widget child}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Yeni sayfa: ikinci yarıda fade in (0.0–0.4 arası bekle, 0.4–1.0 fade in)
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.4, 1, curve: Curves.easeOut),
      );

      // Eski sayfa: fade out
      final fadeOut = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0, 0.6, curve: Curves.easeIn),
        ),
      );

      return FadeTransition(
        opacity: fadeOut,
        child: FadeTransition(opacity: fadeIn, child: child),
      );
    },
  );
}
