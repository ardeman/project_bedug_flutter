# Bedug

A cross-platform Muslim prayer times app with a Hijri calendar, in Indonesian, English, Arabic and Malay.

- **Prayer times** from Kemenag RI by default, or one of several global calculation methods, with a live countdown to the next prayer and adhan notifications.
- **Hijri calendar** view.
- **Location** from GPS (auto detect) or a city picked in Settings.
- **Adaptive design:** Liquid Glass on iOS and macOS, Material 3 on Android and Linux, a Fluent-style layout on Windows.

## Features

- Live next-prayer countdown and adhan notifications.
- Location source:
  - Auto detect from device GPS, or
  - Manual city selection from Settings (required when auto detect is off).
- When reverse geocoding fails, the header shows the nearest supported city, never raw coordinates.
- GPS timeouts are handled gracefully: high-accuracy settings on Android, a recent last-known position as fallback, and no raw exception text shown to users.
- In-app theme switching (System / Light / Dark) updates every card, bar and glass overlay at once.
- Calculation method picker: a native Cupertino sheet on iOS/macOS, a liquid-glass sheet elsewhere.
- Apple-specific polish:
  - Native SF Symbols (`cupertino_native`) for icons and app bar buttons.
  - Prayer header that collapses into a compact bar, keeps the countdown visible and adapts to the Dynamic Island in portrait and to camera cutouts in landscape.
  - macOS window with a hidden, transparent title bar, rounded corners and inset traffic-light buttons. Tabs can be selected by dragging across the nav bar.

## Supported platforms

| Platform | Design system | Status |
| --- | --- | --- |
| iOS 26+ | Liquid Glass | ✅ |
| macOS 26+ | Liquid Glass | ✅ |
| Android | Material Design 3 | ✅ |
| Windows | Fluent Design | ✅ |
| Linux | Material Design 3 | ✅ |

## Getting started

Prerequisites: the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.31+) on the stable channel, plus the toolchain for the platform you target: Xcode 26+ for iOS/macOS (deployment targets are 26.0), Android Studio for Android. Run `flutter doctor` to check.

```sh
flutter pub get
flutter gen-l10n
./scripts/install_git_hooks.sh
flutter run -d macos   # or: iphone, android, windows, linux
```

## Commands

| Task | Command |
| --- | --- |
| Install dependencies | `flutter pub get` |
| Generate localizations | `flutter gen-l10n` |
| Run (debug) | `flutter run -d <device>` |
| List devices | `flutter devices` |
| Format changed files | `dart format <files>` |
| Static analysis | `flutter analyze` |
| Tests | `flutter test` |
| Install Git hooks (once per clone) | `./scripts/install_git_hooks.sh` |
| Check the adhan calculation from the command line | `dart run bin/check_adhan.dart` |
| Release build | `flutter build <apk\|appbundle\|ipa\|macos\|windows\|linux>` |

**Checks**: run both before every commit. They must pass with no errors or warnings:

```sh
flutter analyze && flutter test
```

### Commit messages

Commit subjects use Conventional Commits: `type(scope)!: description`, with optional scope and `!` for breaking changes. Allowed types are `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore` and `revert`. For example: `fix(theme): apply app-theme brightness immediately`.

`./scripts/install_git_hooks.sh` sets `core.hooksPath=.githooks`, which runs:

- `pre-commit`: `flutter analyze` on staged `.dart` files (`scripts/analyze_staged_dart.sh`).
- `commit-msg`: Conventional Commit validation (`scripts/validate_commit_msg.sh`).

To check the latest subject by hand:

```sh
git log -1 --pretty=%s | grep -E '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?: .+'
```

## Project layout

```text
lib/
  main.dart          Entry point
  app.dart           MaterialApp, theme, locale
  home/              Main scaffold with the adaptive bottom nav
  core/
    constants/       AppColors, city catalog
    design/          Platform detection, adaptive scaffold, liquid glass, SF Symbols
    providers/       localeProvider, settingsProvider
    services/        Prayer times, Kemenag method, notifications
    utils/           Hijri helpers
    widgets/         Shared widgets (calculation method picker)
  features/
    prayer_times/    Prayer times screen
    prayer/          Prayer card widget
    hijri_calendar/  Hijri calendar screen
    settings/        Settings screen
  l10n/              ARB files (app_id.arb is the template)
  generated/l10n/    Generated localizations (do not edit)
bin/                 Command-line helper scripts
scripts/             Git hook scripts
.githooks/           Versioned Git hooks
test/                Widget tests
android/ ios/ macos/ windows/ linux/
                     Platform runners
```

## Calculation methods

| Method | Region |
| --- | --- |
| Kemenag RI ⭐ | Indonesia (default) |
| Muslim World League | Global |
| ISNA | North America |
| Egyptian Authority | Egypt |
| Umm Al-Qura | Saudi Arabia |
| Karachi University | Pakistan |
| Kuwait | Kuwait |
| Qatar | Qatar |
| Singapore | Singapore |
| Turkey | Turkey |

## Localization

The app ships in Indonesian (template), English, Arabic and Malay. To add a language:

1. Create `lib/l10n/app_XX.arb` (`XX` is the language code) with every key from `app_id.arb`.
2. Run `flutter gen-l10n`.
3. Add the locale to `supportedLocales` in `lib/app.dart`.
4. Switch to it in Settings and check every screen.

## macOS

- The window chrome lives in `macos/Runner/MainFlutterWindow.swift`: hidden title, transparent title bar, full-size content, rounded corners, movable by background, and traffic-light buttons placed at a fixed inset that is kept on resize.
- Deployment target is macOS 26.0 and needs Xcode 26+.

## Tech stack

| Category | Package |
| --- | --- |
| State management | `flutter_riverpod` |
| Prayer times | `adhan` |
| Hijri calendar | `hijri` |
| Location | `geolocator`, `geocoding` |
| Notifications | `flutter_local_notifications` |
| Home screen widget | `home_widget` (Android, iOS) |
| Native Apple controls | `cupertino_native` |
| Storage | `shared_preferences` |
| Localization | `flutter_localizations` + `gen-l10n`, `intl` |
| Timezone | `timezone` |

## Documentation map

Each topic has one home. Update that file instead of copying its content somewhere else.

| File | Audience | Owns |
| --- | --- | --- |
| `README.md` | Everyone | Overview, setup, commands, layout |
| `AGENTS.md` | AI coding agents (and humans who want the rules) | Conventions, platform UI rules, guardrails, definition of done |
| `CLAUDE.md`, `GEMINI.md` | Claude Code, Gemini CLI | Only an import of `AGENTS.md` |
| `CONTRIBUTING.md` | Human contributors | Branches, bug reports, feature requests, pull requests |

Codex, Cursor, GitHub Copilot, Windsurf, Jules, Aider, Zed and other agents that follow the [AGENTS.md](https://agents.md) convention read `AGENTS.md` directly.

## License

MIT License.
