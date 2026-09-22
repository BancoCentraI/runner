import 'package:flutter/material.dart';

/// SnackBar ve BottomSheet icin BuildContext extension.
/// Tekrar eden boilerplate'i ortadan kaldirir.
///
/// Kullanim:
/// ```dart
/// context.showSuccessSnack('Kaydedildi');
/// context.showErrorSnack('Bir hata olustu');
/// context.showInfoSnack('Bilgi mesaji');
/// context.showConfirmDialog(title: 'Sil?', message: 'Emin misiniz?');
/// context.showAppBottomSheet(child: MyWidget());
/// ```
extension AppMessenger on BuildContext {
  // ── SnackBar ─────────────────────────────────────────────────

  void showSuccessSnack(String message) {
    _showSnack(
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: Theme.of(this).colorScheme.primary,
      foregroundColor: Theme.of(this).colorScheme.onPrimary,
    );
  }

  void showErrorSnack(String message) {
    _showSnack(
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: Theme.of(this).colorScheme.error,
      foregroundColor: Theme.of(this).colorScheme.onError,
    );
  }

  void showInfoSnack(String message) {
    _showSnack(
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: Theme.of(this).colorScheme.inverseSurface,
      foregroundColor: Theme.of(this).colorScheme.onInverseSurface,
    );
  }

  void _showSnack({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: foregroundColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: foregroundColor)),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ── Confirm Dialog ───────────────────────────────────────────

  /// Onay dialog'u. Kullanici onaylarsa `true`, iptal ederse `false` doner.
  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmLabel = 'Onayla',
    String cancelLabel = 'Iptal',
    bool isDestructive = false,
  }) async {
    final cs = Theme.of(this).colorScheme;
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: cs.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Bottom Sheet ─────────────────────────────────────────────

  /// Genel amacli bottom sheet. Icerige [child] widget'i verilir.
  Future<T?> showAppBottomSheet<T>({
    required Widget child,
    bool isDismissible = true,
    bool showDragHandle = true,
  }) {
    final cs = Theme.of(this).colorScheme;
    return showModalBottomSheet<T>(
      context: this,
      isDismissible: isDismissible,
      showDragHandle: showDragHandle,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(child: child),
    );
  }
}
