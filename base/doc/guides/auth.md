# Kimlik Doğrulama

Kurulum (Firebase bağlama, sağlayıcı açma) bu rehberde değil:
→ **[`doc/guides/auth_setup.md`](auth_setup.md)**

Bu dosya günlük geliştirmede auth'la nasıl çalışılacağını anlatır.

## Katmanlar

```
Ekranlar (login/register/forgot/verify)   lib/feature/auth/
      │ yalnız cubit'i çağırır
AuthCubit ◄── authStateChanges() stream    lib/product/state/auth/
      │ yalnız interface'i görür
AuthService (abstract interface)           lib/product/service/firebase/auth/
      ├── FirebaseAuthService   (üretim)
      └── MockAuthService       (Firebase kapalıyken + testte)
```

`AppConfig.firebaseEnabled` hangisinin bağlanacağını belirler. **Firebase
kurulmadan da giriş akışı çalışır** — mock herhangi bir e-posta/şifreyi kabul
eder.

## Sert kurallar

**1. Ekran yönlendirme yapmaz.**
Başarılı girişte `go`/`pop` çağırma. Oturum `authStateChanges` stream'inden
akar, `GoRouterRefreshStream` guard'ı yeniden değerlendirir ve yönlendirmeyi
router yapar. Elle yönlendirmek çift geçişe yol açar.

**2. Guard'lı rotalara daima `go`.**
`push` imperative'dir: declarative URI değişmez, `refreshListenable`
tetiklendiğinde go_router yalnızca declarative location'ı yeniden değerlendirir
— pushed sayfanın redirect'i bir daha çalışmaz. Sonuç: giriş yapılmış olmasına
rağmen login ekranı ekranda takılı kalır.

**3. İptal hata değildir.**
`AuthActionCanceled` geldiğinde hiçbir mesaj gösterme. Kullanıcı zaten
bilinçli olarak vazgeçti.

**4. Cubit'te elle emit yok.**
Aksiyon metotları yalnızca servisi çağırır ve `AuthActionResult` döner. İki
istisna vardır ve ikisi de dokümante edilmiştir: `emailVerified` ve
`displayName` değişimleri `authStateChanges`'i tetiklemez, o yüzden elle emit
edilir.

**5. Servis kullanıcı metni üretmez.**
Yalnız dilden bağımsız kod taşır (`AuthException.code`); metin
`AuthErrorLocalizer` ile tek yerde çevrilir.

## Kullanım

```dart
final result = await context.read<AuthCubit>().signInWithEmail(email, password);

switch (result) {
  case AuthActionSuccess():
    break;                                   // router yönlendirir
  case AuthActionCanceled():
    break;                                   // sessiz
  case AuthActionFailure(:final message):
    context.showErrorSnack(message);         // yerelleştirilmiş
}
```

Oturum durumunu okumak:

```dart
final isLoggedIn = context.select<AuthCubit, bool>((c) => c.state.isLoggedIn);
final name = context.watch<AuthCubit>().state.displayName;
```

## Rota koruması

`AppRouter.protectedPrefixes` — oturum isteyen önekler. Liste **bilinçli
olarak dar**: misafir gezebilir (`AppConfig.allowGuestBrowsing`). Kayıt duvarı
dönüşümü düşürür; önce değeri göster, hesaba bağlanan yerde giriş iste.

Yeni korumalı rota gerektiğinde önekini listeye eklemek yeterlidir; ekranda
`if (loggedIn)` yazılmaz.

`AppConfig.requireEmailVerification` açıkken doğrulanmamış kullanıcı yalnızca
`EmailVerificationView`'u görebilir.

## Yan etkiler

`AuthSideEffects` (`product/init/`) oturum değişiminde şunları yapar:
RevenueCat `appUserId` senkronu, Analytics kimliği + `login` olayı, Firestore
profil upsert'i. Cubit'in ödeme/profil servislerini tanımaması için ayrı
tutulmuştur.

**RevenueCat UID bağı kritiktir:** bağlanmazsa kullanıcı cihaz değiştirdiğinde
ödediği aboneliği kaybeder.

## Hesap silme

`AuthCubit.deleteAccount({password})` — **mağaza şartıdır** (App Store
5.1.1(v), Google Play): hesap oluşturmaya izin veren uygulama hesap silmeyi de
sunmak zorundadır.

Sıra: sağlayıcıya göre yeniden doğrula → sil → çık. Firebase 5 dakikadan taze
giriş ister; e-posta kullanıcısında şifre zorunludur (UI dialog'la toplar).

Bu akış yalnızca Auth kullanıcısını siler. Firestore/Storage'daki kullanıcı
verisi büyüdüğünde silme işi Admin SDK ile bir Cloud Function'a taşınmalıdır.

## Test

`MockAuthService` fake görevi görür — GetIt'e dokunmaya gerek yok:

```dart
final cubit = AuthCubit(MockAuthService());
```

Belirli bir hatayı üretmek için `AuthService`'i sarmalayan bir sınıf yaz
(`MockAuthService` `final class`'tır, genişletilemez). Örnek:
`test/product/state/auth/auth_cubit_test.dart`.

## Derin teşhis

Google/Apple girişi "sessizce" kırıldığında:
→ [`flutter-firebase-auth-rehberi.md`](flutter-firebase-auth-rehberi.md)
