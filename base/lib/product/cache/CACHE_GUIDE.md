# Cache Rehberi

## Hangi Sistemi Kullanmalıyım?

| Veri Tipi | Sistem | Örnek |
|-----------|--------|-------|
| Basit key-value (bool, int, String) | **SharedCache** | Tema seçimi, ilk açılış, ayarlar |
| Karmaşık model / Liste | **ProductCache (Hive)** | Kullanıcı profili, ürün listesi, arama geçmişi |

---

## 1. SharedCache (Basit Veriler)

### Yeni key ekleme

**Adım 1:** `shared_keys.dart`'a key ekle:
```dart
enum SharedKeys {
  firstAppOpen,
  theme,
  themeVariant,
  currentVersion,
  yeniAnahtar,       // <-- ekle
}
```

**Adım 2:** `shared_cache.dart`'a getter/setter ekle:
```dart
// Okuma
bool get isYeniAnahtar =>
    getValue<bool>(SharedKeys.yeniAnahtar) ?? false;

// Yazma
Future<void> setYeniAnahtar({required bool value}) async {
  await setValue<bool>(SharedKeys.yeniAnahtar, value);
}
```

**Adım 3:** Kullanım:
```dart
// Okuma
final deger = locator.sharedCache.isYeniAnahtar;

// Yazma
await locator.sharedCache.setYeniAnahtar(value: true);
```

### Desteklenen tipler
`bool`, `int`, `double`, `String`, `List<String>`

---

## 2. ProductCache / Hive (Karmaşık Modeller)

### Yeni cache modeli ekleme

**Adım 1:** `hive_v2/model/` altında model oluştur:

```dart
// hive_v2/model/urun_cache_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:qrcode_akillisletme/product/cache/cache_manager.dart';

part 'urun_cache_model.g.dart';

@JsonSerializable()
final class UrunCacheModel with CacheModel, EquatableMixin {
  const UrunCacheModel({
    required this.urunId,
    this.ad = '',
    this.fiyat = 0,
  });

  factory UrunCacheModel.fromJson(Map<String, dynamic> json) {
    return _$UrunCacheModelFromJson(json);
  }

  final String urunId;
  final String ad;
  final double fiyat;

  @override
  String get id => urunId;

  @override
  List<Object> get props => [urunId, ad, fiyat];

  @override
  UrunCacheModel fromDynamicJson(dynamic json) {
    if (json is! Map<String, dynamic>) throw Exception('Invalid json type');
    return UrunCacheModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson() => _$UrunCacheModelToJson(this);
}
```

**Adım 2:** `hive_adapters.dart`'a AdapterSpec ekle:

```dart
@GenerateAdapters([
  AdapterSpec<AppCacheModel>(),
  AdapterSpec<UrunCacheModel>(),    // <-- ekle
])
```

> Not: Model içindeki nested objeler de ayrı AdapterSpec gerektirir.

**Adım 3:** `product_cache.dart`'a operation ekle:

```dart
final class ProductCache {
  // ...

  Future<void> init() async {
    await _cacheManager.init([
      const AppCacheModel(),
      const UrunCacheModel(urunId: ''),   // <-- ekle (empty constructor)
    ]);
  }

  late final CacheOperation<AppCacheModel> appModelCache =
      HiveOperationManager<AppCacheModel>();

  late final CacheOperation<UrunCacheModel> urunCache =
      HiveOperationManager<UrunCacheModel>();   // <-- ekle
}
```

**Adım 4:** Build runner çalıştır:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Adım 5:** Kullanım:

```dart
final cache = locator.productCache;

// Ekleme
cache.urunCache.add(
  UrunCacheModel(urunId: '123', ad: 'Kahve', fiyat: 45.0),
);

// Tekil okuma
final urun = cache.urunCache.get('123');

// Tüm listeyi okuma
final tumUrunler = cache.urunCache.getAll();

// Güncelleme
cache.urunCache.update(
  UrunCacheModel(urunId: '123', ad: 'Kahve', fiyat: 50.0),
);

// Silme
cache.urunCache.delete(urun!);

// Tümünü silme
await cache.urunCache.removeAll();
```

---

## Dosya Yapısı

```
lib/product/cache/
├── CACHE_GUIDE.md                      # Bu dosya
├── cache_manager.dart                  # Soyut arayüzler
├── product_cache.dart                  # Ana koordinatör (Hive operation'ları burada)
├── hive_v2/
│   ├── hive_cache.dart                 # Hive başlatma + adapter register
│   ├── hive_operation_manager.dart     # Generic CRUD (add/get/getAll/update/delete)
│   ├── hive_adapters.dart              # @GenerateAdapters listesi
│   ├── hive_adapters.g.dart            # (generated)
│   ├── hive_registrar.g.dart           # (generated)
│   └── model/
│       └── app_cache_model.dart        # Örnek model
└── shared_operation/
    ├── shared_cache.dart               # Singleton — high-level getter/setter API
    ├── base_shared_operation.dart       # Abstract base + SharedOperation impl
    ├── shared_operation_generic_mixin.dart  # Type-safe generic read/write
    └── shared_keys.dart                # Key enum'u
```

## Checklist: Yeni Model Ekleme

- [ ] `hive_v2/model/` altında model dosyası oluştur (`CacheModel` mixin ile)
- [ ] `hive_adapters.dart`'a `AdapterSpec<Model>()` ekle (nested modeller dahil)
- [ ] `product_cache.dart`'a `late final CacheOperation<Model>` ekle
- [ ] `product_cache.dart` `init()` listesine empty constructor ekle
- [ ] `dart run build_runner build --delete-conflicting-outputs` çalıştır
