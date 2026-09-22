import 'dart:convert';
import 'dart:math';

import 'package:akillisletme/product/init/app_error_handler.dart';
import 'package:akillisletme/product/service/firebase/auth/auth_service.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// `firebase_auth` + `google_sign_in` (v7) + `sign_in_with_apple` kullanan
/// uretim implementasyonu.
///
/// Tum hatalar [AuthException]'a cevrilir — UI hicbir zaman Firebase tipi
/// gormez. Ham hata kodlari log'a gider, kullaniciya yerellestirilmis mesaj
/// cikar.
///
/// Ayrinti ve kurulum: `doc/guides/auth_setup.md`, `doc/guides/auth.md`
final class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required String googleServerClientId,
    FirebaseAuth? auth,
  }) : _googleServerClientId = googleServerClientId,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Firebase Console'daki **Web client ID**. Google'dan `idToken` alabilmek
  /// icin zorunludur; bos ise giris sessizce basarisiz olur.
  final String _googleServerClientId;

  bool _googleInitialized = false;

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_mapUser);

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  // ── E-posta / sifre ────────────────────────────────────────

  @override
  Future<void> signInWithEmail(String email, String password) {
    return _guard(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  @override
  Future<void> registerWithEmail(
    String email,
    String password, {
    String? name,
  }) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) return;

      if (name != null && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());
      }
      await user.sendEmailVerification();
    });
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  // ── Google ─────────────────────────────────────────────────

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      throw _mapGoogleException(error);
    } on FirebaseAuthException catch (error) {
      throw _mapProviderFirebaseException(error, 'google');
    }
  }

  /// Google v7: `authenticate()` cagrilmadan once bir kez `initialize()`
  /// **sart**. Bu cagri olmadan hicbir metot (signOut dahil) calismaz.
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleInitialized = true;
  }

  // ── Apple ──────────────────────────────────────────────────

  @override
  Future<void> signInWithApple() async {
    try {
      final (:credential, :apple) = await _appleCredential();
      final result = await _auth.signInWithCredential(credential);

      // Apple ad/e-postayi YALNIZ ilk yetkilendirmede dondurur — hemen yaz,
      // sonraki girislerde bir daha gelmez.
      final givenName = apple.givenName;
      if (givenName != null && (result.user?.displayName ?? '').isEmpty) {
        final familyName = apple.familyName ?? '';
        await result.user?.updateDisplayName('$givenName $familyName'.trim());
      }
    } on SignInWithAppleAuthorizationException catch (error) {
      throw _mapAppleException(error);
    } on FirebaseAuthException catch (error) {
      throw _mapProviderFirebaseException(error, 'apple');
    }
  }

  /// Apple girisinin ve yeniden dogrulamanin ortak kismi.
  ///
  /// Iki kritik nokta:
  ///
  /// 1. **Nonce** — rastgele deger uretilir, SHA-256'si Apple'a, **hami**
  ///    Firebase'e verilir. Replay saldirisini engeller.
  /// 2. **`accessToken: authorizationCode` SART** — `firebase_auth` 5.2.0'dan
  ///    itibaren Apple credential'i sunucu tarafinda authorization code ile de
  ///    dogrulaniyor. Gecilmezse token kusursuz olsa bile
  ///    "invalid-credential — Invalid OAuth response from apple.com" duser ve
  ///    hata mesaji tamamen yaniltici olur.
  ///    (flutterfire #13242, Apple DevForums thread 826547)
  ///
  /// Token'in KENDISI asla loglanmaz — kimlik bilgisidir.
  Future<({OAuthCredential credential, AuthorizationCredentialAppleID apple})>
  _appleCredential() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final identityToken = apple.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      // Ayri kod: aksi halde Firebase'in dondugu genel "invalid-credential"
      // yapilandirma hatasindan ayirt edilemiyor.
      throw const AuthException('apple');
    }

    final credential = OAuthProvider('apple.com').credential(
      idToken: identityToken,
      rawNonce: rawNonce,
      accessToken: apple.authorizationCode,
    );
    return (credential: credential, apple: apple);
  }

  /// Apple icin kriptografik olarak guvenli ham nonce.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // ── Yeniden dogrulama ──────────────────────────────────────

  @override
  Future<void> reauthenticateWithPassword(String password) {
    return _guard(() async {
      final user = _auth.currentUser;
      final email = user?.email;
      if (user == null || email == null) throw const AuthException('generic');

      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      // Token'i zorla yenile: hassas islemler 5 dakikadan taze `auth_time`
      // ister, yenilenmemis token eski girisin saatini tasir.
      await user.getIdToken(true);
    });
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      await _reauthenticate(credential);
    } on GoogleSignInException catch (error) {
      throw _mapGoogleException(error);
    } on FirebaseAuthException catch (error) {
      throw _mapProviderFirebaseException(error, 'google');
    }
  }

  @override
  Future<void> reauthenticateWithApple() async {
    try {
      final (:credential, apple: _) = await _appleCredential();
      await _reauthenticate(credential);
    } on SignInWithAppleAuthorizationException catch (error) {
      throw _mapAppleException(error);
    } on FirebaseAuthException catch (error) {
      throw _mapProviderFirebaseException(error, 'apple');
    }
  }

  Future<void> _reauthenticate(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('generic');
    await user.reauthenticateWithCredential(credential);
    await user.getIdToken(true);
  }

  // ── Profil ─────────────────────────────────────────────────

  @override
  Future<void> updateDisplayName(String name) {
    final user = _auth.currentUser;
    if (user == null) return Future<void>.value();
    return _guard(() => user.updateDisplayName(name.trim()));
  }

  @override
  Future<void> updatePhotoUrl(String? url) {
    final user = _auth.currentUser;
    if (user == null) return Future<void>.value();
    return _guard(() => user.updatePhotoURL(url));
  }

  @override
  Future<void> sendEmailVerification() {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return Future<void>.value();
    return _guard(user.sendEmailVerification);
  }

  @override
  Future<bool> reloadEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    // reload() sunucudan tazeler; sonra currentUser YENIDEN okunmalidir —
    // reload eski referansi guncellemez.
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ── Hesap ──────────────────────────────────────────────────

  @override
  Future<void> deleteAccount() {
    final user = _auth.currentUser;
    if (user == null) return Future<void>.value();
    return _guard(user.delete);
  }

  @override
  Future<void> signOut() async {
    // Google v7'de `initialize()` cagrilmadan hicbir metot kullanilamaz —
    // `signOut()` dahil. E-posta veya Apple ile girmis bir kullanicida bu akis
    // hic calismamis olur; sarmalanmazsa buradan firlayan hata
    // `_auth.signOut()`a hic gelinmemesine, yani kullanicinin CIKIS
    // YAPAMAMASINA yol acar. Firebase ayagi her kosulda calismali.
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } on Object catch (error) {
      AppErrorHandler.reportHandled(error);
    }
    await _auth.signOut();
  }

  // ── Hata esleme ────────────────────────────────────────────

  AuthException _mapGoogleException(GoogleSignInException error) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return const AuthException('canceled');
    }
    // Ham kodu logla: kullaniciya tek bir "google" mesaji gosteriyoruz ama
    // teshis icin gercek neden (clientId yok, URL scheme uyusmuyor, ag) sart.
    AppErrorHandler.reportHandled(
      StateError('google sign-in: ${error.code} ${error.description}'),
    );
    return const AuthException('google');
  }

  AuthException _mapAppleException(
    SignInWithAppleAuthorizationException error,
  ) {
    if (error.code == AuthorizationErrorCode.canceled) {
      return const AuthException('canceled');
    }
    AppErrorHandler.reportHandled(
      StateError('apple sign-in: ${error.code} ${error.message}'),
    );
    return const AuthException('apple');
  }

  /// Saglayici akisindan donen `invalid-credential`, "saglayici token'i
  /// reddedildi" demektir. Duz birakilirsa kullanici hic sifre girmedigi halde
  /// "E-posta veya sifre hatali" gorur. Diger kodlar (ör.
  /// `account-exists-with-different-credential`, `user-mismatch`) anlamlidir,
  /// oldugu gibi gecer.
  AuthException _mapProviderFirebaseException(
    FirebaseAuthException error,
    String providerCode,
  ) {
    AppErrorHandler.reportHandled(
      StateError('$providerCode firebase: ${error.code} ${error.message}'),
    );
    return AuthException(
      error.code == 'invalid-credential' ? providerCode : error.code,
    );
  }

  /// `FirebaseAuthException`'i dilden bagimsiz [AuthException] koduna cevirir.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.code);
    }
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      name: user.displayName,
      emailVerified: user.emailVerified,
      photoUrl: user.photoURL,
      // Ilk saglayici yeterli (cogu kullanicida tek):
      // password / google.com / apple.com
      providerId: user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : null,
    );
  }
}
