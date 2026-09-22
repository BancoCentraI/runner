# Enums and Constants

## Enums

All enums are placed under `lib/product/enum/`.

```
lib/product/enum/
  game_type.dart
  difficulty_level.dart
  ...
```

Even if an enum is only used by one feature, it goes into `product/enum/` for consistency and discoverability. Before creating a new enum, check if one already exists.

## Constants

All app-wide constants are placed under `lib/product/const/`.

```
lib/product/const/
  app_string.dart      # All UI texts (see route_and_strings.md for the pattern)
  app_constants.dart   # Numeric/config constants
  ...
```

When adding a new constant, first check existing files in this folder to avoid duplication.
