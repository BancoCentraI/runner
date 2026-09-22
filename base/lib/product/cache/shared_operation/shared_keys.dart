enum SharedKeys {
  firstAppOpen,
  theme,
  themeVariant,
  themeCustomSeed,
  themeSchemeVariant,
  themeContrast,
  themeUseSystemColors,
  currentVersion,
  onboardingCompleted,
  backgroundAnimation,

  /// Profil dokumaninin son yazilan halinin parmak izi — gereksiz
  /// Firestore okuma/yazmasini engeller.
  profileSync,

  /// Son bilinen premium durumu — cevrimdisi acilista dogru davranmak icin.
  premiumActive,
}
