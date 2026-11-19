# SkinSight – Android Face Detection Release Crash Patch

## Why this patch

The screenshot's exception occurs during Google ML Kit `FaceDetector.processImage()` and its message matches a reported Android release-only failure. One proposed cause is R8 shrinking/obfuscation removing or renaming ML Kit classes that are accessed reflectively. This patch adds keep rules for the ML Kit Face Detection implementation.

This is a targeted fix to test, not a guarantee: the uploaded `lib(10).zip` contains Dart `lib/` only, not the actual Android Gradle configuration or a release mapping/logcat trace. If the crash remains with minification disabled, investigate the native ML Kit dependency/device environment next.

## 1. Copy the rules file

Copy this file:

`proguard-rules.pro`

to your Flutter project at:

`android/app/proguard-rules.pro`

Do not put it in `android/` root or inside `lib/`.

## 2. Connect it to the Release build

Open the ONE file your project uses:

- `android/app/build.gradle.kts` → use `build.gradle.kts.release-snippet.txt`
- `android/app/build.gradle` → use `build.gradle.groovy.release-snippet.txt`

Merge only the `proguardFiles(...)` / `proguardFiles ...` line into the existing `release` block under `android { buildTypes { ... } }`.

Do not replace the whole `buildTypes` block. Preserve existing signing configuration and other options. Do not turn minification on just to use these rules; if minification is currently off, the keep rules do not change the behavior of R8.

## 3. Diagnostic test (important)

Before testing the keep rules, you can isolate whether R8 is the cause:

In the existing `release` block, temporarily set:

Kotlin DSL:

`isMinifyEnabled = false`

`isShrinkResources = false`

Groovy:

`minifyEnabled false`

`shrinkResources false`

Build and install a fresh Release APK. If Face Detection now works, that strongly supports an R8/minification cause. Then restore your previous minification settings, add the keep rules above, and test again.

If it still crashes with minification disabled, this is not fixed by ProGuard rules alone. Capture the complete `adb logcat` exception and inspect the resolved native ML Kit dependency version before changing Dart code or upgrading packages.

## 4. Clean and rebuild

From the Flutter project root (the directory containing `pubspec.yaml`):

```bash
flutter clean
flutter pub get
flutter build apk --release
```

Install the newly generated APK; do not test an older APK already copied to the phone.

## 5. What this patch does not change

- No Dart files or SkinSight scan logic are changed.
- Face Detection still happens before Face ROI cropping and YOLO LiteRT inference.
- Acne / PIH / Dark Circle confidence threshold remains 0.05 in the uploaded analyzer.
- Dummy skin type remains unchanged.

## Evidence / limitation

The stack trace shared by the user is highly similar to this report and its suggested R8 keep-rule remedy:
https://stackoverflow.com/questions/79966859/google-mlkit-face-detection-facedetector-processimage-crashes-only-in-android

The ML Kit Flutter package documentation confirms that `processImage()` crosses a Flutter platform channel and executes the native ML Kit API, so a native `PlatformException` at this step is not caused by YOLO tensor decoding:
https://pub.dev/documentation/google_mlkit_face_detection/latest/

The actual Gradle file was not included in `lib(10).zip`; therefore this patch supplies safe snippets rather than overwriting a build configuration that has not been inspected.
