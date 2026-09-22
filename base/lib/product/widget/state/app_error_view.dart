import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/utils/extension/context_extension.dart';
import 'package:akillisletme/product/widget/state/app_message_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Hata durumu — anlamli mesaj + yeniden dene.
///
/// [message] kullaniciya gosterilecek **yerellestirilmis** metindir; ham
/// exception metni gecilmez (`doc/guides/clean_code.md` → Hata yonetimi).
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, this.title, this.message, this.onRetry})
    : _isOffline = false;

  /// Internet baglantisi olmadiginda gosterilen hazir varyant.
  const AppErrorView.offline({super.key, this.onRetry})
    : title = null,
      message = null,
      _isOffline = true;

  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final bool _isOffline;

  @override
  Widget build(BuildContext context) {
    return AppMessageView(
      icon: _isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      iconColor: context.colorScheme.error,
      title:
          title ??
          (_isOffline
              ? LocaleKeys.state_offlineTitle.tr()
              : LocaleKeys.state_errorTitle.tr()),
      message:
          message ??
          (_isOffline
              ? LocaleKeys.state_offlineMessage.tr()
              : LocaleKeys.error_generic.tr()),
      actionLabel: onRetry == null ? null : LocaleKeys.general_retry.tr(),
      onAction: onRetry,
    );
  }
}
