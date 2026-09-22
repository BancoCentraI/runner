# Data Storage

Detailed usage guide: **`lib/product/cache/CACHE_GUIDE.md`**

## A) Simple data — SharedCache (SharedPreferences)

Use `SharedCache` for settings, flags, and simple string/bool/int values.

```
lib/product/cache/shared_operation/
  shared_cache.dart               # Singleton — high-level getter/setter API
  shared_keys.dart                # Key enum
  base_shared_operation.dart      # Abstract base + implementation
  shared_operation_generic_mixin.dart  # Type-safe generic read/write
```

### Adding a new key

1. Add key to `shared_keys.dart`:
```dart
enum SharedKeys {
  firstAppOpen,
  theme,
  themeVariant,
  newKey,          // <-- add
}
```

2. Add getter/setter to `shared_cache.dart`:
```dart
bool get isNewKey =>
    getValue<bool>(SharedKeys.newKey) ?? false;

Future<void> setNewKey({required bool value}) async {
  await setValue<bool>(SharedKeys.newKey, value);
}
```

3. Usage:
```dart
final value = locator.sharedCache.isNewKey;
await locator.sharedCache.setNewKey(value: true);
```

### Supported types
`bool`, `int`, `double`, `String`, `List<String>`

---

## B) Complex data / Cache — ProductCache (Hive CE)

Use `ProductCache` for model lists, collections, and offline cache.

```
lib/product/cache/
  product_cache.dart                # Main coordinator
  cache_manager.dart                # Abstract interfaces
  hive_v2/
    hive_cache.dart                 # Hive initialization
    hive_operation_manager.dart     # Generic CRUD
    hive_adapters.dart              # @GenerateAdapters
    model/
      app_cache_model.dart          # Example model
```

### Adding a new cache model

1. Create model in `hive_v2/model/` (`CacheModel` mixin + `EquatableMixin` + `@JsonSerializable()`)
2. Add `AdapterSpec<Model>()` to `hive_adapters.dart` (including nested models)
3. Add `late final CacheOperation<Model>` to `product_cache.dart` + add empty constructor to `init()` list
4. Run `dart run build_runner build --delete-conflicting-outputs`

### Usage

```dart
final cache = locator.productCache;

// CRUD
cache.modelCache.add(model);
cache.modelCache.get('id');
cache.modelCache.getAll();
cache.modelCache.update(model);
cache.modelCache.delete(model);
await cache.modelCache.removeAll();
```

---

## Decision table

| Data type | Method | Location |
|-----------|--------|----------|
| Simple key-value (bool, int, String) | SharedCache | `cache/shared_operation/` |
| Settings, flags | SharedCache | `cache/shared_operation/` |
| Model lists, collections | ProductCache (Hive) | `cache/hive_v2/model/` |
| Offline-first cached data | ProductCache (Hive) | `cache/hive_v2/model/` |
