# Language Selection Module

## Summary
Shared language selection UI supporting 14 languages. Used in both Onboarding Step 1 (embedded grid) and Settings (standalone page with navigation).

## Structures
- LanguageSelectionView: Standalone page with AppBar, subtitle, and language grid
- LanguageGridContent: Reusable GridView of LanguageCard widgets (shared between onboarding and settings)
- LanguageCard: Individual card widget showing flag emoji, native name, and selection state
- LanguageItem: Data model in `product/init/language/language_item.dart` holding flag, nativeName, and AppLocale

## Navigation
- From Settings: `const LanguageSelectionRoute().push<void>(context)` → `/settings/language`
- In Onboarding: `LanguageGridContent` widget embedded directly in Step 1
