import 'package:akillisletme/product/theme/state/theme_state.dart';
import 'package:akillisletme/product/theme/theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget testleri icin ortak kurulum.
///
/// EasyLocalization'in **widget**'i bilerek kullanilmaz: `Localizations`
/// delegeleri cozulene kadar alt agaci cizmez ve ayni dosyadaki ikinci testte
/// yukleme tamamlanmadigi icin agac bos kalir. Bunun yerine yalnizca depolama
/// katmani baslatilir; bu durumda `LocaleKeys.x.tr()` cevirinin **anahtar
/// yolunu** dondurur (`'validation.required'` gibi) ve hicbir sey patlamaz.
///
/// Sonuc olarak widget testleri **cevrilmis metne degil, davranisa ve widget
/// tipine** bakar — ceviri metni degistiginde testler kirilmaz.
///
/// ```dart
/// void main() {
///   setUpAll(initializeTestBindings);
///
///   testWidgets('...', (tester) async {
///     await tester.pumpApp(const MyWidget());
///     expect(find.byType(MyWidget), findsOneWidget);
///   });
/// }
/// ```
Future<void> initializeTestBindings() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // EasyLocalization ve SharedCache secili dili/temayi burada tutar.
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
}

extension PumpApp on WidgetTester {
  /// [child]'i uygulamanin gercek temasiyla bir `Scaffold` icinde cizer.
  ///
  /// [themeState] ile farkli varyant/mod kombinasyonlari denenebilir; boylece
  /// bir widget'in hem light hem dark'ta okunur oldugu test edilebilir.
  Future<void> pumpApp(
    Widget child, {
    ThemeState themeState = const ThemeState(),
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(themeState),
        darkTheme: AppTheme.darkTheme(themeState),
        themeMode: themeMode,
        home: Scaffold(body: child),
      ),
    );
    await pump();
  }
}
