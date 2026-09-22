import 'package:flutter/widgets.dart';

/// Animasyon ve gecikme sureleri.
/// Ham `Duration(milliseconds: ...)` yerine bunlar kullanilir; boylece
/// uygulamanin animasyon ritmi tek yerden ayarlanir.
@immutable
final class AppDurations {
  const AppDurations._();

  /// Anlik geri bildirim — renk/opaklik gecisleri.
  static const Duration instant = Duration(milliseconds: 120);

  /// Varsayilan UI gecisi — buton, kart, expand/collapse.
  static const Duration short = Duration(milliseconds: 220);

  /// Sayfa gecisi ve daha belirgin hareketler.
  static const Duration medium = Duration(milliseconds: 350);

  /// Vurgulu giris animasyonlari, onboarding adimlari.
  static const Duration long = Duration(milliseconds: 600);

  /// SnackBar gorunme suresi — `AppMessenger` bunu kullanir.
  static const Duration snackBar = Duration(seconds: 3);

  /// Arama alaninda tuslama sonrasi bekleme (debounce).
  static const Duration debounce = Duration(milliseconds: 400);

  /// Ag cagrilari icin varsayilan zaman asimi.
  static const Duration networkTimeout = Duration(seconds: 15);
}
