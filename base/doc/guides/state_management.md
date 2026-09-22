# State Management (Cubit + Freezed)

## State file (`<feature>_state.dart`)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '<feature>_state.freezed.dart';

@freezed
abstract class <Feature>State with _$<Feature>State {
  const factory <Feature>State({
    @Default(false) bool isLoading,
    // other fields...
  }) = _<Feature>State;
}
```

## Cubit file (`<feature>_cubit.dart`)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class <Feature>Cubit extends Cubit<<Feature>State> {
  <Feature>Cubit({required SomeService service})
      : _service = service,
        super(const <Feature>State());

  final SomeService _service;
}
```

- Services are received via constructor injection
- State is updated with `emit(state.copyWith(...))`
- Codegen: `dart run build_runner build --delete-conflicting-outputs`

## BlocProvider Strategy

Where the Cubit is provided is determined by priority:

### A) Global (at app startup) -> `lib/product/init/state_initialize.dart`

Cubits that live throughout the app lifecycle, are accessed by multiple screens, or need to be initialized early.

```dart
// Inside state_initialize.dart -> MultiBlocProvider:
BlocProvider(
  create: (context) => <Feature>Cubit(
    service: locator.someService,
  )..loadData(),
),
```

Example global cubits: `ThemeCubit`, `AuthCubit`, `HomeCubit` (varies per project)

### B) Local (at feature level) -> Inside the view file

Cubits that only live while the screen is open and are disposed when the screen closes.
Wrapped with BlocProvider in the view's build method.

```dart
class <Feature>View extends StatelessWidget {
  const <Feature>View({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => <Feature>Cubit(
        service: locator.someService,
      )..initialize(),
      child: const _<Feature>Content(),
    );
  }
}
```

### App-wide state (product/state)

If a Cubit/Bloc integration affects the **entire app** (not just one feature), it is placed under `lib/product/state/` instead of a feature folder.

```
lib/product/state/
  theme_cubit.dart
  theme_state.dart
  ...
```

Examples: `ThemeCubit` (controls app-wide theme), `AuthCubit` (global auth state). These are always registered globally in `state_initialize.dart`.

### When to use which?

| Scenario | Preference |
|---|---|
| Multiple screens access it | Global (state_initialize) |
| Data must be loaded at app startup | Global (state_initialize) |
| Affects the entire app (theme, auth, etc.) | `product/state/` + Global |
| Belongs to a single screen only | Local (BlocProvider in view) |
| State is unnecessary after screen closes | Local (BlocProvider in view) |
