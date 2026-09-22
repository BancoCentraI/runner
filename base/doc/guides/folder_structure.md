# Folder Structure & Module Documentation

Reference: `lib/feature/<any_existing_feature>/` folder.

## Folder Structure

Each feature is created under `lib/feature/<feature_name>/`:

```
lib/feature/<feature_name>/
  <feature_name>_view.dart           # Main view (StatelessWidget)
  <feature_name>_view_model.dart     # (only if StatefulWidget)
  <feature_name>.md                  # Module documentation
  state/
    <feature_name>_cubit.dart        # Cubit (business logic)
    <feature_name>_state.dart        # Freezed state class
  widget/
    <widget_name>.dart               # Extracted sub-widgets
  model/                             # (optional) feature-specific models
  service/                           # (optional) feature-specific services
```

- `state/` -> Cubit + Freezed state
- `widget/` -> Small widgets separated from the view (separate files)
- `model/` -> Only if there are models specific to this feature
- `service/` -> Only if there is a service specific to this feature (see [service_rules.md](service_rules.md))
- `<feature>.md` -> Brief summary of module contents

## Module Documentation (`<feature>.md`)

A `<feature_name>.md` file is added to each feature folder.
This file briefly describes what the module does, the structures it contains, and any notes.

Example:
```markdown
# Home Module

## Summary
Main screen. Game types are listed, recent games are shown.

## Structures
- HomeCubit: Loads and deletes recent games
- HomeState: recentGames, isLoading
- GameTypeCard: Game type card widget
- RecentGameCard: Recent game card widget
```
