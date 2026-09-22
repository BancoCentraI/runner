import 'package:flutter/services.dart';

/// Buton tiklama geri bildirimi — sistem sesi + haptic.
class ButtonFeedback {
  ButtonFeedback._();

  static void trigger() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }
}
