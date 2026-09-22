# Form ve Validation

İki parça: girdi alanı (`AppTextField`) ve doğrulama (`AppValidator`). İkisi de hata metnini kendi içinde üretir; çağrı yeri metin yazmaz.

## AppTextField

`lib/product/widget/app_text_field.dart`

```dart
AppTextField(
  controller: emailController,
  label: LocaleKeys.auth_email.tr(),
  type: TextFieldType.email,
  validator: Validators.email,
)
```

Klavye tipi, otomatik doldurma ipucu, girdi filtresi ve karakter sınırı **`TextFieldType`'tan** gelir (`lib/product/enum/text_field_type.dart`) — bunları tek tek vermeye gerek yok.

| Tür | Klavye | Otomatik doldurma | Not |
|---|---|---|---|
| `text` | metin | — | varsayılan |
| `multiline` | çok satırlı | — | 3–5 satır, `TextInputAction.newline` |
| `email` | e-posta | `email` | |
| `password` | gizli | `password` | göster/gizle düğmesi otomatik |
| `phone` | telefon | `telephoneNumber` | rakam + biçim karakterleri |
| `number` | sayısal | — | yalnız rakam |
| `url` | url | `url` | |
| `name` | ad | `name` | |
| `search` | metin | — | karakter sınırı yok |

Görünüm tema `inputDecorationTheme`'inden gelir — alan içinde stil verilmez.

## Validators

`lib/product/utils/validator/app_validator.dart`

```dart
validator: Validators.required
validator: Validators.email
validator: Validators.optionalPhone()
validator: Validators.minLength(3)
validator: Validators.numericRange(min: 1, max: 99)
validator: Validators.match(() => passwordController.text)
validator: Validators.all([Validators.required, Validators.minLength(8)])
```

Hazır kurallar: `required`, `optional`, `email`, `phone`, `password`, `fullName`, `url`, `minLength`, `maxLength`, `numericRange`, `match`, `all`.

Regex'ler `RegexTypes` içinde (`lib/product/const/regex_types.dart`), hata metinleri `LocaleKeys.validation_*` altında.

### İki kullanım biçimi

```dart
validator.validate(value)   // hata metni ya da null — TextFormField.validator ile uyumlu
validator.isValid(value)    // bool — "kaydet" butonunu canlı aktif/pasif yapmak için
```

### Yeni kural yazma

`AppValidator`'dan türet, hata metnini `LocaleKeys`'ten al, `Validators`'a kısa erişim ekle:

```dart
final class IbanValidator extends AppValidator {
  const IbanValidator();

  @override
  String? validate(String? value) {
    if (value.isNullOrBlank) return LocaleKeys.validation_required.tr();
    return RegexTypes.iban.hasMatch(value!) ? null : LocaleKeys.validation_iban.tr();
  }
}
```

Yeni anahtarı `tr.json` **ve** `en.json`'a ekle, `./script/lang.sh` çalıştır.

## Form iskeleti

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    spacing: AppPaddings.l,
    children: [
      AppTextField(controller: _email, label: ..., type: TextFieldType.email, validator: Validators.email),
      AppTextField(controller: _password, label: ..., type: TextFieldType.password, validator: Validators.password),
      AppPrimaryButton(label: ..., onPressed: _submit),
    ],
  ),
)

void _submit() {
  if (!_formKey.currentState!.validate()) return;
  context.read<AuthCubit>().signIn(_email.text.trim(), _password.text);
}
```

Controller'lar `StatefulWidget` + `_view_model.dart` içinde açılır ve `dispose()` edilir ([view_rules.md](view_rules.md)).

## Kurallar

- Hata metni validator'ın içinde üretilir; çağrı yerinde `'Zorunlu alan'` yazılmaz.
- Aynı kural iki ekranda gerekiyorsa yeni validator sınıfı yazılır, kopyalanmaz.
- Kullanıcı girdisi kaydedilmeden önce `value.normalize` ile sadeleştirilir.
- `AppScaffold` boşluğa dokununca klavyeyi kapatır — form ekranında ayrıca uğraşma.
