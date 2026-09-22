# Assets and FlutterGen

## Overview

Project uses **flutter_gen** for type-safe asset access. Assets are generated into `lib/product/generated/`.

Generated files:
- `assets.gen.dart` — Image, SVG, Lottie, translations
- `fonts.gen.dart` — Font family constants

## Asset folder structure

```
assets/
  image/       → PNG, JPG, WebP, etc.
  svg/         → SVG files
  lottie/      → Lottie JSON animations
  songs/       → Audio files
  translations/→ i18n JSON files (tr.json, en.json)
  font/        → Font files (Poppins, Inter)
```

## Adding a new asset

### 1. Place the file in the correct folder

| Asset type | Folder | Example |
|---|---|---|
| PNG / JPG image | `assets/image/` | `assets/image/logo.png` |
| SVG icon/image | `assets/svg/` | `assets/svg/star.svg` |
| Lottie animation | `assets/lottie/` | `assets/lottie/loading.json` |
| Audio file | `assets/songs/` | `assets/songs/click.mp3` |

### 2. Run code generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

This regenerates `lib/product/generated/assets.gen.dart`.

### 3. Use the generated asset

```dart
import 'package:akillisletme/product/generated/assets.gen.dart';

// --- Image ---
Assets.image.logo.image(width: 100, height: 100)
// or as ImageProvider:
Assets.image.logo.provider()

// --- SVG ---
Assets.svg.star.svg(width: 24, height: 24)
// with color filter:
Assets.svg.star.svg(
  colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
)

// --- Lottie ---
Assets.lottie.loading.lottie(width: 200, height: 200)
// with controller:
Assets.lottie.loading.lottie(
  controller: animationController,
  repeat: true,
)

// --- Font ---
import 'package:akillisletme/product/generated/fonts.gen.dart';

TextStyle(fontFamily: FontFamily.poppins)
TextStyle(fontFamily: FontFamily.inter)

// --- Path string (if needed) ---
Assets.image.logo.path  // 'assets/image/logo.png'
Assets.svg.star.path    // 'assets/svg/star.svg'
```

## Why use FlutterGen?

| Without FlutterGen | With FlutterGen |
|---|---|
| `Image.asset('assets/image/logo.png')` | `Assets.image.logo.image()` |
| `SvgPicture.asset('assets/svg/star.svg')` | `Assets.svg.star.svg()` |
| `Lottie.asset('assets/lottie/loading.json')` | `Assets.lottie.loading.lottie()` |
| Typo in path → runtime crash | Typo → compile-time error |
| No autocomplete | Full IDE autocomplete |

## Configuration (pubspec.yaml)

```yaml
flutter_gen:
  output: lib/product/generated/
  integrations:
    lottie: true
    flutter_svg: true
```

## Rules

- **Never use hardcoded asset paths** — always use `Assets.xxx` generated accessors
- **Never use hardcoded font family strings** — always use `FontFamily.xxx`
- After adding/removing/renaming any asset file, **always run build_runner**
- Generated files (`lib/product/generated/`) are auto-generated — do not edit manually
