# Widget and Theme Rules

## Decision tree

1. **Check `product/widget/`.** Is there an existing shared widget used across the app?
2. **If it exists, use it.** Do not create a new widget.
3. **If it doesn't exist and will be used across the app** → Add it under `lib/product/widget/`.
4. **If it's a widget specific only to this feature** → Add it under `lib/feature/<feature>/widget/`.

## Theme / Style

1. **Check `product/theme/parts/`.** Button theme, card theme, etc. are already defined app-wide.
   (Example: `button_theme.dart` → Global styles for ElevatedButton, FilledButton)
2. **If the global theme is sufficient** → Do not add extra styles, the theme is applied automatically.
3. **If a specific/different design is needed** → Override the style in the feature's `widget/` folder.

## TextTheme Usage

Inline `TextStyle(fontSize: ...)` is **not allowed**. All text styles are defined in `text_theme.dart` and accessed via `Theme.of(context).textTheme.*`.

```dart
// Correct — get from TextTheme
Text('Title', style: Theme.of(context).textTheme.headlineSmall)

// If customization is needed, use copyWith
Text(
  'Title',
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.bold,
    color: cs.onSurface,
  ),
)

// Wrong — do not use inline fontSize
Text('Title', style: TextStyle(fontSize: 24))
```

### Common TextTheme styles

| Style | Size | Usage |
|-------|------|-------|
| `headlineSmall` | 24 | Page/dialog large titles |
| `titleLarge` | 22 | Card/tile titles |
| `titleMedium` | 16 | Button labels, dialog titles |
| `titleSmall` | 14 | Small titles |
| `labelMedium` | 12 | Section titles, segment labels |
| `labelSmall` | 11 | Chip/badge text |
| `bodyLarge` | 16 | Main content text |
| `bodyMedium` | 14 | General text, descriptions |
| `bodySmall` | 12 | Helper text, captions |

Full list: see `lib/product/theme/THEME.md`

## Semantic Colors (AppThemeColors)

Use `AppThemeColors` for variant-independent, dark/light-aware fixed colors.

```dart
import 'package:akillisletme/product/theme/app_theme_colors.dart';

// Short access (recommended)
context.appColors.scoreGold
context.appColors.toggleActive

// Color access priority:
// 1. Theme colorScheme → Theme.of(context).colorScheme.primary
// 2. Semantic colors → context.appColors.scoreGold
// 3. NEVER use inline colors
```

## Existing shared widgets

| Widget | Location | Usage |
|--------|----------|-------|
| `AppPrimaryButton` | `product/widget/` | Primary action button (FilledButton, haptic feedback) |
| `AppSecondaryButton` | `product/widget/` | Secondary action button (OutlinedButton, haptic feedback) |
| `AppTextButton` | `product/widget/` | Light text button (TextButton, haptic feedback) |
| `AppScaffold` | `product/widget/` | Page shell — padding + SafeArea + keyboard dismiss |
| `AppTextField` | `product/widget/` | Typed input, see [forms_and_validation.md](forms_and_validation.md) |
| `KeyboardDismisser` | `product/widget/` | Tap outside to close the keyboard |
| `AppSemantics` | `product/widget/` | UI-test identifier, see [testing.md](testing.md) |
| `AppStateView` and friends | `product/widget/state/` | Four screen states, see [ui_states.md](ui_states.md) |
| `AppSelectSheet` | `product/widget/sheet/` | Generic single-select bottom sheet |
| `AppErrorSheet` | `product/widget/sheet/` | Blocking error + retry sheet |
| `ThemeSettingTile` | `product/theme/widget/` | Theme selection tile (gradient card) |
| `SettingsSection` | `feature/settings/widget/` | Settings group card |
| `BackgroundAnimationTile` | `feature/settings/widget/` | Background animation on/off switch |

## Existing shared utilities

| Utility | Location | Usage |
|---------|----------|-------|
| `AppPaddings` | `product/const/app_paddings.dart` | Padding/spacing constants — no hardcoded values |
| `AppMessenger` | `product/utils/app_messenger.dart` | SnackBar, Dialog, BottomSheet — context extension |

### AppPaddings usage

Use `AppPaddings` instead of hardcoded `EdgeInsets.all(24)`:

```dart
// Predefined EdgeInsets
padding: AppPaddings.allXxl            // EdgeInsets.all(24)
padding: AppPaddings.page              // horizontal: 16, vertical: 8
padding: AppPaddings.horizontalL       // horizontal: 16

// As double value
SizedBox(height: AppPaddings.m)        // 12
```

### AppMessenger usage

Use `AppMessenger` extension for user feedback:

```dart
// SnackBar
context.showSuccessSnack('Saved!');
context.showErrorSnack('An error occurred');
context.showInfoSnack('Information');

// Confirmation dialog (returns true/false)
final confirmed = await context.showConfirmDialog(
  title: 'Are you sure you want to delete?',
  message: 'This action cannot be undone.',
  isDestructive: true,  // red button
);

// Bottom sheet
context.showAppBottomSheet<void>(child: MyContentWidget());
```

## General widget rules

- Every repeated or complex UI piece is extracted into a separate file under `widget/`
- Widgets use `final` parameters with `const` constructors
- Callbacks are received via `VoidCallback` or `ValueChanged<T>`
- Do not use inline `TextStyle(fontSize: ...)` — use `Theme.of(context).textTheme.*`
- Do not use inline colors — use `colorScheme.*` or `context.appColors.*`
