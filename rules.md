# Development Rules

The following guidelines govern the development of the Daily Routine app.

## 1. Incremental Development
- Build the application in strict phases. Do not implement features (like notifications or databases) before their scheduled phase.

## 2. Reusability
- Do **not** hard-code activities as separate systems. All activities must inherit from or utilize the generic `Activity` model.

## 3. State & Timer Accuracy
- Never rely on continuously running background loops for timers.
- Always use timestamp-based logic for calculations involving time passing to ensure accuracy across app lifecycle changes.

## 4. Testing
- Every controller or business logic class must have comprehensive unit tests.
- Complex UI screens (like the `MeditationScreen`) must have widget tests covering all user interaction paths.
- Avoid introducing third-party packages until strictly necessary (e.g., use `package:test` and `flutter_test` before adding mocking libraries if possible).

## 5. Build Environment
- Monitor the Gradle build environment. Lock the `gradle-wrapper.properties` to a known stable version that complies with the current AGP and Java versions.
