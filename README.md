# Bedug - Muslim Prayer Times App

Cross-platform Muslim prayer time app with Hijri calendar, localized UI, and adaptive platform design.

## Features

- Accurate prayer times (default: Kemenag RI, plus multiple global methods)
- Live next-prayer countdown
- Hijri calendar view
- Adhan notification integration
- Multi-language UI: Indonesian, English, Arabic, Malay
- Adaptive UI by platform: Liquid Glass (iOS/macOS), Material 3 (Android/Linux), Fluent-like layout (Windows)
- Shared, reusable "Calculation Method" picker with animated slide + drag-to-dismiss

## Theme Behavior

- In-app theme switching (System/Light/Dark) updates immediately across prayer cards, app bars, nav bars, and glass overlays.
- UI brightness is derived from the active app theme (`Theme.of(context).brightness`) instead of system platform brightness, to avoid delayed or partial color updates when user theme mode is changed inside the app.

## Commit Message Convention

Use Conventional Commits:

```text
<type>(<scope>): <description>
```

Examples:
- `fix(theme): apply app-theme brightness immediately`
- `docs(readme): add commit message validation guide`

Common types:
- `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `build`, `ci`, `perf`, `style`, `revert`

Validate the latest commit subject locally:

```bash
git log -1 --pretty=%s | grep -E '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?: .+'
```

Husky-like hook setup (repo-managed git hooks):

```bash
./scripts/install_git_hooks.sh
```

This installs `core.hooksPath=.githooks` and validates commit messages automatically on every `git commit`.

## Supported Platforms

| Platform | Design System | Status |
|---|---|---|
| iOS | Liquid Glass | ✅ |
| macOS | Liquid Glass | ✅ |
| Android | Material Design 3 | ✅ |
| Windows | Fluent Design | ✅ |
| Linux | Material Design 3 | ✅ |

## Getting Started

### Prerequisites

- Flutter SDK 3.31+ recommended
- Dart SDK 3.x
- Xcode 14+ (for iOS/macOS)
- iOS deployment target 14.0+ (required by `home_widget`)
- Android Studio (for Android)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/bedug.git
cd bedug

# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run the app
flutter run
```

### Run on specific platform

```bash
flutter run -d macos      # macOS
flutter run -d iphone     # iOS Simulator
flutter run -d android    # Android Emulator
flutter run -d windows    # Windows
```

## Tech Stack

| Category | Package |
|---|---|
| State management | `flutter_riverpod` |
| Prayer times | `adhan` |
| Notifications | `flutter_local_notifications` |
| Location | `geolocator` |
| Localization | `flutter_localizations` + `gen-l10n` |
| Hijri calendar | `hijri` |
| Timezone | `timezone` |

## Localization

The app supports 4 languages. To add a new language:

1. Create `lib/l10n/app_XX.arb` (where `XX` is the language code)
2. Add translations for all keys
3. Run `flutter gen-l10n`
4. Add the locale to `supportedLocales` in `app.dart`

Notes:
- Do not hardcode user-facing strings in widgets.
- Use `AppLocalizations.of(context)` for all labels and messages.

## Calculation Methods

| Method | Region |
|---|---|
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

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── home/
│   └── home_screen.dart
├── core/
│   ├── constants/
│   ├── providers/
│   ├── services/
│   └── widgets/
├── features/
│   ├── prayer_times/
│   ├── hijri_calendar/
│   └── settings/
└── generated/
    └── l10n/
```

## Contributing

Please read [README_AGENT.md](./README_AGENT.md) if you're using an AI coding assistant.

## License

MIT License — see [LICENSE](./LICENSE) for details.
