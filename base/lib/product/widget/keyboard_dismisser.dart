import 'package:flutter/material.dart';

/// Bos alana dokununca acik klavyeyi kapatir.
///
/// `HitTestBehavior.translucent` sayesinde dokunuslar alttaki widget'lara da
/// gecer — buton ve liste ogeleri calismaya devam eder.
///
/// `AppScaffold` bunu varsayilan olarak uygular; tum uygulamada gecerli olmasi
/// icin `MaterialApp.builder` icine de konabilir.
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
