# Flutter + Firebase Auth Rehberi — E-posta, Google ve Apple ile Giriş

> Gerçek bir üretim uygulamasında yaşanmış sorunlardan damıtılmış, uçtan uca
> doğrulanmış bir kimlik doğrulama rehberi. Üç yöntemi kapsar: **e-posta/şifre**,
> **Google ile giriş** (`google_sign_in` v7) ve **Apple ile giriş**
> (`sign_in_with_apple`). Sadece "nasıl yapılır" değil; **nerede patlar, hata
> mesajları neden yanıltıcıdır ve nasıl teşhis edilir** de anlatılır.
>
> Kod örnekleri Dart/Flutter'dır; tüm kimlikler (`com.example.app`,
> `YOUR_WEB_CLIENT_ID` vb.) yer tutucudur — kendi değerlerinizle değiştirin.

---

## İçindekiler

1. [Paketler ve sürüm tuzağı](#1-paketler)
2. [Mimari: UI'yi Firebase'den yalıtın](#2-mimari)
3. [Firebase proje kurulumu](#3-kurulum)
4. [E-posta + şifre](#4-e-posta--şifre)
5. [Google ile giriş — v7'nin kırıcı değişiklikleri](#5-google-ile-giriş)
6. [Apple ile giriş — ve meşhur "Invalid OAuth response" hatası](#6-apple-ile-giriş)
7. [Hata yönetimi: kod-tabanlı, tek yerde çeviri](#7-hata-yönetimi)
8. [Çıkış (signOut) — az bilinen bir tuzak](#8-çıkış)
9. [Rota koruması (auth-gating)](#9-rota-koruması)
10. [Kritik tuzaklar — özet tablo](#10-kritik-tuzaklar)
11. [Teşhis rehberi: "giriş çalışmıyor" dediğinizde](#11-teşhis-rehberi)

---

## 1. Paketler

```yaml
dependencies:
  firebase_core: ^4.0.0
  firebase_auth: ^6.0.0
  google_sign_in: ^7.0.0     # v7 KIRICI sürümdür — bkz. §5
  sign_in_with_apple: ^7.0.0
  crypto: ^3.0.0             # Apple nonce SHA-256 için
```

**Sürüm uyarıları:**

- **`google_sign_in` v7**, v6'dan tamamen farklı bir API'dir. `signIn()`
  kaldırıldı; internetteki eski örnekler çalışmaz (§5).
- **`firebase_auth` 5.2.0 ve sonrası**, Apple girişinde ek bir parametreyi
  fiilen zorunlu kılar; eklemezseniz yanıltıcı bir hatayla karşılaşırsınız (§6).
- FlutterFire paketleri **toplu (batch) yayınlanır** ve bir batch'teki tek bir
  paketin eksik/bozuk yayını tüm zinciri kırabilir. Çözümleme hatası alırsanız
  körlemesine `pub upgrade` yapmayın; çalışan sürümleri aralıkla
  (`">=x.y.z <x.y+1.0"`) pinlemek meşru bir stratejidir.

---

## 2. Mimari

Temel ilke: **UI ve state katmanı Firebase tiplerini hiç görmez.** Araya bir
soyutlama koyun:

```
Ekranlar (login/register/forgot)
      │  yalnız cubit'i çağırır
AuthCubit ◄── authStateChanges() stream   ← oturumun TEK doğru kaynağı
      │  yalnız interface'i görür
AuthService (abstract interface)
      │
FirebaseAuthService (implements) → firebase_auth + google_sign_in + sign_in_with_apple
```

Bunun üç somut getirisi var:

1. **Test edilebilirlik** — cubit ve ekranlar sahte bir `AuthService` ile test
   edilir; Firebase emülatörü gerekmez.
2. **Hata sözleşmesi** — servis dışarıya yalnız dilden bağımsız bir kod taşıyan
   kendi exception'ınızı fırlatır (§7). UI, `FirebaseAuthException`'ı tanımaz.
3. **Değiştirilebilirlik** — backend değişse (ör. başka bir kimlik sağlayıcı)
   ekranlara dokunulmaz.

### Sözleşme

```dart
/// UI'nin gördüğü sade kullanıcı modeli — Firebase `User` tipini sızdırmaz.
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.name,
    this.emailVerified = false,
    this.photoUrl,
  });
  final String uid;
  final String? email;
  final String? name;
  final bool emailVerified;
  final String? photoUrl;
}

abstract interface class AuthService {
  /// Oturum değişimlerini (giriş/çıkış) yayınlar — tek doğru kaynak.
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;

  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail(String email, String password, {String? name});
  Future<void> sendPasswordReset(String email);
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
}
```

### State: stream'e bağlanın, elle emit etmeyin

Giriş/çıkış **nerede** olursa olsun (başka ekran, token süresi dolması, hesap
devre dışı bırakılması) durum stream'den akar. Aksiyon metotları emit yapmaz;
sadece servisi çağırır ve **sonucu** döndürür:

```dart
/// Bir auth aksiyonunun sonucu. İptal ile başarı AYRI tutulur — yoksa
/// kullanıcının yarıda bıraktığı bir Google/Apple akışı "giriş başarılı"
/// bildirimi gösterir (gerçek ve sinir bozucu bir bug).
sealed class AuthActionResult {}
class AuthActionSuccess extends AuthActionResult {}
class AuthActionCanceled extends AuthActionResult {}
class AuthActionFailure extends AuthActionResult {
  AuthActionFailure(this.message);
  final String message; // yerelleştirilmiş, gösterime hazır
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._auth) : super(AuthState.fromUser(_auth.currentUser)) {
    _sub = _auth.authStateChanges().listen((u) => emit(AuthState.fromUser(u)));
  }

  final AuthService _auth;
  late final StreamSubscription<AppUser?> _sub;

  Future<AuthActionResult> signInWithApple() => _run(_auth.signInWithApple);

  Future<AuthActionResult> _run(Future<void> Function() action) async {
    try {
      await action();
      return AuthActionSuccess();
    } on AuthException catch (e) {
      if (e.isCanceled) return AuthActionCanceled();
      return AuthActionFailure(AuthErrorLocalizer.message(e.code));
    } on Object {
      return AuthActionFailure(AuthErrorLocalizer.message('generic'));
    }
  }

  @override
  Future<void> close() { _sub.cancel(); return super.close(); }
}
```

> ⚠️ **BlocProvider lazy tuzağı:** `BlocProvider` varsayılan olarak lazy'dir —
> cubit, ilk ekran onu okuyana kadar **hiç yaratılmaz**. Oturum dinleyiciniz
> açılışta yan etki yapıyorsa (analytics kullanıcı kimliği, profil yazımı, FCM
> token kaydı) `lazy: false` verin; yoksa kullanıcı giriş ekranına uğramadıkça
> hiçbiri çalışmaz ve bunu fark etmeniz haftalar alabilir.

---

## 3. Kurulum

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Bu komut `lib/firebase_options.dart`'ı üretir ve platform dosyalarını
(`google-services.json`, `GoogleService-Info.plist`) bağlar. Sonra:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Console → Authentication → Sign-in method'dan Email/Password, Google ve
Apple sağlayıcılarını açın.

> ⚠️ **Çift app kaydı tuzağı:** Projede aynı platform için birden fazla app
> kaydı varsa (ör. bundle id değişimi sonrası eskisi silinmemişse),
> `firebase.json`'ın **hangi appId'yi** gösterdiğini kontrol edin. Yanlış app'i
> gösteriyorsa bir sonraki `flutterfire configure` çalıştırışınız plist/json
> dosyalarını **yanlış app'in** değerleriyle sessizce ezer ve Google girişi
> anlaşılmaz biçimde kırılır. Kullanılmayan app kayıtlarını Console'dan silin.

---

## 4. E-posta + şifre

En dertsiz yöntem. Servis implementasyonu:

```dart
final _fb = FirebaseAuth.instance;

Future<void> signInWithEmail(String email, String password) =>
    _guard(() => _fb.signInWithEmailAndPassword(
        email: email.trim(), password: password));

Future<void> registerWithEmail(String email, String password, {String? name}) {
  return _guard(() async {
    final cred = await _fb.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = cred.user;
    if (user == null) return;
    if (name != null && name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
    }
    await user.sendEmailVerification();
  });
}

Future<void> sendPasswordReset(String email) =>
    _guard(() => _fb.sendPasswordResetEmail(email: email.trim()));

/// FirebaseAuthException → dilden bağımsız kod (§7).
Future<T> _guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on FirebaseAuthException catch (e) {
    throw AuthException(e.code);
  }
}
```

**Bilinmesi gerekenler:**

- Firebase, hesap taramasını (enumeration) engellemek için "kullanıcı yok" ve
  "şifre yanlış" hatalarını çoğunlukla tek bir `invalid-credential` koduna
  katlar. "E-posta veya şifre hatalı" gibi birleşik bir mesaj gösterin.
- **Sosyal girişle açılmış hesabın şifresi yoktur.** Kullanıcı hesabını Google
  ile oluşturduysa, "doğru şifre" girdiğini düşünse bile e-posta/şifre girişi
  `invalid-credential` alır — bir bug değildir. Destek taleplerinde ilk
  bakılacak şey, hesabın `providerData`'sında hangi sağlayıcıların olduğudur.

---

## 5. Google ile giriş

### v7'nin kırıcı değişiklikleri

| v6 (eski) | v7 (yeni) |
|---|---|
| `GoogleSignIn()` ile örnek oluştur | `GoogleSignIn.instance` singleton |
| doğrudan `signIn()` | önce **bir kez** `initialize()`, sonra `authenticate()` |
| iptalde `null` döner | iptalde `GoogleSignInException(code: canceled)` fırlar |
| auth + authz iç içe | kimlik (authentication) ile yetki/scope (authorization) ayrıldı |

```dart
final class FirebaseAuthService implements AuthService {
  FirebaseAuthService({required String googleServerClientId})
      : _googleServerClientId = googleServerClientId;

  final String _googleServerClientId;
  bool _googleInitialized = false;

  /// v7: `authenticate()` çağrılmadan önce bir kez `initialize()` ŞART.
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId, // Firebase Web client ID
    );
    _googleInitialized = true;
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('canceled');
      }
      // Ham kodu logla (§11) — kullanıcıya genel mesaj, log'a gerçek neden.
      log('google sign-in failed: ${e.code} ${e.description}');
      throw const AuthException('google');
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code == 'invalid-credential' ? 'google' : e.code);
    }
  }
}
```

### Platform yapılandırması

**Android:**
- Debug **ve** release imza anahtarlarının SHA-1/SHA-256 parmak izlerini
  Firebase'deki Android app'e ekleyin (`keytool -list -v -keystore ...`).
  Play App Signing kullanıyorsanız Play Console'daki imza sertifikasının
  SHA'ları da gerekir.
- SHA ekledikten sonra **`google-services.json`'ı yeniden indirin** — eski
  dosya yeni OAuth client'ı içermez.
- `serverClientId` = Console'da Google sağlayıcısını açınca oluşan **Web
  client ID** (`...apps.googleusercontent.com`). `idToken` alabilmek için
  gereklidir.

**iOS:**
- Eklenti `CLIENT_ID`'yi `GoogleService-Info.plist`'ten okur.
- `Info.plist` → `CFBundleURLTypes`'a plist'teki `REVERSED_CLIENT_ID` değerini
  URL scheme olarak ekleyin.

> ⚠️ **Sessiz kırılma:** `flutterfire configure` yeniden çalıştırılıp
> `GoogleService-Info.plist` yenilendiğinde `Info.plist`'teki URL scheme
> **otomatik güncellenmez**. İki değer ayrışırsa Google girişi hiçbir anlamlı
> hata vermeden kırılır. Plist her yenilendiğinde URL scheme'i elle doğrulayın.

---

## 6. Apple ile giriş

Apple'ın kuralı: uygulamanızda üçüncü taraf giriş (Google dahil) varsa
**Apple ile girişi de sunmak zorundasınız** (App Store İnceleme 4.8).

### Platform yapılandırması

1. Apple Developer → App ID'de "Sign in with Apple" yeteneğini açın.
2. Xcode → Runner target → Signing & Capabilities → **+ Sign in with Apple**
   (entitlements dosyasına `com.apple.developer.applesignin` ekler).
3. Firebase Console → Authentication → Apple sağlayıcısını açın.
   **Services ID alanını yalnız native iOS girişi için BOŞ bırakın** — o alan
   web/Android akışı içindir. Native akışta doldurmak doğrulamayı bozabilir.

### Güvenli akış: nonce + accessToken

İki kritik parça var. Birincisi bilinen **nonce** akışı: rastgele bir değer
üretir, **SHA-256'sını Apple'a**, **hamını Firebase'e** verirsiniz; replay
saldırısını engeller. İkincisi az bilinen ve bu rehberin yazılma sebebi olan
**`accessToken`** parametresi:

```dart
@override
Future<void> signInWithApple() async {
  try {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce, // HASH Apple'a gider
    );

    final identityToken = apple.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw const AuthException('apple');
    }

    final credential = OAuthProvider('apple.com').credential(
      idToken: identityToken,
      rawNonce: rawNonce,                    // HAM nonce Firebase'e gider
      accessToken: apple.authorizationCode,  // ⚠️ ŞART — aşağıyı okuyun
    );
    final result = await _auth.signInWithCredential(credential);

    // Apple ad/e-postayı YALNIZ İLK yetkilendirmede döndürür — hemen kaydet.
    final givenName = apple.givenName;
    if (givenName != null && (result.user?.displayName ?? '').isEmpty) {
      final family = apple.familyName ?? '';
      await result.user?.updateDisplayName('$givenName $family'.trim());
    }
  } on SignInWithAppleAuthorizationException catch (e) {
    if (e.code == AuthorizationErrorCode.canceled) {
      throw const AuthException('canceled');
    }
    log('apple sign-in failed: ${e.code} ${e.message}');
    throw const AuthException('apple');
  } on FirebaseAuthException catch (e) {
    log('apple firebase rejection: ${e.code} ${e.message}');
    throw AuthException(e.code == 'invalid-credential' ? 'apple' : e.code);
  }
}

String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}
```

### 🔥 "Invalid OAuth response from apple.com" — en yanıltıcı hata

```
[firebase_auth/invalid-credential] Invalid OAuth response from apple.com
```

Bu hatayı alırsanız içgüdünüz "Apple'dan bozuk yanıt gelmiş" veya "yapılandırmam
yanlış" olur. **İkisi de büyük olasılıkla yanlıştır.** Gerçek vaka kaydı:

- Apple akışı kusursuz tamamlanıyordu; `identityToken` doluydu (~920 bayt).
- Token elle çözüldü: `iss`, `aud`, `exp` doğru; `nonce` claim'i gönderilen
  hash'le birebir aynı.
- Token'ın RSA imzası, Apple'ın açık anahtarlarına
  (`https://appleid.apple.com/auth/keys`) karşı **elle doğrulandı: GEÇERLİ.**
- Yani Apple'ın yanıtında hiçbir sorun yoktu. Buna rağmen Firebase reddediyordu.

**Neden:** `firebase_auth` 5.2.0'dan itibaren Apple credential'ı sunucu tarafında
`authorizationCode` ile de doğrulanıyor. `credential(...)` çağrısına
`accessToken: apple.authorizationCode` geçilmezse doğrulama, token ne kadar
kusursuz olursa olsun bu mesajla düşer. Tek satırlık eksik, saatlerce süren
yanlış yönlendirilmiş teşhis. (Kayıtlar: flutterfire issue #13242; Apple
Developer Forums thread 826547 — hata gerçek cihazlarda da oluşur,
simülatöre özgü değildir.)

### Apple'a özgü diğer tuzaklar

- **Ad/e-posta yalnız ilk sefer gelir.** Sonraki girişlerde `givenName`/`email`
  `null`'dur. İlk yetkilendirmede profile yazmazsanız bir daha alamazsınız.
  (Test ederken sıfırlamak için: iCloud ayarları → Apple Account → Sign in with
  Apple → uygulamanızı silin; bir sonraki giriş yine "ilk giriş" olur.)
- **"E-postamı Gizle"** seçen kullanıcının adresi `...@privaterelay.appleid.com`
  olur. E-postayı iletişim için kullanıyorsanız relay adreslerine mail
  atabilmek için Apple Developer'da domain/adres doğrulaması gerekir.
- **Simülatörde test:** simülatöre Ayarlar'dan bir Apple hesabıyla **tam**
  (iki adımlı doğrulama dahil) giriş yapılmış olmalı. Yarıda bırakılmış bir
  hesap oturumu, giriş sayfası hiç açılmadan anında hata dönmesine yol açar.
  Şüphede kalırsanız: Device → Erase All Content and Settings → Ayarlar'dan
  temiz giriş → tekrar deneyin. Kesin doğrulama her zaman gerçek cihazdır.

---

## 7. Hata yönetimi

İlke: **servis katmanı kullanıcı metni üretmez.** Yalnız dilden bağımsız bir
kod taşır; metin tek bir yerde, o anki dile çevrilir:

```dart
class AuthException implements Exception {
  const AuthException(this.code);
  final String code; // Firebase kodu, ya da 'google'/'apple'/'canceled'
  bool get isCanceled => code == 'canceled';
}
```

Kod → mesaj eşlemesi tek dosyada (yerelleştirme anahtarlarıyla):

| Kod | Kullanıcıya |
|---|---|
| `invalid-credential`, `wrong-password` | E-posta veya şifre hatalı |
| `email-already-in-use` | Bu e-posta zaten kayıtlı |
| `weak-password` | Şifre çok zayıf |
| `user-disabled` | Hesap devre dışı |
| `too-many-requests` | Çok fazla deneme — sonra tekrar deneyin |
| `network-request-failed` | Ağ hatası |
| `account-exists-with-different-credential` | Bu e-posta başka bir yöntemle kayıtlı |
| `google` / `apple` | Google/Apple girişi tamamlanamadı |
| diğer her şey | Genel hata mesajı |

İki önemli kural:

1. **`canceled` bir hata değildir.** Kullanıcı sağlayıcı sayfasını kapattıysa
   ne hata ne başarı gösterin — sessiz kalın.
2. **Sağlayıcı akışında `invalid-credential`'ı "şifre hatalı"ya çevirmeyin.**
   Google/Apple akışından dönen `invalid-credential` "sağlayıcı token'ı
   reddedildi" demektir. Eşlemeyi düz bırakırsanız kullanıcı hiç şifre
   girmediği halde "E-posta veya şifre hatalı" görür ve hem kullanıcı hem siz
   yanlış yere bakarsınız. Servis içinde bu kodu `google`/`apple` koduna
   çevirin (yukarıdaki kodda yapıldı).

---

## 8. Çıkış

Masum görünen şu kod bir bug içerir:

```dart
// ❌ HATALI
Future<void> signOut() async {
  await GoogleSignIn.instance.signOut(); // initialize edilmediyse FIRLATIR
  await _auth.signOut();                 // ...ve buraya hiç gelinmez
}
```

`google_sign_in` v7'de `initialize()` çağrılmadan hiçbir metot kullanılamaz —
`signOut()` dahil. `initialize()`'ı yalnız Google girişi sırasında çağırıyorsanız
(doğru pratik), **e-posta veya Apple ile girmiş** bir kullanıcı çıkış yapmaya
kalktığında ilk satır fırlatır ve Firebase çıkışına sıra gelmez: **kullanıcı
çıkış yapamaz.** Üstelik bunu testlerde yakalamak zordur, çünkü test
senaryolarının çoğu Google ile girip Google ile çıkar.

```dart
// ✅ DOĞRU: Google temizliği "elinden geleni yap"; Firebase çıkışı her koşulda.
Future<void> signOut() async {
  try {
    await _ensureGoogleInitialized();
    await GoogleSignIn.instance.signOut();
  } on Object catch (e) {
    log('google sign-out cleanup skipped: $e');
  }
  await _auth.signOut();
}
```

---

## 9. Rota koruması

GoRouter kullanıyorsanız: koruma her ekranda ayrı `if` değil, tek bir
`redirect`'te yaşasın. Oturum değişiminde router'ın yeniden değerlendirmesi
için `refreshListenable` şarttır:

```dart
final router = GoRouter(
  refreshListenable: GoRouterRefreshStream(authService.authStateChanges()),
  redirect: (context, state) {
    final loggedIn = authService.currentUser != null;
    final location = state.matchedLocation;
    const protectedPrefixes = ['/profile']; // bilinçli dar tutun
    if (!loggedIn && protectedPrefixes.any(location.startsWith)) {
      return '/auth/login';
    }
    if (loggedIn && location.startsWith('/auth')) return '/home';
    return null;
  },
  routes: [...],
);
```

Tasarım önerisi: **misafiri gezdirin.** Korumalı önek listesini dar tutup
(yalnız gerçekten hesaba bağlı sayfalar), diğer ekranlarda içerik yerine
"giriş yap" kartı gösterin. Kayıt duvarı dönüşümü düşürür.

Ayrıca: giriş başarısında `pop` yerine ana sayfaya `go` tercih edin. Giriş
ekranı birçok yerden açılabilir; `pop` kullanıcıyı geldiği derin ekrana geri
bırakır ve "giriş yaptım ama hiçbir şey olmadı" hissi verir. `go` yığını da
temizler — geri tuşu giriş ekranına dönmez.

---

## 10. Kritik tuzaklar

| # | Tuzak | Belirti | Çözüm |
|---|---|---|---|
| 1 | Apple credential'da `accessToken` yok | `invalid-credential — Invalid OAuth response from apple.com`, token kusursuzken | `accessToken: apple.authorizationCode` ekle (§6) |
| 2 | v7 `GoogleSignIn.signOut()` initialize'sız | E-posta/Apple kullanıcısı çıkış yapamıyor | try/catch + önce initialize (§8) |
| 3 | Sağlayıcı hatası `invalid-credential` → "şifre hatalı" mesajı | Kullanıcı şifre girmeden şifre hatası görüyor | Servis içinde `google`/`apple` koduna çevir (§7) |
| 4 | İptal ile başarının ayrılmaması | Yarıda bırakılan giriş "başarılı" bildirimi gösteriyor | `Success/Canceled/Failure` üçlü sonuç tipi (§2) |
| 5 | Ham hata kodunun yutulması | Log'da yalnız "apple failed" — teşhis imkânsız | Kullanıcıya genel mesaj, log'a ham kod; token'ı ASLA loglama |
| 6 | `flutterfire configure` sonrası iOS URL scheme'i eski | Google girişi sessizce kırık | `REVERSED_CLIENT_ID` ↔ `Info.plist` eşitliğini elle doğrula (§5) |
| 7 | Projede bayat/çift app kaydı + yanlış `firebase.json` | Bir sonraki configure config dosyalarını yanlış app'le eziyor | Kullanılmayan app kayıtlarını sil, `firebase.json` appId'lerini doğrula (§3) |
| 8 | Apple ad/e-postası ilk girişten sonra `null` | Kullanıcı adı boş kalıyor | İlk yetkilendirmede hemen profile yaz (§6) |
| 9 | `BlocProvider` lazy varsayılanı | Oturum yan etkileri (uid, profil, FCM) açılışta çalışmıyor | `lazy: false` (§2) |
| 10 | Sosyal hesapla e-posta/şifre girişi denemesi | "Doğru şifreyle" `invalid-credential` | Hesabın sağlayıcı listesine bak — şifresi yok (§4) |
| 11 | SHA ekledikten sonra eski `google-services.json` | Android Google girişi çalışmıyor | Dosyayı yeniden indir (§5) |
| 12 | Yarım kalmış simülatör iCloud oturumu | Apple sayfası hiç açılmadan anında hata | Simülatörü sıfırla, iCloud'a TAM gir (§6) |

---

## 11. Teşhis rehberi

"Giriş çalışmıyor" dendiğinde körlemesine yapılandırma değiştirmeyin; sırayla
daraltın:

**1. Ham hata kodunu görün.** Genel "giriş başarısız" mesajı teşhis için
işe yaramaz. Servisteki catch bloklarına ham `code`/`message` logu ekleyin
(üretimde de kalabilir — token/kimlik bilgisi loglamadığınız sürece).

**2. Hangi tarafın reddettiğini belirleyin.** Akış iki yarıdır:
- *Sağlayıcı yarısı* (Apple/Google sayfası): `SignInWithAppleAuthorizationException`
  / `GoogleSignInException` buradan gelir → yapılandırma/entitlement/oturum sorunu.
- *Firebase yarısı* (`signInWithCredential`): `FirebaseAuthException` buradan
  gelir → sağlayıcı akışı BAŞARILI demektir; sorun credential kurulumu veya
  Firebase yapılandırmasıdır. (Meşhur #1 tuzağı bu yarıda yaşanır.)

**3. Token'ı kendiniz inceleyin (Firebase yarısı reddediyorsa).** Bir JWT'nin
başlık ve gövdesi base64url'dir; imza anahtarı kimliği (`kid`), `iss`, `aud`,
`exp` ve `nonce` claim'lerini geçici bir debug loguyla dökün:

```dart
// GEÇİCİ teşhis — token gövdesini/sub/email'i ASLA loglamayın.
Map<String, dynamic> part(String tok, int i) => json.decode(utf8.decode(
    base64Url.decode(base64Url.normalize(tok.split('.')[i]))));
final h = part(idToken, 0), p = part(idToken, 1);
log('jwt kid=${h['kid']} iss=${p['iss']} aud=${p['aud']} exp=${p['exp']}');
```

Kontrol listesi:
- `aud` == uygulamanızın bundle id'si mi?
- `iss` == `https://appleid.apple.com` mı?
- `kid`, `https://appleid.apple.com/auth/keys` listesindeki anahtarlardan biri mi?
- token'daki `nonce` == gönderdiğiniz SHA-256 hash mi?

**4. Hepsi doğruysa** sorun claims'te değildir; ya credential kurulumunda eksik
parametre vardır (Apple için `accessToken` — #1 tuzak) ya da Firebase konsol
yapılandırmasında (Apple'da native akış için Services ID boş olmalı; Google'da
SHA/Web client ID). Bu noktada paket sürümünüz + hata mesajıyla issue tracker
araması yapın — bu sınıf hataların çoğu bilinen regresyonlardır.

**5. Hesap-özel sorunlarda** kullanıcının sağlayıcı listesine bakın (Admin
SDK/Console): şifresi olmayan sosyal hesap (#10), farklı sağlayıcıya bağlı
e-posta (`account-exists-with-different-credential`) buradan tanınır.

---

## Kaynaklar

- [Firebase Auth — Flutter başlangıç](https://firebase.google.com/docs/auth/flutter/start)
- [Federated auth (Google/Apple) — Firebase](https://firebase.google.com/docs/auth/flutter/federated-auth)
- [google_sign_in v7 geçiş notları — pub.dev](https://pub.dev/packages/google_sign_in)
- [sign_in_with_apple — pub.dev](https://pub.dev/packages/sign_in_with_apple)
- [flutterfire #13242 — Apple girişi 5.2.0 regresyonu](https://github.com/firebase/flutterfire/issues/13242)
- [Apple Developer Forums thread 826547 — "Invalid OAuth response" vakası](https://developer.apple.com/forums/thread/826547)
- [Apple açık anahtarları (JWKS)](https://appleid.apple.com/auth/keys)
