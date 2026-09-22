# doc/ — Bilgi Tabanı (AI buradan başla)

Bu klasör bu template'in yerleşik bilgi tabanıdır. Kuralları ezberlemek yerine ilgili dosyayı oku. Giriş noktası ve bağlayıcı kurallar: **[`AGENTS.md`](AGENTS.md)** .

## Klasör haritası

| Klasör / dosya | İçerik |
|---|---|
| [`AGENTS.md`](AGENTS.md) | **Kanonik AI talimat dosyası** — okuma sırası ve bağlayıcı kurallar |
| [`project.md`](project.md) | Proje genel bakışı: sistemler, mimari, uygulama akışı |
| [`clean_code.md`](clean_code.md) | Her satır kodda geçerli taşınabilir temiz-kod standardı |
| [``]() | Günlük geliştirme görev rehberleri (feature, state, servis, model…) |
| [``]() | **Klonlayan kullanıcı** için tek seferlik kurulum ve özelleştirme |
| [``]() | Ortam sorunları (emulator vb.) |
| [``]() | Plan, fikir ve yol haritası dokümanları |

> Kurulumun giriş noktası kökteki **[`doc/setup.md`](../setup.md)**'dir; `` altındaki dosyalar onun adım rehberleridir.
> `` klasörü template'i kendi projesine uyarlayan kullanıcı içindir. Template'in geliştiricisiysen bu akışları kendi başına çalıştırma (bkz. `AGENTS.md` → "Kim için çalışıyorsun?").

## Görev → doc yönlendirme

| Yapılacak iş | Oku |
|---|---|
| Yeni feature klasörü | [folder_structure.md](folder_structure.md) |
| Servis ekleme | [service_rules.md](service_rules.md) + [service_initialization.md](service_initialization.md) |
| Model oluşturma | [model_rules.md](model_rules.md) |
| Enum / sabit ekleme | [enums_and_constants.md](enums_and_constants.md) |
| State kurulumu (Cubit + Freezed) | [state_management.md](state_management.md) |
| Veri saklama (SharedCache / Hive) | [data_storage.md](data_storage.md) |
| View kurma (Stateless / Stateful) | [view_rules.md](view_rules.md) |
| Widget ekleme / tema kullanımı | [widget_and_theme.md](widget_and_theme.md) |
| Tasarım token'ı (padding/radius/gölge/süre) | [design_tokens.md](design_tokens.md) |
| Ekran durumu (loading/error/empty/data) | [ui_states.md](ui_states.md) |
| Form / input / validation | [forms_and_validation.md](forms_and_validation.md) |
| Extension yazma / kullanma | [extensions.md](extensions.md) |
| Test yazma | [testing.md](testing.md) |
| Route / UI string ekleme | [route_and_strings.md](route_and_strings.md) |
| Asset ekleme (image, SVG, Lottie) | [assets_and_flutter_gen.md](assets_and_flutter_gen.md) |
| Giriş / oturum / rota koruması | [auth.md](auth.md) |
| Firebase Auth derin teşhis | [flutter-firebase-auth-rehberi.md](flutter-firebase-auth-rehberi.md) |
| **Klonladıktan sonra kurulum** | [../setup.md](../setup.md) |
| Store URL / iletişim güncelleme | [settings_and_urls.md](settings_and_urls.md) |
| Yeni projeye uyarlama | [customization.md](customization.md) |
| Ödeme / abonelik kurulumu | [payment_setup.md](payment_setup.md) |
| Android release imzalama | [android_signing.md](android_signing.md) |

## Yeni feature checklist

Yeni bir feature eklerken:

- [ ] `lib/feature/<feature>/` klasör yapısını kur ([folder_structure.md](folder_structure.md))
- [ ] `<feature>.md` modül dokümanını yaz ([folder_structure.md](folder_structure.md))
- [ ] Model gerekiyorsa Freezed + toMap/fromMap ile yaz ([model_rules.md](model_rules.md))
- [ ] Freezed state + Cubit'i doğru yerde konumlandır ([state_management.md](state_management.md))
- [ ] App-geneli state mi? → `product/state/`, değilse `feature/state/`
- [ ] BlocProvider: global (state_initialize) mı, lokal (view içinde) mi karar ver
- [ ] `dart run build_runner build --delete-conflicting-outputs` çalıştır
- [ ] View tipini belirle: StatelessWidget / StatefulWidget + ViewModel ([view_rules.md](view_rules.md))
- [ ] StatefulWidget ise `_view.dart` + `_view_model.dart` olarak ayır
- [ ] Widget ihtiyacı: önce `product/widget/` kontrol et, varsa kullan ([widget_and_theme.md](widget_and_theme.md))
- [ ] Ortak widget yoksa ve genelse → `product/widget/`; feature'a özelse → `feature/widget/`
- [ ] Veri çeken ekransa dört durum `AppStateView` ile ele alındı ([ui_states.md](ui_states.md))
- [ ] Liste ekranıysa `loadingPlaceholder` olarak shimmer verildi
- [ ] Form varsa `AppTextField` + `Validators` kullanıldı ([forms_and_validation.md](forms_and_validation.md))
- [ ] Tema: `product/theme/parts/` kontrol et, global stil yeterse override etme
- [ ] Enum → `product/enum/` (önce mevcut var mı bak) ([enums_and_constants.md](enums_and_constants.md))
- [ ] Sabit → `product/const/`
- [ ] Servis ihtiyacı: locator'ı kontrol et, gerekirse ekle ([service_rules.md](service_rules.md) + [service_initialization.md](service_initialization.md))
- [ ] Async init gerektiriyor mu → locator'daki `_registerAsyncSingletons()`'a ekle (`allReady()` bekler)
- [ ] Basit veri cache? → `SharedCache` + `SharedKeys` ([data_storage.md](data_storage.md))
- [ ] Model/liste cache? → `ProductCache` + Hive model ([data_storage.md](data_storage.md))
- [ ] String'leri `AppString`'e ekle ([route_and_strings.md](route_and_strings.md))
- [ ] Route'u `app_router.dart`'a TypedGoRoute olarak ekle + build_runner ([route_and_strings.md](route_and_strings.md))
- [ ] Padding/radius/gölge/süre/ikon boyutu token'dan, hardcoded değer yok ([design_tokens.md](design_tokens.md))
- [ ] Kullanıcı geri bildirimi gerekiyor mu? `AppMessenger` kullan ([widget_and_theme.md](widget_and_theme.md))
- [ ] Asset: `Assets.xxx` üretilmiş accessor'lar, hardcoded path yok ([assets_and_flutter_gen.md](assets_and_flutter_gen.md))
- [ ] Yeni asset eklendi mi? `./script/codegen.sh`
- [ ] Responsive kontrol ekle (`context.isWide`) ([extensions.md](extensions.md))
- [ ] Tema renklerini kullan (hardcoded renk yok)
- [ ] UI testi gerekiyorsa `AppSemantics` + `AppSemanticKeys` kimliği eklendi ([testing.md](testing.md))
- [ ] Yeni iş mantığı (cubit metodu, servis, validator) testle geldi ([testing.md](testing.md))
- [ ] **Bitirme:** `./script/verify.sh` sıfır hata ile geçti
