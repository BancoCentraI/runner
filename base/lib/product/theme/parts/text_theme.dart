part of '../theme.dart';

const _fontDisplay = 'Poppins';
const _fontBody = 'Inter';

/// Uygulamanin tipografi temasi.
///
/// Varsayilan olarak Poppins (display/headline) + Inter (govde/etiket) ikilisini
/// kullanir. [fontFamily] verildiginde (or. hacker/terminal monospace) tum
/// stillerin font ailesi tek seferde override edilir; boylece tema spec'leri
/// kendi tipografisini saglayabilir.
TextTheme _buildTextTheme({String? fontFamily}) {
  if (fontFamily == null) return _baseTextTheme;
  return _baseTextTheme.apply(fontFamily: fontFamily);
}

const TextTheme _baseTextTheme = TextTheme(
  // ── Display ────────────────────────────────────────────────
  displayLarge: TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    height: 1.12, // 64 / 57
  ),
  displayMedium: TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.16, // 52 / 45
  ),
  displaySmall: TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.22, // 44 / 36
  ),

  // ── Headline ───────────────────────────────────────────────
  headlineLarge: TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.25, // 40 / 32
  ),
  headlineMedium: TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.29, // 36 / 28
  ),
  headlineSmall: TextStyle(
    fontFamily: _fontDisplay,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.33, // 32 / 24
  ),

  // ── Title ──────────────────────────────────────────────────
  titleLarge: TextStyle(
    fontFamily: _fontBody,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.27, // 28 / 22
  ),
  titleMedium: TextStyle(
    fontFamily: _fontBody,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5, // 24 / 16
  ),
  titleSmall: TextStyle(
    fontFamily: _fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43, // 20 / 14
  ),

  // ── Label ──────────────────────────────────────────────────
  labelLarge: TextStyle(
    fontFamily: _fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43, // 20 / 14
  ),
  labelMedium: TextStyle(
    fontFamily: _fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33, // 16 / 12
  ),
  labelSmall: TextStyle(
    fontFamily: _fontBody,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45, // 16 / 11
  ),

  // ── Body ───────────────────────────────────────────────────
  bodyLarge: TextStyle(
    fontFamily: _fontBody,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5, // 24 / 16
  ),
  bodyMedium: TextStyle(
    fontFamily: _fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43, // 20 / 14
  ),
  bodySmall: TextStyle(
    fontFamily: _fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33, // 16 / 12
  ),
);
