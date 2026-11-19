# SkinSight on-device ML integration

## Main files added/changed

- `lib/features/scan/data/skin_on_device_analyzer.dart` — ML Kit face detection, largest-face selection, upright-image normalization, Face ROI crop with 12% context, letterbox/preprocessing, three LiteRT runtimes, YOLO detection/segmentation post-processing, and `SkinAnalysis` output.
- `lib/features/scan/presentation/skin_scan_page.dart` — ordinary scan runs on-device inference; return-photo mode returns bytes to the caller for inference there.
- `lib/features/scan/presentation/skin_initial_scan_page.dart` — each initial baseline photo is analyzed on-device.
- `lib/features/journeys/presentation/skin_journey_photos_page.dart` — each weekly check-in photo is analyzed on-device.
- `lib/features/journeys/data/skin_journey_store.dart` — `stageAnalysis` stores actual inference output, without demo visual findings.
- `lib/features/scan/presentation/skin_result_page.dart` — no automatic fake visual-result fallback.

## Model assets

- `assets/ml_models/acne_pih_darkcircle_float32.tflite`
- `assets/ml_models/redness_float32.tflite`
- `assets/ml_models/wrinkle_float32.tflite`
- `assets/ml_models/conversion_manifest.json`

## Face ROI and confidence configuration

- Google ML Kit Face Detection runs first on an EXIF-normalized upright JPEG.
- The largest detected face is selected when there are multiple faces.
- The model receives only the selected face crop plus 12% context padding; the original full-frame photo is not passed to YOLO.
- Acne / PIH / Dark Circle detection threshold: `0.05` (lowest value offered by the original prototype slider).
- Redness / Wrinkle segmentation threshold: `0.25` (prototype default).
- Skin type remains dummy: `Dry`, confidence `0.86`. No dummy visual counts, mask areas, or visual confidence values are used by the on-device analyzer.

## Static checks performed

- ZIP integrity checked.
- Model SHA-256 values match the supplied conversion manifest.
- All declared model input/output shapes in Dart match the supplied conversion manifest.
- Relative Dart imports checked for missing local files.
- Active ordinary scan, initial baseline scan, and weekly Journey photo flow call `SkinOnDeviceAnalyzer`.
- No backend URL, FastAPI, or Cloudflare Tunnel is required for scan inference.

## Not verified here

The uploads did not include the complete Flutter project (`pubspec.yaml`, `android/`, Gradle files), and Flutter/Dart CLI is not installed in this build environment. Therefore `flutter analyze`, Android APK build, runtime face detection, and real-device inference have not been executed here. They must be run in the complete project on an Android device.
