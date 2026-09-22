# Model Rules

The model folder is optional, but if a model needs to be created, follow these rules for consistency.

## Feature-specific model

Written with Freezed + manual `toMap()`/`fromMap()` (for Hive serialization).

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '<model>_name.freezed.dart';

@freezed
abstract class <Model>Name with _$<Model>Name {
  const factory <Model>Name({
    required int id,
    @Default(0) int score,
  }) = _<Model>Name;

  const <Model>Name._(); // Required for toMap/fromMap

  Map<String, dynamic> toMap() {
    return {'id': id, 'score': score};
  }

  static <Model>Name fromMap(Map<String, dynamic> map) {
    return <Model>Name(
      id: map['id'] as int,
      score: map['score'] as int? ?? 0,
    );
  }
}
```

## Model to be saved in Hive (product/model)

Models shared across the app and written to Hive are placed under `lib/product/model/`,
written with `@HiveType` + `@HiveField`. Freezed is not used, `toMap()`/`fromMap()` are added.

## Summary

| Scenario | Method | Location |
|---|---|---|
| Feature-specific, not saved to Hive | Freezed + toMap/fromMap | `feature/model/` |
| Feature-specific, saved to Hive | @HiveType + toMap/fromMap | `product/model/` |
| Simple data used only within state | Freezed (toMap not needed) | `feature/model/` |
