# Post-Clone Setup Guide (Claude Code Instructions)

This file is written as instructions for Claude Code.
Follow the steps below in order. Ask the user questions and branch based on their answers.

---

## Flow

```
Step 1: Clean old generated files
   ↓
Step 2: flutter pub get
   ↓
Step 3: Ask user → "Enable Firebase integration?"
   ├─ YES → Step 3a: Activate Firebase
   └─ NO  → continue
   ↓
Step 4: build_runner (code-gen)
   ↓
Step 5: EasyLocalization generate
   ↓
Step 6: flutter pub get (again)
   ↓
Step 7: flutter analyze + fix errors
```

> **Shortcut:** if Firebase is not needed, steps 2, 4, 5 and 6 are a single command:
>
> ```bash
> ./script/deep_clean.sh   # cleans generated files, then runs pub get + codegen + lang
> ```
>
> Then jump to Step 7 (`./script/verify.sh`). The manual steps below stay as the
> reference for what each command does and for the Firebase branch.

---

## Step 1: Clean Old Generated Files

The cloned repo may contain old `.g.dart` and `.freezed.dart` files.
These may be incompatible with the current environment and should be deleted first.

```bash
find lib -name "*.g.dart" -delete && find lib -name "*.freezed.dart" -delete
```

---

## Step 2: Install Dependencies

```bash
flutter pub get
```

If errors occur:
- Check Flutter SDK version: `flutter --version`
- Must be compatible with `environment.sdk` in `pubspec.yaml`
- If needed: `flutter pub upgrade`

---

## Step 3: Firebase Question

Ask the user:

> **Do you want to enable Firebase integration?**
> (For version checking via Firebase Remote Config)

### If YES → Go to Step 3a
### If NO → Skip to Step 4

---

## Step 3a: Activate Firebase Integration

Read the `doc/firebase.md` file. It describes which files have which lines
commented out. Remove all comment markers tagged with `// TODO: Firebase kurulduktan sonra`
and activate the original code.

Steps in order:

### 3a.1 — `pubspec.yaml`
Uncomment the Firebase packages:
```yaml
firebase_core: ^latest_version
firebase_remote_config: ^latest_version
```
To get latest versions, check `pub.dev` or write `any` and resolve with `flutter pub get`.

### 3a.2 — `flutter pub get`
Install the newly added Firebase packages:
```bash
flutter pub get
```

### 3a.3 — `lib/product/service/service_locator.dart`
- Uncomment the `RemoteConfigService` import
- Uncomment the `RemoteConfigService` registration in `_registerSingletons()`
- Uncomment the `RemoteConfigService.init()` call in `_initializeServices()`
- Uncomment the `remoteConfigService` getter in `ServiceLocator` extension

### 3a.4 — `lib/feature/login_process/splash/state/splash_cubit.dart`
- Uncomment `package_info_plus` and `RemoteConfigService` imports
- Uncomment `RemoteConfigService` dependency injection in constructor
- Uncomment version check logic in `checkApp()` (remove the temporary `SplashState.success()` line)
- Uncomment the `_isVersionLessThan()` method

### 3a.5 — `lib/product/init/application_init.dart`
- Uncomment the `Firebase.initializeApp()` call

### 3a.6 — `lib/product/navigation/app_router.dart`
- Pass `locator.remoteConfigService` as a parameter when creating `SplashCubit`
- Add the required import

### Important Note
Firebase Console setup (`flutterfire configure`, `google-services.json`, `GoogleService-Info.plist`)
will be done separately by the user. Only activate the code side. Since Firebase is not yet configured,
Firebase-related errors during `flutter analyze` or `flutter run` are expected — IGNORE THEM.

---

## Step 4: Regenerate Code-Gen Files

Generate Freezed, GoRouter, Hive adapter, FlutterGen, and JsonSerializable files with `build_runner`.

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Generated files:**

| File type | Generator |
|-----------|-----------|
| `*.freezed.dart` | Freezed (State classes) |
| `*.g.dart` | GoRouter, JsonSerializable, Hive |
| `assets.gen.dart` | FlutterGen (Asset accessors) |
| `fonts.gen.dart` | FlutterGen (Font constants) |

---

## Step 5: Generate EasyLocalization Keys

Generate the type-safe `LocaleKeys` class from translation files.

```bash
./script/lang.sh
```

**Input:** `assets/translations/tr.json` and `en.json`
**Output:** `lib/product/init/language/locale_keys.g.dart`

> Do not run the underlying `easy_localization:generate` command by hand. It needs
> `-s en.json`; without it the source file defaults to the alphabetically first one
> (`tr.json`) and any key present in only one language is dropped from the generated
> class — silently, with no error.

---

## Step 6: Reinstall Dependencies

For a clean dependency resolution after generated files:

```bash
flutter pub get
```

---

## Step 7: Error Analysis and Fixing

```bash
./script/verify.sh    # dart format → flutter analyze → flutter test
```

### Rules

1. If NO errors → tell the user "Project is ready, you can run it with `flutter run`".
2. If errors exist → fix according to the table below:

| Error | Cause | Solution |
|-------|-------|----------|
| `Target URI doesn't exist` (*.g.dart) | Generated file missing | Re-run Step 4 |
| `Target URI doesn't exist` (locale_keys) | EasyLocalization generate missing | Re-run Step 5 |
| `Undefined class 'Assets'` | FlutterGen file missing | Re-run Step 4 |
| `The method '...' isn't defined` | Freezed output missing | Re-run Step 4 |
| `Could not resolve...` | Package not installed | Re-run `flutter pub get` |
| Firebase-related errors | Firebase not yet configured | **IGNORE** (user will handle) |

3. After fixing non-Firebase errors, run `flutter analyze` again.
4. Repeat until clean output (excluding Firebase errors).

---

## Project Customization

After setup is complete, follow the customization checklist in
`doc/guides/project.md` under the **"New Project Setup (Customization)"** section.
