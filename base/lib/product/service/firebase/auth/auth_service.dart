/// Kimlik dogrulama hatasi.
///
/// UI'ye Firebase tipini sizdirmaz, yalnizca **dilden bagimsiz** bir [code]
/// tasir. Kullaniciya gosterilecek metin `AuthErrorLocalizer` tarafindan bu
/// koddan uretilir; boylece servis katmani ceviriden arinik kalir.
class AuthException implements Exception {
  const AuthException(this.code);

  /// Firebase hata kodu (`invalid-email`, `weak-password`...) ya da bizim
  /// urettigimiz kodlar (`google`, `apple`, `canceled`, `generic`).
  final String code;

  /// Kullanici akisi yarida birakti. **Hata degildir** — ne hata ne basari
  /// mesaji gosterilir.
  bool get isCanceled => code == 'canceled';

  @override
  String toString() => 'AuthException($code)';
}

/// UI'nin gordugu sade kullanici modeli — Firebase `User` tipini sizdirmaz.
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.name,
    this.emailVerified = false,
    this.photoUrl,
    this.providerId,
  });

  final String uid;
  final String? email;
  final String? name;
  final bool emailVerified;

  /// Profil fotografinin indirme URL'i. Google ile girenlerde Google avatari
  /// gelebilir; kullanici kendi fotografini yukleyince uzerine yazilir.
  final String? photoUrl;

  /// Giris saglayicisi (`password`, `google.com`, `apple.com`). Hesap silme
  /// akisi buna bakar: e-posta kullanicisindan sifre istenir, saglayici
  /// kullanicisi kendi sayfasinda yeniden dogrular.
  final String? providerId;
}

/// Kimlik dogrulamanin sozlesmesi.
///
/// `AuthCubit` ve ekranlar **yalnizca** bu soyutlamaya baglanir. Uretimde
/// `FirebaseAuthService`, Firebase kurulmadan once ve testlerde
/// `MockAuthService` baglanir — arayuz ikisini ayirt etmez.
///
/// Ayrinti: `doc/guides/auth.md`
abstract interface class AuthService {
  /// Oturum degisimlerini yayinlar — **tek dogru kaynak**.
  ///
  /// Giris/cikis nerede olursa olsun (baska ekran, token suresi dolmasi,
  /// hesabin devre disi birakilmasi) durum buradan akar.
  Stream<AppUser?> authStateChanges();

  /// Su anki oturum (yoksa `null`).
  AppUser? get currentUser;

  Future<void> signInWithEmail(String email, String password);

  /// Kayit; [name] verilirse profile yazilir ve dogrulama e-postasi gonderilir.
  Future<void> registerWithEmail(String email, String password, {String? name});

  Future<void> sendPasswordReset(String email);

  /// Google ile giris. Iptalde `AuthException('canceled')`.
  Future<void> signInWithGoogle();

  /// Apple ile giris (nonce'lu guvenli akis). Iptalde `AuthException('canceled')`.
  Future<void> signInWithApple();

  /// Gorunen adi gunceller. Oturum yoksa sessizce doner.
  Future<void> updateDisplayName(String name);

  /// Profil fotografi URL'ini yazar. `null` fotografi kaldirir.
  Future<void> updatePhotoUrl(String? url);

  /// E-posta dogrulama baglantisi gonderir. Oturum yoksa ya da e-posta zaten
  /// dogrulanmissa sessizce doner.
  Future<void> sendEmailVerification();

  /// Kullaniciyi sunucudan tazeler ve guncel dogrulama durumunu dondurur.
  ///
  /// `emailVerified` degisimi [authStateChanges]'i **TETIKLEMEZ** — kullanici
  /// baglantiya uygulama disinda tiklar. Bu yuzden elle sorulmasi gerekir.
  Future<bool> reloadEmailVerified();

  /// Kimligi yeniden kanitlar (e-posta saglayicisi). Hesap silme oncesi
  /// zorunludur: Firebase 5 dakikadan taze giris ister
  /// (`requires-recent-login`).
  Future<void> reauthenticateWithPassword(String password);

  /// Yeniden dogrulama — Google saglayicisi.
  Future<void> reauthenticateWithGoogle();

  /// Yeniden dogrulama — Apple saglayicisi.
  Future<void> reauthenticateWithApple();

  /// Hesabi kalici olarak siler.
  ///
  /// **Magaza sarti:** hesap olusturmaya izin veren uygulama hesap silmeyi de
  /// sunmak zorundadir (App Store 5.1.1(v), Google Play). Cagirmadan once
  /// yeniden dogrulama yapilmalidir.
  Future<void> deleteAccount();

  Future<void> signOut();
}
