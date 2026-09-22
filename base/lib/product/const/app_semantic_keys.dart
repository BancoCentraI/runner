/// UI testlerinin (Maestro, integration_test) widget bulmak icin kullandigi
/// kimlikler.
///
/// Test id'leri kod icine dagilmis string'ler olarak degil, tek enum'da tutulur:
/// bir ekran yeniden adlandirildiginda testin hangi id'ye bagli oldugu derleyici
/// tarafindan gorunur olur, yazim hatasi runtime'a kacmaz.
///
/// Kullanim: widget'i `AppSemantics` ile sarmala.
///
/// ```dart
/// AppSemantics(
///   semanticKey: AppSemanticKeys.homeSettingsButton,
///   child: IconButton(...),
/// )
/// ```
enum AppSemanticKeys {
  // ── Acilis akisi ───────────────────────────────────────────
  splashView('splashView'),
  onboardingView('onboardingView'),
  onboardingNextButton('onboardingNextButton'),
  onboardingSkipButton('onboardingSkipButton'),
  onboardingFinishButton('onboardingFinishButton'),

  // ── Kimlik dogrulama ───────────────────────────────────────
  loginView('loginView'),
  loginSubmitButton('loginSubmitButton'),
  registerView('registerView'),
  registerSubmitButton('registerSubmitButton'),
  forgotPasswordView('forgotPasswordView'),
  emailVerificationView('emailVerificationView'),
  googleSignInButton('googleSignInButton'),
  appleSignInButton('appleSignInButton'),

  // ── Ana ekran ──────────────────────────────────────────────
  homeView('homeView'),
  homeSettingsButton('homeSettingsButton'),

  // ── Ayarlar ────────────────────────────────────────────────
  settingsView('settingsView'),
  settingsThemeTile('settingsThemeTile'),
  settingsLanguageTile('settingsLanguageTile'),
  settingsAboutTile('settingsAboutTile'),

  // ── Tema secimi ────────────────────────────────────────────
  themeSelectionView('themeSelectionView'),
  themeModeSelector('themeModeSelector'),
  themeCustomColorButton('themeCustomColorButton'),

  // ── Dil secimi ─────────────────────────────────────────────
  languageSelectionView('languageSelectionView'),

  // ── Ortak durum widget'lari ────────────────────────────────
  loadingIndicator('loadingIndicator'),
  errorView('errorView'),
  emptyView('emptyView'),
  retryButton('retryButton');

  const AppSemanticKeys(this.key);

  final String key;
}
