# Flutter Starter Template — Project Guide

This is the first file to read to understand the project.
It explains what the project is, how it works, and where to find other documentation.

---

## First Clone?

If you just cloned this project from GitHub, follow this guide first:

→ **[../setup.md](../setup.md)** — Clean generated files, install dependencies, code-gen, Firebase question, and error analysis steps.

Come back to this file after setup is complete.

---

## What Is This Project?

A ready-to-use Flutter boilerplate/template for quickly starting new projects.
Includes theming, caching, navigation, localization, state management, service infrastructure, onboarding, and settings page out of the box.

- **Package name:** `akillisletme` (should be changed for new projects)
- **State Management:** Cubit + Freezed
- **DI:** GetIt (singleton pattern)
- **Routing:** GoRouter (type-safe, code-gen)
- **Cache:** SharedCache (SharedPreferences) + ProductCache (Hive CE)
- **Localization:** EasyLocalization (TR + EN)
- **Assets:** FlutterGen (type-safe)
- **Lint:** `very_good_analysis`

---

## Project Structure

```
build.yaml                                 # Codegen scope (per-builder generate_for)
script/                                    # general, codegen, lang, verify, deep_clean
.github/workflows/analyze.yml              # CI: pub get → codegen → format → analyze → test
.claude/skills/                            # starter-feature, starter-style-guide, starter-review
.claude/agents/                            # starter-architecture-reviewer

SETUP.md                                   # Kurulum giris noktasi (klonlayan buradan baslar)

doc/                                       # Duz — alt klasor yok
├── AGENTS.md                              # Canonical AI instructions
├── README.md                              # doc map + task→doc table + checklist
├── project.md                             # ← THIS FILE
├── clean_code.md                          # Portable clean-code standard
├── <konu>.md                              # Gelistirme rehberleri (state_management,
│                                          #   view_rules, design_tokens, ui_states,
│                                          #   forms_and_validation, testing, auth, ...)
└── <konu>_setup.md                        # Kurulum adimlari (auth_setup, payment_setup,
                                           #   android_signing, customization, ...)

test/
├── helper/pump_app.dart                   # Shared widget-test setup
└── product/                               # Mirrors lib/ structure

lib/
├── main.dart                              # App entry point
├── feature/                               # Screens / features
│   ├── home/
│   │   ├── home_view.dart                 # Home page (StatefulWidget + ViewModel)
│   │   ├── home_view_mode.dart            # ViewModel (abstract State)
│   │   ├── android_modules/
│   │   │   └── android_modules_view.dart  # Android native modules demo + izin UI
│   │   └── widget/
│   │       └── home_background.dart       # Global animated background
│   ├── login_process/
│   │   ├── onboarding/                    # 5-step onboarding
│   │   └── splash/                        # Splash screen + SplashCubit
│   └── settings/
│       ├── settings_view.dart             # Settings page
│       └── widget/                        # Theme, language tiles
└── product/                               # Shared infrastructure layer
    ├── cache/                             # SharedCache + Hive (ProductCache)
    ├── const/                             # AppString, AppPaddings, AppRadius, AppDurations,
    │                                      #   AppIconSizes, RegexTypes, AppSemanticKeys
    ├── enum/                              # ViewState, TextFieldType
    ├── init/                              # App init, error handler, localization, AppBuilder
    ├── model/                             # Shared immutable data models
    │   └── android_module_info.dart       # AndroidModuleInfo (icon, title, features)
    ├── navigation/                        # GoRouter config + transitions
    ├── service/                           # Services + GetIt DI
    ├── state/                             # App-wide cubits
    ├── theme/                             # Material 3 theme (8 variants, dark/light) + AppShadows
    ├── generated/                         # FlutterGen output
    ├── utils/                             # AppMessenger, extensions, validators,
    │                                      #   NetworkChecker, VersionChecker, haptics
    └── widget/                            # Shared buttons, text field, scaffold,
                                           #   state views, sheets, semantics

android/app/src/main/
├── kotlin/com/cleanstart/akillisletme/
│   ├── MainActivity.kt                    # Flutter bridge (MethodChannels + lifecycle)
│   ├── home_widget/
│   │   └── HomeWidget.kt                  # HomeWidgetProvider + HomeWidgetReceiver
│   └── overlay/
│       └── OverlayService.kt              # Floating overlay foreground service
└── res/
    ├── layout/
    │   ├── widget_home.xml                # Home screen widget layout
    │   └── overlay_window.xml             # Floating overlay layout
    ├── drawable/                          # Widget/overlay shape drawables
    └── xml/
        └── app_widget_info.xml            # Widget provider metadata
```

---

## App Flow

```
First launch:  Splash → Onboarding (5 steps) → Home
Subsequent:    Splash → Home (direct)
```

- Onboarding completion is saved to `SharedCache.isOnboardingCompleted`
- Router `initialLocation` decides based on this flag
- Settings page is accessible from Home AppBar
- Global background animation is visible on all pages via `AppBuilder`

---

## Built-in Infrastructure

### 1. Theme System

5 color variants (Purple, Blue, Green, Orange, Red) with Material 3. Auto dark/light.

- **Location:** `lib/product/theme/`
- **State:** `ThemeCubit` — saves variant selection to SharedCache
- **Usage:** `context.watch<ThemeCubit>().state`
- **Selection dialog:** `ThemeSelectionDialog.show(context)`
- **Details:** `lib/product/theme/THEME.md`

### 2. Cache System

| Data Type | System | Access |
|-----------|--------|--------|
| bool, int, String | SharedCache | `locator.sharedCache` |
| Model lists | ProductCache (Hive) | `locator.productCache` |

- **Location:** `lib/product/cache/`
- **Details:** `lib/product/cache/CACHE_GUIDE.md`

### 3. Navigation

Type-safe GoRouter with `go_router_builder` code-gen.

| Route | Path | Transition |
|-------|------|------------|
| HomeRoute | `/` | fade |
| SettingsRoute | `/settings` | slide right + fade |
| OnboardingRoute | `/onboarding` | fade |

- **Location:** `lib/product/navigation/app_router.dart`
- **Details:** `doc/guides/route_and_strings.md`

### 4. Localization (i18n)

`easy_localization` with TR + EN. JSON-based translation files.

- **Translation files:** `assets/translations/tr.json`, `en.json`
- **Type-safe keys:** `lib/product/init/language/locale_keys.g.dart` (generated)
- **Usage:** `LocaleKeys.home_title.tr()`
- **Change language:** `context.setLocale(Locale('en', 'US'))`

### 5. State Management

flutter_bloc + Freezed.

- **App-wide:** `lib/product/state/` (e.g. ThemeCubit)
- **Feature-level:** `lib/feature/<feature>/state/`
- **Provider registration:** `lib/product/init/state_initialize.dart`
- **Details:** `doc/guides/state_management.md`

### 6. Dependency Injection

GetIt singleton service management.

- **Location:** `lib/product/service/service_locator.dart`
- **Access:** `locator.sharedCache`, `locator.productCache`
- **Details:** `doc/guides/service_initialization.md`

### 7. Onboarding

5-step PageView. Completion saves `SharedCache.isOnboardingCompleted = true`.

- **Location:** `lib/feature/login_process/onboarding/`
- **Details:** `lib/feature/login_process/onboarding/ONBOARDING.md`

### 8. Settings Page

Theme selection + language switching. Accessible via Home AppBar settings icon.

- **Location:** `lib/feature/settings/`

### 9. Global Background Animation

Animated background visible on all pages.

- **Location:** `lib/feature/home/widget/home_background.dart`
- **Toggle:** `HomeBackground.enabledNotifier`

### 10. FlutterGen

Type-safe asset access with compile-time error checking + IDE autocomplete.

```dart
Assets.image.booom.image(width: 100)     // PNG/JPG
Assets.svg.bomb.svg(width: 24)           // SVG
Assets.lottie.backroundAnimation.lottie() // Lottie
FontFamily.poppins                        // Font
```

- **Details:** `doc/guides/assets_and_flutter_gen.md`

### 11. AppPaddings

Consistent spacing constants. Used instead of hardcoded `EdgeInsets`.

- **Values:** xs=4, s=8, m=12, l=16, xl=20, xxl=24, xxxl=32
- **File:** `lib/product/const/app_paddings.dart`

### 12. AppMessenger

Context extensions for SnackBar, Dialog, and BottomSheet.

```dart
context.showSuccessSnack('Saved!');
context.showErrorSnack('An error occurred');
context.showConfirmDialog(title: '...', message: '...');
context.showAppBottomSheet<void>(child: MyWidget());
```

- **File:** `lib/product/utils/app_messenger.dart`

### 13. RegexTypes

Validation patterns with Turkish character support: fullName, email, phoneNumber, password, url, plus text-normalization patterns.

- **File:** `lib/product/const/regex_types.dart`
- **Usage:** `RegexTypes.email.hasMatch(value)`

### 13a. Screen States (loading / error / empty / data)

`AppStateView` resolves all four states in one place, so no screen re-implements the `if (isLoading) … else if (isError) …` chain.

```dart
AppStateView(
  state: ViewState.from(isLoading: …, hasError: …, isEmpty: …),
  onRetry: cubit.load,
  loadingPlaceholder: const AppShimmerList(),
  builder: () => TaskList(tasks: state.tasks),
)
```

- **Location:** `lib/product/widget/state/`
- **Details:** [ui_states.md](ui_states.md)

### 13b. Forms

`AppTextField` derives keyboard type, autofill hints, input filters and length limits from `TextFieldType`; `Validators` supplies localized validation rules.

- **Location:** `lib/product/widget/app_text_field.dart`, `lib/product/utils/validator/`
- **Details:** [forms_and_validation.md](forms_and_validation.md)

### 13c. Global Error Handling

`AppErrorHandler` wires **both** channels — `FlutterError.onError` (framework) and `PlatformDispatcher.instance.onError` (uncaught async) — plus a guarded zone around `runApp`. Only one of these is not enough: framework-only wiring silently loses async errors.

- **File:** `lib/product/init/app_error_handler.dart`
- **Crashlytics:** single TODO inside `_report`; call sites never change

### 13d. Startup Checks

`SplashCubit` runs: connectivity → (optional) forced-version → proceed. Each branch is its own state; the view only draws.

- `NetworkChecker` — real DNS probe, no extra package; being on Wi-Fi ≠ having internet
- `VersionChecker` — segment-wise semver comparison (`1.2.10 < 1.3.0` resolves correctly)
- `requiresNetwork` defaults to `false` — flip it to `true` once the app fetches at startup

### 14. Firebase (Optional)

Firebase Remote Config integration is ready but commented out. To activate:

→ **[auth_setup.md](auth_setup.md)**

### 15. Home Screen Widget (Android)

Native Android home screen widget — no third-party packages. Users can control the counter directly from their home screen without opening the app.

- **Kotlin:** `android/.../home_widget/HomeWidget.kt` (`HomeWidgetProvider` + `HomeWidgetReceiver`)
- **Layout:** `res/layout/widget_home.xml` (RemoteViews — limited to standard Android views)
- **Shared data:** `SharedPreferences("widget_prefs", key: "counter")` — same file read by overlay and Flutter
- **Flutter bridge:** `MethodChannel('counter')` in `MainActivity.kt` → `get / increment / decrement / reset`
- **Demo UI:** `lib/feature/home/android_modules/android_modules_view.dart`

Widget button taps → `HomeWidgetReceiver` → updates SharedPreferences → updates widget UI → sends `ACTION_REFRESH` broadcast to overlay.

### 16. Floating Overlay (Android)

A draggable floating window drawn over all other apps using `WindowManager`. Visible only when the Flutter app is in the background.

- **Kotlin:** `android/.../overlay/OverlayService.kt` (ForegroundService)
- **Layout:** `res/layout/overlay_window.xml`
- **Permission required:** `SYSTEM_ALERT_WINDOW` — requested from `android_modules_view.dart`
- **Lifecycle:** `MainActivity.onStop()` → `startService()`, `MainActivity.onStart()` → `stopService()`
- **Shared data:** same `SharedPreferences("widget_prefs")` as home widget
- **Sync:** listens to `ACTION_REFRESH` broadcast; sends `AppWidgetManager.updateAppWidget()` on counter change

Drag threshold: 8px — smaller touches pass through to buttons.

**Permissions declared in `AndroidManifest.xml`:**
```
SYSTEM_ALERT_WINDOW, FOREGROUND_SERVICE, FOREGROUND_SERVICE_SPECIAL_USE
```

---

> ### 🤖 Android modülleri — kurulum soruları (cloner)
>
> Template klonlanıp kendi projeye uyarlanırken, widget ve overlay'i kendi veri
> modeline göre ayarlamak için 7 kurulum sorusu sorulur (veri tipi, widget/overlay
> başlığı, bildirim metni, MethodChannel adları, buton seti, demo sayfası).
>
> Tam liste ve varsayılanlar: **[customization.md](customization.md)**.

---

## Shared Widgets

| Widget | Location | Description |
|--------|----------|-------------|
| AppPrimaryButton | `product/widget/` | FilledButton |
| AppSecondaryButton | `product/widget/` | OutlinedButton |
| AppTextButton | `product/widget/` | TextButton |
| AppScaffold | `product/widget/` | Padding + SafeArea + keyboard dismiss |
| AppTextField | `product/widget/` | Typed input (keyboard/autofill/limits from `TextFieldType`) |
| KeyboardDismisser | `product/widget/` | Tap outside to close keyboard |
| AppSemantics | `product/widget/` | Stable UI-test identifiers |
| AppStateView | `product/widget/state/` | loading / error / empty / data switcher |
| AppLoadingView · AppErrorView · AppEmptyView | `product/widget/state/` | Individual state views |
| AppShimmer · AppShimmerBox · AppShimmerList | `product/widget/state/` | Skeleton placeholders |
| AppSelectSheet | `product/widget/sheet/` | Generic single-select bottom sheet |
| AppErrorSheet | `product/widget/sheet/` | Blocking error + retry sheet |
| ThemeSettingTile | `product/theme/widget/` | Theme selection tile |
| SettingsSection | `feature/settings/widget/` | Settings group card |

## Utilities

| Utility | File | Description |
|---------|------|-------------|
| AppMessenger | `product/utils/app_messenger.dart` | SnackBar, Dialog, BottomSheet |
| Validators / AppValidator | `product/utils/validator/` | Form validation rules |
| NetworkChecker | `product/utils/network_checker.dart` | Real connectivity probe (no package) |
| VersionChecker | `product/utils/version_checker.dart` | Semantic version comparison |
| AppErrorHandler | `product/init/app_error_handler.dart` | Global uncaught error capture |
| ResponsiveExtension | `product/utils/extension/context_extension.dart` | `context.isWide`, `context.r(20)`, `context.rf(16)` |
| ThemeContextExtension | `product/utils/extension/context_extension.dart` | `context.colorScheme`, `context.textTheme`, keyboard state |
| StringExtension | `product/utils/extension/string_extension.dart` | `normalize`, `initials`, `withHttps`, … |
| DateTimeExtension | `product/utils/extension/date_time_extension.dart` | `timeAgo`, `relativeDayLabel`, `shortDate`, … |
| Int/Double/FileSize extensions | `product/utils/extension/num_extension.dart` | `padded`, `grouped`, `readableFileSize`, … |
| ButtonFeedback | `product/utils/button_feedback.dart` | Haptic + sound feedback |
| ThemeDecorations | `product/utils/theme_decorations.dart` | Theme-based container decoration |

## Design Tokens

| Token | File |
|-------|------|
| AppPaddings | `product/const/app_paddings.dart` |
| AppRadius | `product/const/app_radius.dart` |
| AppDurations | `product/const/app_durations.dart` |
| AppIconSizes | `product/const/app_icon_sizes.dart` |
| AppShadows | `product/theme/app_shadows.dart` |
| RegexTypes | `product/const/regex_types.dart` |
| AppSemanticKeys | `product/const/app_semantic_keys.dart` |

Details: [design_tokens.md](design_tokens.md)

## Fonts

| Font | Usage |
|------|-------|
| Poppins | Display + Headline (large titles) |
| Inter | Title + Label + Body (body text) |

---

## Documentation Map

To find which file to read when adding a new feature:

→ **[doc/guides/README.md](README.md)** — Task-based navigation table + checklist

### Inline guides (inside code)

| File | Location | Topic |
|------|----------|-------|
| `CACHE_GUIDE.md` | `lib/product/cache/` | Cache system usage guide |
| `THEME.md` | `lib/product/theme/` | Theme system documentation |
| `ONBOARDING.md` | `lib/feature/login_process/onboarding/` | Onboarding module |

---

## New Project Setup (Customization)

Template'i kendi projene uyarlamanın tüm adımları (paket adı, çeviriler, store URL'leri, tema varyantları, Android modül soruları) tek yerde:

→ **[customization.md](customization.md)**

---

## Commands

Uzun komutları elle yazma — hepsi `script/` altında ve CI ile aynı adımları çalıştırır.

```bash
./script/general.sh     # pub get + codegen + locale keys (klon sonrası tek komut)
./script/codegen.sh     # Freezed, GoRouter, Hive, FlutterGen
./script/lang.sh        # locale_keys.g.dart  (-s en.json bayrağını garanti eder)
./script/verify.sh      # BITIRME: dart format → flutter analyze → flutter test
./script/deep_clean.sh  # üretilen dosyaları ve bağımlılıkları sıfırdan kur
```

`rps` kuruluysa: `rps general`, `rps verify`, `rps codegen`, `rps lang`, `rps deepClean`.

**Codegen kapsamı** `build.yaml` ile daraltılmıştır (her builder yalnızca ilgilendiği dosyaları tarar). Yeni bir builder eklenirse kapsamı orada da tanımlanmalı.
