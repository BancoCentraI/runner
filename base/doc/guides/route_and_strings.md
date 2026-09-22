# Route Addition & Strings

## Route Addition (TypedGoRoute)

The project uses type-safe `TypedGoRoute` + `GoRouteData` + code generation.
Routes are defined in `lib/product/navigation/app_router.dart`.

### Adding a new route (3 steps):

**1. Create a GoRouteData class** (`app_router.dart`):
```dart
class FeatureRoute extends GoRouteData with $FeatureRoute {
  const FeatureRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const FeatureView(),
    );
  }
}
```

**2. Add to TypedGoRoute annotation** (nested under HomeRoute):
```dart
@TypedGoRoute<HomeRoute>(
  path: '/home',
  routes: [
    // ...existing routes
    TypedGoRoute<FeatureRoute>(path: 'feature_name'),
  ],
)
```

**3. Run codegen:**
```
dart run build_runner build --delete-conflicting-outputs
```

### Passing data ($extra)

Use the `$extra` parameter to pass data to routes:
```dart
class FeatureRoute extends GoRouteData with $FeatureRoute {
  const FeatureRoute({required this.$extra});
  final FeatureConfig $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: FeatureView(config: $extra),
    );
  }
}
```

### Navigation usage

```dart
// Navigate to page
const FeatureRoute().go(context);

// Push onto stack
const FeatureRoute().push(context);

// Navigate with data
FeatureRoute($extra: config).go(context);
```

### Key rules

- Sub-routes are added nested under `HomeRoute`
- Every route class must include `with $RouteName` mixin
- Use `buildPage` override for custom transitions (slide/fade)
- `route_transitions.dart` provides `slideRightTransition` and `fadeTransition`

---

## String Addition

There are two string methods in the project:

### A) Multilingual — EasyLocalization (preferred)

All user-visible text is defined in JSON files under `assets/translations/`.

**Adding a new string (4 steps):**

1. Add key to `assets/translations/tr.json` and `assets/translations/en.json`:
   ```json
   {
     "feature": {
       "title": "Title",
       "description": "Description text"
     }
   }
   ```

2. Regenerate type-safe keys:
   ```bash
   ./script/lang.sh
   ```

   > **Neden script?** Komutta `-s en.json` **zorunludur**. Verilmezse easy_localization kaynak dosyayı alfabetik ilk dosyadan (`tr.json`) seçer ve yalnızca bir dilde bulunan anahtarlar üretilen sınıfın dışında kalır — hata vermeden anahtar düşer. Script bu bayrağı garanti eder; komutu elle yazma.

3. Use in widget:
   ```dart
   import 'package:easy_localization/easy_localization.dart';
   import 'package:akillisletme/product/init/language/locale_keys.g.dart';

   Text(LocaleKeys.feature_title.tr())
   ```

4. Change language:
   ```dart
   context.setLocale(const Locale('en', 'US'));
   ```

**JSON configuration:**

| File | Location |
|------|----------|
| `tr.json` | `assets/translations/tr.json` |
| `en.json` | `assets/translations/en.json` |
| Locale config | `lib/product/init/language/core_localize.dart` |
| Generated keys | `lib/product/init/language/locale_keys.g.dart` |

**Rules:**
- Keys use nested JSON structure: `"feature": { "title": "..." }`
- In the generated file, keys are joined with underscore: `LocaleKeys.feature_title`
- Always add to BOTH language files (TR + EN)
- Run the generate command after adding keys

### B) Constant Strings — AppString

For non-translatable constant values (URLs, store links, technical strings).

```
lib/product/const/app_string.dart
```

```dart
static const String storeUrl = 'https://...';
```
