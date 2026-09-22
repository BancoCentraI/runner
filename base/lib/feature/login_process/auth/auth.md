# Auth Modülü

## Özet

Giriş, kayıt, şifre sıfırlama ve e-posta doğrulama ekranları. Oturum durumunun kendisi app-geneli olduğu için `product/state/auth/` altındadır; bu klasör yalnızca **ekranları** içerir.

Firebase kurulu olmadan da çalışır: `AppConfig.firebaseEnabled` false iken `MockAuthService` devrededir.

## Yapılar

| Dosya | Ne yapar |
|---|---|
| `login_view.dart` + `login_view_model.dart` | E-posta/şifre girişi + sosyal giriş + şifremi unuttum bağlantısı |
| `register_view.dart` + `register_view_model.dart` | Kayıt (ad, e-posta, şifre + tekrar) |
| `forgot_password_view.dart` | Şifre sıfırlama bağlantısı gönderir |
| `email_verification_view.dart` | `AppConfig.requireEmailVerification` açıkken doğrulama kapısı |
| `widget/auth_scaffold.dart` | Ortak kabuk: başlık + genişlikte sınırlı form + `AuthDivider` + `AuthFooterAction` |
| `widget/social_sign_in_buttons.dart` | Google/Apple butonları — `AppConfig` bayraklarına göre çizilir |

## Bağlı olduğu app-geneli parçalar

- `product/state/auth/auth_cubit.dart` — `AuthCubit`, `AuthActionResult`, `AuthState`
- `product/service/firebase/auth/` — `AuthService` sözleşmesi, `FirebaseAuthService`, `MockAuthService`
- `product/navigation/app_router.dart` — `AppRouter._redirect` (auth-gating)

## Kurallar

- **Ekran yönlendirme yapmaz.** Başarılı girişte `go`/`pop` çağrılmaz; oturum `authStateChanges` stream'inden akar ve router `refreshListenable` ile yönlendirir. Elle yönlendirmek çift geçişe yol açar.
- **İptal hata değildir.** `AuthActionCanceled` geldiğinde hiçbir mesaj gösterilmez.
- **Girişte şifre kuralı doğrulanmaz.** Mevcut şifre, kurallar değişmeden önce oluşturulmuş olabilir; `Validators.required` yeterlidir. Kural yalnızca kayıtta uygulanır.
- Sosyal buton eklemek/çıkarmak için bu klasöre dokunulmaz — `AppConfig` bayrağı çevrilir.

## Kurulum

Sağlayıcıları açmak ve Console tarafında yapılması gerekenleri görmek için:
**[`doc/guides/auth_setup.md`](../../../doc/guides/auth_setup.md)** (ya da `starter-auth-setup` skill'i).
