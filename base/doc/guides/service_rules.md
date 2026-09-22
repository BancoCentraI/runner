# Service Rules

## Decision tree

1. **Does it exist in locator?** → Check `service_locator.dart`. If yes, use `locator<Service>()`.
2. **Is it a general/shared service?** → Add under `lib/product/service/` + register in locator.
3. **Is it specific to a single module?** → Add under the feature's `service/` folder, do NOT register in locator.

## Adding a shared service

Single file → `lib/product/service/services/<service_name>.dart`
Multiple files → Create `lib/product/service/<service_name>/` folder

Register in locator (`service_locator.dart`):
```dart
// Inside _registerSingletons:
..registerSingleton<NewService>(NewService.instance)

// Inside extension:
NewService get newService => locator<NewService>();
```

## Module-specific service

Added under `service/` in the feature folder. NOT registered in locator.
Only used by that module's Cubit.

```
lib/feature/<feature_name>/
  service/
    <feature>_service.dart
```

## Cache services

Use existing services in locator for cache needs:

| Need | Service | Access |
|------|---------|--------|
| Simple key-value | SharedCache | `locator.sharedCache` |
| Model/list cache | ProductCache | `locator.productCache` |

Details: [data_storage.md](data_storage.md)
