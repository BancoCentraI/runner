import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/widget/state/app_message_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Bos durum — islem basarili ama gosterilecek veri yok.
///
/// Bos liste **hata degildir**: bu yuzden hata ikonu/rengi kullanilmaz ve
/// varsayilan olarak "yeniden dene" gosterilmez. Kullaniciyi ilerletecek bir
/// aksiyon varsa ([actionLabel] + [onAction]) onu gosterir.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String? title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppMessageView(
      icon: icon,
      title: title ?? LocaleKeys.state_emptyTitle.tr(),
      message: message ?? LocaleKeys.state_emptyMessage.tr(),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
