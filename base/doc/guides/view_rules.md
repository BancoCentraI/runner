# View Rules

## A) StatelessWidget (default preference)

For screens where state is listened to via BlocBuilder and no lifecycle management is needed.

```dart
class <Feature>View extends StatelessWidget {
  const <Feature>View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

Reference: `lib/feature/settings/settings_view.dart`

## B) StatefulWidget + ViewModel

For screens that require lifecycle management (initState, dispose), AnimationController,
TextEditingController, ScrollController, PageController, etc.

**2 files are created:**

`<feature>_view.dart`:
```dart
import '<feature>_view_model.dart';

class <Feature>View extends StatefulWidget {
  const <Feature>View({super.key});

  @override
  State<<Feature>View> createState() => _<Feature>ViewState();
}

class _<Feature>ViewState extends <Feature>ViewModel {
  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

`<feature>_view_model.dart`:
```dart
import '<feature>_view.dart';

abstract class <Feature>ViewModel extends State<<Feature>View> {
  // Controllers, lifecycle methods, helper functions go here

  @override
  void initState() {
    super.initState();
    // Initialize controllers here
  }

  @override
  void dispose() {
    // Dispose controllers here
    super.dispose();
  }
}
```

Reference implementations:
- `lib/feature/home/home_view.dart` + `home_view_mode.dart` (HomeView + HomeViewMode)
- `lib/feature/login_process/onboarding/onboarding_view.dart` + `onboarding_view_model.dart` (OnboardingView + OnboardingViewModel)

## When to use which?

| Scenario | Preference |
|---|---|
| Only Bloc/Cubit state is sufficient | StatelessWidget |
| AnimationController, TickerProvider | StatefulWidget + ViewModel |
| TextEditingController, FocusNode | StatefulWidget + ViewModel |
| PageController, ScrollController | StatefulWidget + ViewModel |
| Operations requiring initState/dispose | StatefulWidget + ViewModel |

## Common view rules (for both types)

- **Responsive**: Check `isWide` with `MediaQuery.sizeOf(context).width > 600`
- **Padding**: Use `AppPaddings` constants from `lib/product/const/app_paddings.dart` (not hardcoded values)
  - `AppPaddings.allXxl` -> `EdgeInsets.all(24)`
  - `AppPaddings.page` -> `EdgeInsets.symmetric(horizontal: 16, vertical: 8)`
  - Responsive padding: `context.r(AppPaddings.l)` for scaled values
- **Spacing**: Use `Column(spacing: 16, ...)` parameter (not SizedBox)
- **Strings**: Translatable text uses `LocaleKeys.<key>.tr()`, constants use `AppString`
- **Theme**: Use `Theme.of(context).colorScheme` and `textTheme`, no hardcoded colors
- **Navigation**: Type-safe routes with `const FeatureRoute().go(context)` (see [route_and_strings.md](route_and_strings.md))
