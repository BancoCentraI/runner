import 'package:akillisletme/product/const/app_icon_sizes.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/utils/extension/context_extension.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:flutter/material.dart';

/// Ikon + baslik + aciklama + opsiyonel aksiyon duzeni.
///
/// `AppErrorView` ve `AppEmptyView` bunun uzerine kurulur; ikisinin de ayni
/// olculerde gorunmesini garanti eder. Dogrudan da kullanilabilir (orn. izin
/// verilmemis durumu).
class AppMessageView extends StatelessWidget {
  const AppMessageView({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Aksiyon butonu — [onAction] ile birlikte verilmelidir.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Varsayilan `onSurfaceVariant`; hata durumunda `error` gecilir.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final showAction = actionLabel != null && onAction != null;

    return Center(
      child: SingleChildScrollView(
        padding: AppPaddings.allXxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppPaddings.m,
          children: [
            Icon(
              icon,
              size: context.r(AppIconSizes.xxl),
              color: iconColor ?? context.colorScheme.onSurfaceVariant,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium,
            ),
            if (message != null)
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            if (showAction)
              Padding(
                padding: const EdgeInsets.only(top: AppPaddings.s),
                child: AppPrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  isExpanded: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
