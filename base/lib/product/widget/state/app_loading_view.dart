import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/utils/extension/context_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Yukleme durumu — ortalanmis gostergeyle.
///
/// Icerigin sekli onceden biliniyorsa bunun yerine `AppShimmer` ile iskelet
/// placeholder tercih edilir; algilanan hiz belirgin sekilde artar.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message, this.showMessage = false});

  /// Gosterilecek metin. Verilmezse varsayilan "Yukleniyor..." kullanilir.
  final String? message;

  /// Kisa yuklemelerde metin gurultu yapar; varsayilan olarak gizlidir.
  final bool showMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPaddings.allXxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppPaddings.l,
          children: [
            const CircularProgressIndicator.adaptive(),
            if (showMessage)
              Text(
                message ?? LocaleKeys.state_loadingMessage.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
