# Test

`doc/guides/clean_code.md` → "Test": yeni iş mantığı (cubit/servis metodu, extension, validator) testle gelir. Test dosyası kaynakla **aynı klasör yapısında** `test/` altındadır.

```
lib/product/utils/version_checker.dart
test/product/utils/version_checker_test.dart
```

## Çalıştırma

```bash
flutter test                       # tümü
flutter test test/product/utils    # klasör
./script/verify.sh                 # format + analyze + test
```

## Yardımcı: pump_app.dart

`test/helper/pump_app.dart` iki şey sağlar:

```dart
void main() {
  setUpAll(initializeTestBindings);   // binding + SharedPreferences mock + EasyLocalization

  testWidgets('...', (tester) async {
    await tester.pumpApp(const MyWidget());
  });
}
```

`pumpApp`, widget'ı **uygulamanın gerçek temasıyla** bir `Scaffold` içinde çizer. Dark mod'da test için:

```dart
await tester.pumpApp(const MyWidget(), themeMode: ThemeMode.dark);
```

Farklı tema varyantı denemek için `themeState:` parametresi.

### Neden EasyLocalization widget'ı kullanılmıyor?

`Localizations`, delegeleri çözülene kadar alt ağacı **hiç çizmez**. Aynı dosyadaki ikinci widget testinde çeviri yüklemesi frame içinde tamamlanmadığı için ağaç boş kalır ve testler sessizce "0 widget bulundu" ile düşer.

Bunun yerine yalnızca depolama katmanı başlatılır. Bu durumda `LocaleKeys.x.tr()` çevirinin **anahtar yolunu** döndürür (`'validation.required'`) ve hiçbir şey patlamaz. Konsoldaki `Localization key not found` uyarıları beklenen davranıştır.

**Sonuç kural: widget testleri çevrilmiş metne değil, widget tipine ve davranışa bakar.**

```dart
// Yapma — çeviri değişince kırılır, test ortamında zaten çalışmaz
expect(find.text('Tekrar Dene'), findsOneWidget);

// Yap
expect(find.byType(AppPrimaryButton), findsOneWidget);
await tester.tap(find.byType(AppPrimaryButton));
```

## pumpAndSettle kullanma

`AppLoadingView` gibi sonsuz animasyon içeren ağaçlarda `pumpAndSettle` asla durulmaz ve test zaman aşımına uğrar. Sabit sayıda `pump()` kullan:

```dart
await tester.pump();
await tester.pump(AppDurations.short);
```

## Cubit testi

Servisler constructor'dan geldiği için sahte (fake) implementasyon vermek yeterlidir — GetIt'e dokunmaya gerek yok:

```dart
final class _FakeTaskService implements TaskService {
  @override
  Future<List<Task>> fetch() async => [Task(id: 1)];
}

test('yukleme sonrasi liste dolar', () async {
  final cubit = TaskCubit(service: _FakeTaskService());
  await cubit.load();
  expect(cubit.state.tasks, hasLength(1));
});
```

Yeni bir sınıfa singleton'a doğrudan çağrı gömme — test edilemez hale gelir (`doc/guides/clean_code.md` → Test).

## Ne test edilir

| Test edilir | Edilmez |
|---|---|
| Cubit/servis metot davranışı | Framework'ün kendi işi |
| Extension ve validator kuralları | Çeviri metninin içeriği |
| Dört durumun doğru dallanması | Piksel konumu / tam renk değeri |
| Sınır durumlar (boş, null, aşırı değer) | Getter/setter |

## UI testi (Maestro)

Widget'lara test kimliği `AppSemantics` ile verilir; kimlikler `AppSemanticKeys` enum'ında toplanır (`lib/product/const/app_semantic_keys.dart`).

```dart
AppSemantics(
  semanticKey: AppSemanticKeys.retryButton,
  child: AppPrimaryButton(label: ..., onPressed: ...),
)
```

Maestro tarafında: `- tapOn: { id: "retryButton" }`

Yeni bir ekran eklendiğinde kimliği enum'a ekle — kodun içine serbest string yazma.
