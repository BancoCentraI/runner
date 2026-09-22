# Native Splash Screen — AVD Animation

## Overview

The project uses `androidx.core:core-splashscreen` to show an animated splash screen before the Flutter engine starts. The animation is an **Animated Vector Drawable (AVD)** — a pure XML file, no third-party packages.

This prevents the black screen on cold start: the system immediately renders `windowSplashScreenBackground` from `LaunchTheme`, then plays the AVD animation, then hands off to Flutter.

Supports Android 12+ natively, API 23+ via compat layer.

---

## Key Files — Always Edit These When Changing the Splash

| File | What It Controls |
|------|-----------------|
| `android/app/src/main/res/drawable/avd_anim.xml` | The animation itself (shape, motion, duration) |
| `android/app/src/main/res/values/styles.xml` | Background color (light mode), animation duration |
| `android/app/src/main/res/values-night/styles.xml` | Background color (dark mode) |
| `android/app/src/main/kotlin/.../MainActivity.kt` | `installSplashScreen()` — must stay before `super.onCreate()` |
| `android/app/build.gradle.kts` | `core-splashscreen:1.0.1` dependency |

---

## How to Change the Background Color

Edit `windowSplashScreenBackground` in both style files:

`res/values/styles.xml` (light):
```xml
<item name="windowSplashScreenBackground">#FFFFFF</item>
```

`res/values-night/styles.xml` (dark):
```xml
<item name="windowSplashScreenBackground">#000000</item>
```

---

## How to Change the Logo Size

The Android 12 SplashScreen API clips the icon inside a circle. If the logo edges are cut off, reduce `valueTo` in `avd_anim.xml`. Both `scaleX` and `scaleY` must match.

```xml
<!-- In avd_anim.xml → inside the <set> block -->
<objectAnimator android:propertyName="scaleX" android:valueTo="0.7" ... />
<objectAnimator android:propertyName="scaleY" android:valueTo="0.7" ... />
```

Safe range: `0.5` – `0.85`. Current value: `0.7`.

---

## How to Change the Animation Duration

Two places must stay in sync:

1. `res/values/styles.xml` and `res/values-night/styles.xml`:
```xml
<item name="windowSplashScreenAnimationDuration">400</item>
```

2. `android:duration` on every `<objectAnimator>` inside `avd_anim.xml`:
```xml
android:duration="400"
```

Max recommended value: `1000` ms.

---

## How to Replace the Animation with a New One

The user needs to create a new AVD file. The tool for this is **Shape Shifter**:
**https://shapeshifter.design**

### Guide to give the user:

1. Go to https://shapeshifter.design and drag in an SVG file
2. In the left panel, right-click the `path` layer → **Group** → a `group` layer wraps the path
3. Click the `group` layer itself (not a property) → set `pivotX` and `pivotY` to half the canvas size
   - Example: canvas is 128×128 → `pivotX: 64`, `pivotY: 64`
   - Canvas size is visible in the top-left of the editor when `vector` is selected
4. Add animations by clicking the clock icon next to each property on the `group`:
   - `scaleX` / `scaleY`: `fromValue: 0`, `toValue: 0.7`, `endTime: 400`
   - `translateY`: `fromValue: 150`, `toValue: 0`, `endTime: 400` (enter from bottom)
   - Interpolator: **Fast out, slow in** for all
5. Press play to preview
6. **File → Export → Animated Vector Drawable**
7. Replace `android/app/src/main/res/drawable/avd_anim.xml` with the exported file

> Note: `pivotX` and `pivotY` are static values on the `group` layer — do NOT add them as keyframe animations. Click the group layer itself and type directly into the input fields.

---

## AVD File Structure Reference

```xml
<animated-vector>
  <aapt:attr name="android:drawable">
    <vector width="128dp" height="128dp" viewportWidth="128" viewportHeight="128">
      <group name="group" pivotX="64" pivotY="64">
        <path pathData="..." fillColor="#000" />
      </group>
    </vector>
  </aapt:attr>

  <target name="group">
    <aapt:attr name="android:animation">
      <set>
        <objectAnimator propertyName="translateY" valueFrom="150" valueTo="0"   duration="400" />
        <objectAnimator propertyName="scaleX"     valueFrom="0"   valueTo="0.7" duration="400" />
        <objectAnimator propertyName="scaleY"     valueFrom="0"   valueTo="0.7" duration="400" />
      </set>
    </aapt:attr>
  </target>
</animated-vector>
```

---

## Alternative: flutter_native_splash Package

If the user wants a **static image** splash (no custom animation), they can use `flutter_native_splash` instead. It auto-generates all the XML files.

> **Warning:** `flutter_native_splash:create` overwrites `res/values/styles.xml` and modifies `MainActivity.kt`. It will break the existing AVD setup. Do not use both at the same time.

### Setup if the user chooses this path:

1. Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.0
```

2. Create `flutter_native_splash.yaml` in the project root:
```yaml
flutter_native_splash:
  color: "#FFFFFF"
  color_dark: "#000000"
  image: assets/image/splash_logo.png
  android_12:
    color: "#FFFFFF"
    color_dark: "#000000"
    image: assets/image/splash_logo.png
    # To keep AVD animation on Android 12+:
    # android12_icon: "@drawable/avd_anim"
```

3. Run:
```bash
dart run flutter_native_splash:create
```
