import 'package:flutter/material.dart';

/// Çeviriye tabi olmayan sabit stringler.
/// Çevirili stringler için LocaleKeys + .tr() kullan.
@immutable
final class AppString {
  const AppString._();

  // ── Store URL'leri (çeviriye tabi değil) ───────────────────
  static const String appStoreUrl =
      'https://apps.apple.com/app/instagram/id389801252';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.instagram.android';

  // ── İletişim & Destek ─────────────────────────────────────
  static const String contactEmail = 'akillisletme.1@gmail.com';

  // ── Yasal Belge URL'leri (placeholder) ────────────────────
  static const String privacyPolicyUrl = 'https://flutter.dev';
  static const String termsOfServiceUrl = 'https://flutter.dev';
  static const String kvkkClarificationUrl = 'https://flutter.dev';
  static const String consentDeclarationUrl = 'https://flutter.dev';
  static const String acceptableUsePolicyUrl = 'https://flutter.dev';
  static const String refundPolicyUrl = 'https://flutter.dev';
  static const String copyrightNoticeUrl = 'https://flutter.dev';
}
