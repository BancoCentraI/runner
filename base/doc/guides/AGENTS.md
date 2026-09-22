# AGENTS.md — clean_start (Flutter Starter Template)

Bu dosya, bu depoda çalışan **herhangi bir AI ajanı** (Claude, Cursor, Copilot, Codex, Windsurf…) için kanonik talimat dosyasıdır. Kökteki `CLAUDE.md`, `AGENTS.md` ve `.cursorrules` sadece buraya yönlendirir — **tek kaynak bu dosyadır.**

> O üç pointer dosyası kökte durmak zorundadır: ajanlar talimat dosyasını yalnızca kök dizinde arar.


Bu depo bir Flutter **starter template**'idir. Mimari kuralların ayrıntısı `doc/` klasöründedir; kurallar burada tekrarlanmaz, ilgili doc dosyası okunur. Bu dosya yalnızca üç şeyi yapar: (1) yönlendirme, (2) genel kod prensibine referans, (3) doc'ta olmayan bağlayıcı kurallar.

## Nasıl başlarsın (her oturum)

Kod yazmadan önce sırayla:

1. **`doc/guides/README.md`** — doc haritası + görev→doc yönlendirme tablosu.
2. **`doc/guides/project.md`** — proje ne, hangi sistemler var, uygulama akışı.
3. **`doc/guides/clean_code.md`** — her satır kodda geçerli, taşınabilir temiz-kod standardı.

Yapacağın işe ait doc dosyasını **okumadan** o alanda kod yazma.

## Kim için çalışıyorsun?

Bu depoda çalışıyorsan **template'in geliştiricisisin.** Kökteki `doc/setup.md` ve `doc/` altındaki tüm dosyalar template'i klonlayıp **kendi projesine uyarlayan kullanıcı** içindir. Bu kurulum akışlarını kendi başına çalıştırma; kullanıcı açıkça isterse ona rehberlik et.

## Göreve göre okunacak doc

| Yapılacak iş | Önce oku |
|---|---|
| Temiz kod standardı (her zaman geçerli) | `doc/guides/clean_code.md` |
| Yeni feature | `doc/guides/README.md` (checklist) + `doc/guides/folder_structure.md` |
| Cubit / state | `doc/guides/state_management.md` |
| View / widget yapısı | `doc/guides/view_rules.md` |
| Model (Freezed / Hive) | `doc/guides/model_rules.md` |
| Servis yazma | `doc/guides/service_rules.md` + `doc/guides/service_initialization.md` |
| Veri saklama kararı | `doc/guides/data_storage.md` |
| Route / string ekleme | `doc/guides/route_and_strings.md` |
| Widget yerleşimi / tema | `doc/guides/widget_and_theme.md` |
| Padding / radius / gölge / süre | `doc/guides/design_tokens.md` |
| Ekran durumları (loading/error/empty/data) | `doc/guides/ui_states.md` |
| Form / input / validation | `doc/guides/forms_and_validation.md` |
| Extension yazma | `doc/guides/extensions.md` |
| Test yazma | `doc/guides/testing.md` |
| Asset ekleme | `doc/guides/assets_and_flutter_gen.md` |
| Enum / sabit | `doc/guides/enums_and_constants.md` |
| Genel bakış / sistemler | `doc/guides/project.md` |
| Template'i yeni projeye uyarlama (cloner) | kökteki `doc/setup.md` → `doc/` |

## Komutlar

Elle uzun komut yazma; hepsi script'te ve CI ile aynı adımları çalıştırır.

| Komut | İş |
|---|---|
| `./script/general.sh` | `pub get` + codegen + çeviri anahtarları (klon sonrası tek komut) |
| `./script/codegen.sh` | Freezed / GoRouter / Hive / FlutterGen |
| `./script/lang.sh` | `locale_keys.g.dart` (`-s en.json` bayrağını garanti eder) |
| `./script/verify.sh` | **Bitirme kontrolü**: format → analyze → test |
| `./script/deep_clean.sh` | Üretilen dosyaları ve bağımlılıkları sıfırdan kurar |

`rps` kuruluysa aynıları `rps general`, `rps verify` şeklinde de çalışır.

## Skill'ler

İş tipine göre `.claude/skills/`:

| İş | Skill |
|---|---|
| Klonladıktan sonra kurulum (cloner) | `starter-setup` |
| Yalnızca Firebase + giriş kurulumu | `starter-auth-setup` |
| Yeni feature / sayfa iskelesi | `starter-feature` |
| Tema / token / UI tasarım sistemi | `starter-style-guide` |
| Değişiklik denetimi (diff / PR) | `starter-review` |

Derin mimari uygunluk denetimi `starter-architecture-reviewer` subagent'ına devredilir.

## Kod yazarken

- Yazdığın her Dart/Flutter kodu **`doc/guides/clean_code.md`** standardına uyar (widget kuralları, dört-durum, hata yönetimi, paket disiplini, test, bitirme kontrolü). Bu standart **mimari-agnostiktir**: projenin mevcut mimarisine (Cubit+Freezed, GetIt locator, GoRouter) dokunmaz, onun *içinde* temiz kod yazdırır.
- **Mevcut desene uy.** Aynı türde iş nasıl yapılmış (benzer ekran, benzer servis) bak, o deseni takip et. Yeni pattern/yaklaşım icat etme; gerekiyorsa önce sor.

## Doc'ta olmayan bağlayıcı kurallar

- **Dil:** doc ve doc-comment'ler Türkçe; kod tanımlayıcıları (sınıf, değişken, metot) İngilizce.
- **Rapor/analiz/plan/fikir** dokümanları `doc/` veya `doc/reports/` altına yazılır. Kök dizine veya rastgele klasörlere `.md` bırakma. Kökteki `.md` dosyaları sabittir ve artırılmaz: `README.md`, `doc/setup.md`, `AGENTS.md`, `CLAUDE.md`.
- Her yeni feature, `doc/guides/folder_structure.md`'deki kurala göre kendi **`<feature>.md`** dokümanıyla birlikte gelir. Doc yazılmadıysa feature bitmemiştir.
- Template'e yeni bir sistem/pattern eklendiğinde ilgili `doc/` dosyası **aynı commit'te** güncellenir. Doc'u sonraya bırakma.
- Kod stili **`very_good_analysis`**: `flutter analyze` sıfır uyarı ile biter; `// ignore:` ile susturma yapılmaz.
- Inline `TextStyle(fontSize: ...)` ve inline renk **yasak** → `product/theme/` üzerinden git (`doc/guides/widget_and_theme.md`).
- Ham `EdgeInsets` / `BorderRadius.circular(<sayı>)` / `Duration(...)` / ikon boyutu **yasak** → token kullan (`doc/guides/design_tokens.md`).
- Veri çeken her ekran dört durumu ele alır → `AppStateView` (`doc/guides/ui_states.md`).
- **Bitirme:** `./script/verify.sh`. Ayrıntı: `doc/guides/clean_code.md`.

## Doc ile kod çelişirse

Hangisinin güncel olduğunu **SOR**; kafana göre birini seçme.

## Bilinen açık kararlar

- **DI:** eski servisler singleton (`.instance`) + locator kaydı kullanıyor. Yeni servisler `registerLazySingleton` / `registerSingletonAsync` + constructor injection ile yazılır (Firebase servis katmanı böyle); mevcut `.instance` kullananları migrate etme kararı ayrıca verilecek.
- **Firebase servisleri** `interface + FirebaseXxx + NoopXxx` üçlüsüyle yazılır; `AppConfig.firebaseEnabled` kapalıyken no-op bağlanır. Çağrı yerinde `if (firebaseEnabled)` yazılmaz.
