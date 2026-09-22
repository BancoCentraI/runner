import 'package:akillisletme/product/utils/button_feedback.dart';
import 'package:flutter/material.dart';

/// Ana aksiyon butonu — FilledButton tabanli.
/// "Basla, at, devam et, guncelle" gibi birincil aksiyonlar icin.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
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
    final button = icon != null
        ? FilledButton.icon(
            onPressed: _wrappedOnPressed,
            icon: Icon(icon, size: 20),
            label: _label(context),
            style: _style(),
          )
        : FilledButton(
            onPressed: _wrappedOnPressed,
            style: _style(),
            child: _label(context),
          );

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _label(BuildContext context) {
    return Text(label);
  }

  ButtonStyle _style() {
    return FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
