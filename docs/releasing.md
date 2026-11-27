# Releasing

Release notes, store builds, icons and versions.

## Release notes

- Release notes live in `assets/changelog/changelog.json`, newest release first, each change typed `new`, `improved` or `fixed` and written in all four languages. The app's What's New screen shows only the newest release (and check for updates); the website's changelog page lists every release. Both read the same JSON, so it is the one place user-facing text skips the ARB files. When a commit changes what users see, add a line to the top release. The top release's version must match `version:` in `pubspec.yaml` (a test checks this); its `date` stays `null` until it ships. Give a change `platforms` (`android`, `ios`, `macos`, `windows`, `linux`, `web`) when it doesn't reach every app platform, a short `store` text in all four languages when Play's 500-character limit needs it, and an `apple` text in all four when the full text names other platforms, stores or GitHub, which App Review rejects (Guideline 2.3.10); App Store descriptions likewise never mention Android or other platforms; then run `scripts/store_release_notes.py`, which writes the Play and App Store notes under `store/` (CI fails if they are out of date).

## Builds and identity

- **Android release builds shrink code with R8**, which strips or renames classes that plugins using Pigeon JNI (e.g. `shared_preferences_android` 2.5+) look up by name, so the app opens to a blank screen. Debug builds hide it. Add keep rules to `android/app/proguard-rules.pro`, and test a release build on a device after upgrading such plugins.
- **iPhone delivery:** never use `flutter run` to deliver or install a build. Create an untethered Ad Hoc IPA with `flutter build ipa --release --export-method ad-hoc`, then install the app bundle with `xcrun devicectl`.
- **App icons:** edit the SVGs in `assets/branding/`, never the generated platform icons. iOS and macOS use `assets/branding/AppIcon.icon`, edited in Icon Composer and referenced by both Xcode projects; keep `ios: false` and `macos: generate: false` for `flutter_launcher_icons`, and keep the flat layers in `assets/branding/layers/` in sync with what you import into it.
- **Version:** bump `version:` in `pubspec.yaml` only when asked. Its build number (after the `+`) is the one every store and the GitHub release binaries use: raise it there before a store build and never pass `--build-number`. The GitHub release title and notes show only the marketing version, so a store rejection can ship another `+N` under the same version without renaming the release.
