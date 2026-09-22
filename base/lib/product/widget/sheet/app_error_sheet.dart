import 'package:akillisletme/product/const/app_icon_sizes.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/utils/app_messenger.dart';
import 'package:akillisletme/product/utils/extension/context_extension.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:akillisletme/product/widget/app_secondary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Bloke edici hatalarda (acilis kontrolu, zorunlu yukleme) gosterilen sheet.
///
/// Kullanici "tekrar dene" derse `true`, kapatirsa `false`/`null` doner:
///
/// ```dart
/// final shouldRetry = await AppErrorSheet.show(context) ?? false;
/// if (shouldRetry) await cubit.retry();
/// ```
///
/// Ekran icindeki (bloke etmeyen) hatalar icin `AppErrorView` kullanilir.
class AppErrorSheet extends StatelessWidget {
  const AppErrorSheet({
    super.key,
    this.title,
    this.message,
    this.isOffline = false,
  });

  final String? title;
  final String? message;

  /// Baglanti hatasi varyanti — ikon ve metinler ona gore secilir.
  final bool isOffline;

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
    bool isOffline = false,
  }) {
    return context.showAppBottomSheet<bool>(
      isDismissible: false,
      child: AppErrorSheet(
        title: title,
        message: message,
        isOffline: isOffline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Padding(
      padding: AppPaddings.allXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppPaddings.m,
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            size: AppIconSizes.xl,
            color: cs.error,
          ),
          Text(
            title ??
                (isOffline
                    ? LocaleKeys.state_offlineTitle.tr()
                    : LocaleKeys.state_errorTitle.tr()),
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium,
          ),
          Text(
            message ??
                (isOffline
                    ? LocaleKeys.state_offlineMessage.tr()
                    : LocaleKeys.error_generic.tr()),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          AppPrimaryButton(
            label: LocaleKeys.general_retry.tr(),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          AppSecondaryButton(
            label: LocaleKeys.general_close.tr(),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
