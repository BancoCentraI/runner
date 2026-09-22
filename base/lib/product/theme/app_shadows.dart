import 'package:flutter/material.dart';

/// Tema duyarli golge token'lari.
///
/// Golge rengi `colorScheme.shadow`'dan gelir; dark mod'da ayni alpha degeri
/// koyu zeminde gorunmedigi icin opaklik otomatik artirilir. Bu yuzden
/// token'lar sabit liste degil, `context` alan fonksiyonlardir.
///
/// ```dart
/// DecoratedBox(
///   decoration: BoxDecoration(
///     borderRadius: AppRadius.card,
///     boxShadow: AppShadows.card(context),
///   ),
/// )
/// ```
@immutable
final class AppShadows {
  const AppShadows._();

  /// Kart, liste ogesi — zeminden hafifce ayrilir.
  static List<BoxShadow> card(BuildContext context) =>
      _elevation(context, alpha: 0.06, blur: 8, dy: 2);

  /// Yukseltilmis yuzey — one cikan kart, secili oge.
  static List<BoxShadow> raised(BuildContext context) =>
      _elevation(context, alpha: 0.10, blur: 20, dy: 8);

  /// Hero / kapak gorseli — en belirgin katman.
  static List<BoxShadow> hero(BuildContext context) =>
      _elevation(context, alpha: 0.14, blur: 32, dy: 14);

  /// Alt bar — golge yukari dogru duser.
  static List<BoxShadow> bottomBar(BuildContext context) =>
      _elevation(context, alpha: 0.08, blur: 18, dy: -4);

  /// Popup, menu, tooltip.
  static List<BoxShadow> popover(BuildContext context) =>
      _elevation(context, alpha: 0.16, blur: 24, dy: 10);

  static List<BoxShadow> _elevation(
    BuildContext context, {
    required double alpha,
    required double blur,
    required double dy,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return [
      BoxShadow(
        color: theme.colorScheme.shadow.withValues(
          alpha: isDark ? alpha * 2.2 : alpha,
        ),
        blurRadius: blur,
        offset: Offset(0, dy),
      ),
    ];
  }
}
