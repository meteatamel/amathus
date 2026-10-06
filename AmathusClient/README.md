# Amathus Client (Kuzey Kıbrıs Haber)

Cross-platform Flutter client (Web, Android, iOS, macOS) for Amathus, upgraded to **Flutter 3.41 / Dart 3.11** with Material 3 design.

## Prerequisites

- Flutter SDK `>=3.41.0` (Dart `>=3.0.0 <4.0.0`)

## Local Development & Testing

Install dependencies:

```sh
flutter pub get
```

Run static analysis and widget tests:

```sh
flutter analyze
flutter test
```

### Run Locally on Web (Chrome)

```sh
flutter run -d chrome
```

### Run Locally on macOS Desktop

```sh
flutter run -d macos
```

### Run Locally on Android / iOS Emulator

List and launch an emulator:

```sh
flutter emulators
flutter emulators --launch <your-emulator-id>
flutter run -d <your-emulator-id>
```

---

## Build Release Bundles

### Web

```sh
flutter build web --release
```

### Android / iOS

```sh
flutter build apk --debug
flutter build ios --debug
```

---

## Deploy Flutter Web Frontend to Google Cloud Run

A deployment script [`scripts/deploy_web`](./scripts/deploy_web) and [`Dockerfile`](./Dockerfile) (Nginx on port `8080`) are provided to build the Flutter Web release bundle and deploy it to Cloud Run (`amathus-client` in project `events-atamel`, region `europe-west1`):

```sh
./scripts/deploy_web
```
