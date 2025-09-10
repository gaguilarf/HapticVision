
<!-- Technologies badges -->
<p align="center">
	<a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/></a>
	<a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/></a>
	<a href="https://www.tensorflow.org/lite"><img src="https://img.shields.io/badge/TensorFlow--Lite-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white" alt="TFLite"/></a>
	<a href="https://pub.dev/packages/camera"><img src="https://img.shields.io/badge/Camera-plugin-4A90E2?style=for-the-badge&logo=android&logoColor=white" alt="camera"/></a>
	<a href="https://pub.dev/packages/tflite_flutter"><img src="https://img.shields.io/badge/tflite__flutter-2AA6FF?style=for-the-badge&logo=google&logoColor=white" alt="tflite_flutter"/></a>
	<a href="https://pub.dev/packages/flutter_tts"><img src="https://img.shields.io/badge/flutter__tts-6A1B9A?style=for-the-badge&logo=soundcloud&logoColor=white" alt="flutter_tts"/></a>
	<a href="https://pub.dev/packages/vibration"><img src="https://img.shields.io/badge/Vibration-00C853?style=for-the-badge&logo=google&logoColor=white" alt="vibration"/></a>
	<a href="https://developer.android.com"><img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android"/></a>
	<a href="https://developer.apple.com"><img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white" alt="iOS"/></a>
</p>

## HapticVision

HapticVision is a Flutter mobile app that uses the device camera and a
pre-trained on-device model to detect user emotions in real time. The app
translates detected emotions into haptic feedback (vibration) or spoken
notifications (TTS). The codebase follows a Clean Architecture layout (core,
features/<feature>/{data,domain,presentation}) to keep concerns separated and
tests easy to add.

---

## Features (planned / scaffolded)

- camera
	- Camera preview and real-time emotion detection using a local TFLite model.
	- Maps detected emotion to configured feedback (vibration or TTS).
- configuraciones
	- Manage user preferences: enable/disable vibration, enable/disable TTS,
		select camera (front/back), detection frequency, and persistence of
		preferences.

Notes: an `example_feature` scaffold was created earlier during setup and is
kept only for reference; production code will use the two features above.

---

## Supported Emotions

The model will detect the following 4 emotions (labels must match your
pre-trained model):

1. neutral
2. happy
3. sad
4. angry

Default haptic mapping (configurable in `configuraciones`):

- neutral: single short vibration (1 pulse)
- happy: two short vibrations (2 pulses)
- sad: two short vibrations (2 pulses)
- angry: one long vibration (~2 seconds)

You can choose between vibration only, TTS only, or both. TTS will use the
platform TTS engine unless a custom engine is added.

---

## Design decisions and assumptions

- The model runs on-device (TensorFlow Lite) to avoid latency and cloud costs.
- Camera frames will be sampled at a configurable rate to balance CPU usage and
	responsiveness. Default will be a moderate rate (e.g., 6–10 inferences per
	second) with an option to lower it on low-end devices.
- Images are not uploaded to any server by default. If cloud inference is
	desired later, it will be added as an opt-in configuration and documented.
- Permissions for camera and vibration/TTS will be requested at runtime and
	documented in platform-specific files (AndroidManifest / Info.plist).

---

## Local model integration (notes)

- Place your TensorFlow Lite model file(s) under `assets/models/` and declare
	them in `pubspec.yaml`.
- Recommended Flutter packages:
	- `camera` for camera preview and frame access
	- `tflite_flutter` (or `flutter_tflite`) for running TFLite inference on
		device
	- `vibration` or `flutter_vibration` for haptic patterns
	- `flutter_tts` for text-to-speech

Implementation outline:

1. Create a repository interface in the `domain` layer to request emotion
	 predictions from an input image.
2. Implement the repository in `data` using `tflite_flutter` and the device
	 camera frames.
3. Create a `DetectEmotion` use-case that returns a domain `Emotion` entity.
4. Presentation layer handles camera UI and routes predictions to configured
	 outputs (vibration/TTS).

---

## Privacy and permissions

- The app is designed to run fully on-device; user images and video frames are
	not sent to external servers by default. This must be prominently displayed
	in the app's privacy policy and UX when requesting camera permission.

---

## How to clone and run (developer setup)

Prerequisites:

- Flutter SDK installed (stable channel). See https://flutter.dev/docs/get-started/install
- Android SDK / Xcode (for iOS) set up for device or emulator testing

Clone the repository:

```powershell
git clone https://github.com/gaguilarf/HapticVision.git
cd HapticVision
```

Install dependencies and run:

```powershell
flutter pub get
flutter run
```

Platform specifics:

- Android: add camera and vibration permissions to `android/app/src/main/AndroidManifest.xml`.
- iOS: add camera usage and microphone (if TTS requires it) to `ios/Runner/Info.plist`.

---

## Next steps (recommended)

1. Add your TFLite model file to `assets/models/` and update `pubspec.yaml`.
2. Implement repository + use-case scaffolds in `features/main` and
	 `features/configuraciones` domain/data layers.
3. Wire camera frames to the model and implement the vibration / TTS output
	 handlers in the presentation layer.
4. Add unit tests for the `domain` layer and integration tests for the
	 presentation flows.

---

If you want, I can now:

- Remove the `example_feature` scaffold.
- Create skeleton interfaces and example files for each feature (no full
	implementation yet).
- Add `assets/models/` and update `pubspec.yaml` to include it.

Tell me which of the above you want me to do next.
