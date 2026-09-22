import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/widget/keyboard_dismisser.dart';
import 'package:flutter/material.dart';

/// Sayfa iskeleti — standart padding, SafeArea ve klavye kapatma davranisini
/// tek yerde toplar.
///
/// `Scaffold`'dan turetmek yerine onu sarmalar: boylece ic yerlesim degisince
/// (orn. padding kurali) tum sayfalar tek dosyadan guncellenir ve `Scaffold`'un
/// kendi API'siyle catisilmaz.
///
/// Kendi padding'ini yoneten tam ekran icerik (harita, `CustomScrollView`,
/// kenardan kenara gorsel) icin `padding: EdgeInsets.zero` gec.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.padding = AppPaddings.page,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.dismissKeyboardOnTap = true,
    this.useSafeArea = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final EdgeInsetsGeometry padding;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;

  /// Bos alana dokununca klavyeyi kapat. Form ekranlarinda beklenen davranis.
  final bool dismissKeyboardOnTap;

  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: body);

    if (useSafeArea) {
      // AppBar zaten ust centigi yonetir; ikinci kez bosluk birakma.
      content = SafeArea(top: appBar == null, child: content);
    }

    if (dismissKeyboardOnTap) {
      content = KeyboardDismisser(child: content);
    }

    return Scaffold(
      appBar: appBar,
      body: content,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
