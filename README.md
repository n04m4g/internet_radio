# Internet Radio

A free Flutter internet radio app with a curated station list (Israeli stations and SomaFM), favorites, background playback, and lock-screen / notification controls.

Developed by **Noam Ran**.

## Features

- Curated catalog of **37 stations** (Israel + SomaFM), not a full directory dump
- Stream URLs resolved from [Radio Browser](https://www.radio-browser.info/) and **cached locally for 7 days**
- Favorites
- Background playback with Android media notification and lock-screen controls
- Now Playing screen (station name, homepage, bitrate/codec, and song/program metadata when the stream provides it)
- English and Hebrew UI that follows the device language
- Custom teal radio launcher icon
- Settings:
  - Auto-play last station on launch
  - Stream buffer size (low / normal / high)
  - Clear stream cache
- About section with app version

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK constraint: see `pubspec.yaml`)
- Android Studio / Android SDK for device and emulator builds
- A connected device or emulator with USB debugging enabled

iOS project files are present for future work; Android is the primary target today.

## Getting started

```bash
flutter pub get
flutter run
```

Useful variants:

```bash
# Release APK (split by ABI — smaller install per device)
flutter build apk --release --split-per-abi

# Play Store / upload bundle
flutter build appbundle --release
```

Install a split APK on a phone, for example:

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## How stations work

Station **identity** (name, region, Radio Browser UUID) lives in `lib/data/stations.dart`.

At play time, `StationRepository`:

1. Looks up the pinned Radio Browser UUID
2. Picks a suitable stream (prefer healthy, non-HLS / ICY, higher bitrate, HTTPS)
3. Caches the resolved URL until play fails (or the user refreshes)

That avoids hardcoding fragile stream URLs while still preventing duplicate / wrong-station matches from the directory.

## Release signing (Android)

Release builds use a local keystore when `android/key.properties` is present. Those files are **gitignored** and must never be committed:

| File | Purpose |
|------|---------|
| `android/release-keystore.jks` | Signing keystore |
| `android/key.properties` | Passwords + alias + path for Gradle |
| `android/key.properties.example` | Safe template you *can* commit |

On a new machine, copy your keystore and create `key.properties` from the example. Without them, release builds fall back to the debug key (fine for local testing, not for Play Store).

Generate a keystore (once):

```bash
keytool -genkeypair -v -keystore android/release-keystore.jks -storetype PKCS12 \
  -alias release -keyalg RSA -keysize 2048 -validity 10000
```

Then fill in `android/key.properties` (see the example file). Keep a backup of the `.jks` and passwords in a password manager.

## Project layout

```
lib/
  data/           # Station catalog
  l10n/           # English / Hebrew ARB strings + generated localizations
  models/         # Station, ResolvedStream
  screens/        # Home, Now Playing, Settings
  services/       # Player, Radio Browser, cache, favorites, settings
  widgets/        # Station tiles, now-playing bar
android/          # Android app + signing config
test/             # Widget and matching tests
```

## Tests

```bash
flutter analyze
flutter test
```

## Privacy / permissions

- **Internet** — stream audio and contact Radio Browser
- **Notifications** (Android 13+) — media notification and lock-screen controls
- **Foreground service (media playback)** — keep audio playing in the background

No account, ads, or analytics are included in this project.

## License

This project is licensed under the [MIT License](LICENSE).

Radio station streams and branding belong to their respective broadcasters.
Station metadata is resolved via [Radio Browser](https://www.radio-browser.info/).
