// PLACEHOLDER — bu dosya `flutterfire configure` tarafindan UZERINE YAZILIR.
//
// Template'in Firebase paketleriyle birlikte derlenebilmesi icin buradadir.
// Gercek degerler yoktur; `AppConfig.firebaseEnabled` false oldugu surece
// hicbir zaman okunmaz.
//
// Kurulum:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Komut bu dosyayi gercek proje degerleriyle degistirir, ayrica
// `android/app/google-services.json` ve `ios/Runner/GoogleService-Info.plist`
// dosyalarini olusturur. Sonra `AppConfig.firebaseEnabled = true` yap.
//
// Tam akis: doc/guides/auth_setup.md

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// `flutterfire configure` calistirilinca bu sinif gercek platform
/// yapilandirmasiyla yeniden uretilir.
abstract final class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase yapilandirilmamis.\n'
      '\n'
      'lib/firebase_options.dart hala template placeholder dosyasi. Once:\n'
      '  1) dart pub global activate flutterfire_cli\n'
      '  2) flutterfire configure\n'
      '  3) AppConfig.firebaseEnabled = true\n'
      '\n'
      'Ayrinti: doc/guides/auth_setup.md',
    );
  }
}
