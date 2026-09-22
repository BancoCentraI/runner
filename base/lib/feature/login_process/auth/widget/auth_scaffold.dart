import 'package:akillisletme/product/const/app_icon_sizes.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/const/app_radius.dart';
import 'package:akillisletme/product/utils/extension/context_extension.dart';
import 'package:akillisletme/product/widget/keyboard_dismisser.dart';
import 'package:flutter/material.dart';

/// Auth ekranlarinin ortak kabugu: baslik + kaydirilabilir icerik.
///
/// Genis ekranda form kenardan kenara gerilmez, ortada sabit genislikte kalir
/// (uzun satir okunaksizdir). Klavye acilinca icerik kaydirilabilir olur.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
    this.icon,
    this.showBackButton = true,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final IconData? icon;
  final bool showBackButton;

  /// Genis ekranda formun ulasabilecegi azami genislik.
  static const double _maxFormWidth = 420;

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: showBackButton,
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: AppPaddings.allXl,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxFormWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppPaddings.l,
                  children: [
                    _AuthHeader(title: title, subtitle: subtitle, icon: icon),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.subtitle, this.icon});

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Column(
      spacing: AppPaddings.s,
      children: [
        if (icon != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: AppRadius.allXl,
            ),
            child: Padding(
              padding: AppPaddings.allL,
              child: Icon(
                icon,
                size: AppIconSizes.l,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.textTheme.headlineSmall,
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// "veya" ayirici — sosyal giris blogunu e-posta formundan ayirir.
class AuthDivider extends StatelessWidget {
  const AuthDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Row(
      spacing: AppPaddings.m,
      children: [
        Expanded(child: Divider(color: cs.outlineVariant)),
        Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }
}

/// Ekranin altindaki "Hesabin yok mu? Kayit ol" satiri.
class AuthFooterAction extends StatelessWidget {
  const AuthFooterAction({
    required this.question,
    required this.actionLabel,
    required this.onPressed,
    super.key,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}
