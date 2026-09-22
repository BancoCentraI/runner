import 'package:akillisletme/product/utils/button_feedback.dart';
import 'package:flutter/material.dart';

/// Ikincil aksiyon butonu — OutlinedButton tabanli.
/// "Geri don, tut, iptal" gibi ikincil aksiyonlar icin.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.isExpanded = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;

  VoidCallback? get _wrappedOnPressed => onPressed != null
      ? () {
          ButtonFeedback.trigger();
          onPressed!();
        }
      : null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final button = icon != null
        ? OutlinedButton.icon(
            onPressed: _wrappedOnPressed,
            icon: Icon(icon, size: 20),
            label: _label(context),
            style: _style(cs),
          )
        : OutlinedButton(
            onPressed: _wrappedOnPressed,
            style: _style(cs),
            child: _label(context),
          );

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _label(BuildContext context) {
    return Text(label);
  }

  ButtonStyle _style(ColorScheme cs) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(color: cs.primary),
    );
  }
}
