import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

/// Dilden bagimsiz auth hata kodlarini o anki dile cevrilmis kullanici metnine
/// esler.
///
/// Servis katmani ceviriden arinik kalir; tum metinler tek yerde toplanir ve
/// `assets/translations/*.json` uzerinden butun dillere yayilir.
abstract final class AuthErrorLocalizer {
  const AuthErrorLocalizer._();

  /// [code] → gosterilecek yerellestirilmis mesaj. Bilinmeyen kodlar
  /// `generic`e duser. `canceled` burada beklenmez — cubit onu sessizce yutar.
  static String message(String code) => switch (code) {
    'invalid-email' => LocaleKeys.auth_error_invalidEmail.tr(),
    'email-already-in-use' => LocaleKeys.auth_error_emailInUse.tr(),
    'weak-password' => LocaleKeys.auth_error_weakPassword.tr(),

    // Firebase, hesap taramasini (enumeration) engellemek icin "kullanici yok"
    // ve "sifre yanlis" hatalarini tek koda katlar. Bu yuzden mesaj birlesiktir.
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => LocaleKeys.auth_error_wrongCredential.tr(),

    'user-disabled' => LocaleKeys.auth_error_userDisabled.tr(),
    'too-many-requests' => LocaleKeys.auth_error_tooManyRequests.tr(),
    'network-request-failed' => LocaleKeys.auth_error_network.tr(),
    'account-exists-with-different-credential' =>
      LocaleKeys.auth_error_accountExists.tr(),

    // Hesap silme / e-posta degistirme gibi hassas islemler 5 dakikadan taze
    // giris ister.
    'requires-recent-login' => LocaleKeys.auth_error_recentLoginRequired.tr(),

    // Yeniden dogrulamada kullanici, hesabina bagli OLMAYAN bir Google/Apple
    // hesabi secti — jenerik mesaj nedeni gizlerdi.
    'user-mismatch' => LocaleKeys.auth_error_userMismatch.tr(),

    // Saglayici akisindan donen hatalar. Bunlari `invalid-credential` olarak
    // birakmak kullaniciya hic sifre girmedigi halde "sifre hatali" gosterirdi.
    'google' => LocaleKeys.auth_error_google.tr(),
    'apple' => LocaleKeys.auth_error_apple.tr(),

    _ => LocaleKeys.auth_error_generic.tr(),
  };
}
