import 'package:akillisletme/product/const/app_semantic_keys.dart';
import 'package:flutter/material.dart';

/// Widget'a UI testlerinin bulabilecegi sabit bir kimlik ekler.
///
/// `Semantics.identifier` erisilebilirlik agacina yazilir; ekran okuyucunun
/// sesli okudugu `label`'dan ayridir, bu yuzden kullanici deneyimini
/// degistirmez ve ceviriye tabi degildir.
///
/// ```dart
/// AppSemantics(
///   semanticKey: AppSemanticKeys.retryButton,
///   child: AppPrimaryButton(label: ..., onPressed: ...),
/// )
/// ```
///
/// Maestro tarafinda: `- tapOn: { id: "retryButton" }`
class AppSemantics extends StatelessWidget {
  const AppSemantics({
    required this.semanticKey,
    required this.child,
    super.key,
  });

  final AppSemanticKeys semanticKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(identifier: semanticKey.key, child: child);
  }
}
