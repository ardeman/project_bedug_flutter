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
| Linux | Material Design 3 today; following the desktop (Adwaita on GNOME, Breeze on KDE) is planned | ✅ (desktop theming 🚧) |

See the [roadmap](#roadmap) for the Linux plan.

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
| Regenerate app icons after editing `assets/branding/*.svg` (macOS) | `swift scripts/render_brand_icons.swift && dart run flutter_launcher_icons` |
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
    worship/         Worship tab (hosts Qibla, later the tracker, tasbih, duas)
    qibla/           Qibla compass card
    prayer/          Prayer card widget
    hijri_calendar/  Hijri calendar screen
    settings/        Settings screen
  l10n/              ARB files (app_id.arb is the template)
  generated/l10n/    Generated localizations (do not edit)
bin/                 Command-line helper scripts
assets/branding/     App icon sources (SVG) and their 1024px renders
scripts/             Git hook scripts, icon renderer
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

## Roadmap

### Features: support daily Muslim activity

Bedug grows from a prayer-times app into a companion for a Muslim's day, week and year. Phases ship in order; each one is usable on its own.

**Principles for every phase**

- **Offline first, private by default.** Everything works without a network or an account, and the user's worship data (tracker, tasbih counts, bookmarks) stays on the device. Any sync is opt-in and comes later.
- **Trusted, licensed content.** Quran text, translations, duas and dzikir come from named sources whose license allows bundling (for example Tanzil for Quran text, Kemenag RI for the Indonesian translation). Each source is credited in the app.
- **Content is data, not UI strings.** Religious texts ship as per-locale JSON under `assets/content/<locale>/`. Only UI labels go through `AppLocalizations`.
- **Every feature on every platform design** (Liquid Glass, Material 3, Fluent), in all four languages, including right-to-left Arabic.

**Phase 1: Daily prayer (next)**

1. **Qibla direction (done):** compass card in the new Worship tab, using `adhan`'s `Qibla` bearing and the device heading from `flutter_compass` on iOS and Android. Desktop has no compass, so the dial stays north-up and shows the bearing, the distance and the Qibla's angle from the sun while it is up.
2. **Prayer tracker:** mark each of the five prayers as done (on time, late, missed), with a daily and weekly view, streaks and a qada (make-up) count.
3. **Notification control:** per-prayer on/off, a reminder N minutes before adhan, and a choice of adhan sound.
4. **Extra times:** imsak, sunrise (end of Subuh), dhuha, and the last third of the night for tahajud.
5. **Home screen widgets:** next prayer and countdown on iOS and Android (`home_widget` is already a dependency).

**Phase 2: Dzikir and dua**

1. **Tasbih counter:** large tap target with haptics, presets (33 × subhanallah, alhamdulillah, allahu akbar) and custom targets.
2. **Morning and evening dzikir** (dzikir pagi/petang): Arabic, transliteration and translation, with a reminder after Subuh and Asar.
3. **Daily duas** by situation (waking, eating, travel, entering the mosque) and the **Asmaul Husna**.
4. **After-prayer dzikir** offered from the prayer tracker once a prayer is marked done.

**Phase 3: Quran**

1. **Reader:** surah and juz lists, Arabic text with translation, adjustable font size, last-read position and bookmarks.
2. **Khatam planner:** pick a finish date, get a daily target, track progress.
3. **Ayah of the day** on the prayer-times screen and in the widget.
4. **Audio recitation (later):** streamed per ayah with download for offline use; needs a source and a storage budget first.

**Phase 4: The Islamic year**

1. **Events on the Hijri calendar:** Ramadan, Eid al-Fitr, Eid al-Adha, Arafah, Ashura, Isra Mi'raj, Mawlid, Ayyamul Bidh, with optional reminders.
2. **Hijri date adjustment** of ±1 or 2 days, because local announcements (such as Indonesia's sidang isbat) can differ from the calculated date.
3. **Ramadan mode:** sahur and iftar countdown, fasting log, and tarawih in the prayer tracker.
4. **Sunnah fasting reminders:** Monday and Thursday, Ayyamul Bidh, Arafah, Ashura.

**Phase 5: Beyond the device (later)**

1. **Zakat calculator:** zakat maal and fitrah, with the nisab entered manually first and a gold-price source added later.
2. **Nearby mosques:** needs a maps or places provider, so it waits on a cost and privacy review.
3. **Optional backup and sync** of tracker data across devices.

**Navigation.** Three tabs can't hold this. Phase 1 adds a **Worship** tab (Qibla, tracker, and later tasbih and dua); Phase 3 adds a **Quran** tab, giving five: Prayer times, Worship, Quran, Calendar, Settings.

**Open decisions**

- Storage for tracker and reading history: `shared_preferences` won't scale past Phase 1; choose a local database (for example `drift`) before Phase 1 step 2.
- Content sources and licenses for each language's Quran translation, duas and dzikir.
- Whether Phase 1 ships as one release or feature by feature.

### Linux: follow the desktop environment

Linux should look like the desktop it runs on instead of Android's Material 3.

1. **Theme first (next):** detect the desktop from `XDG_CURRENT_DESKTOP` (fallback `DESKTOP_SESSION`); use Adwaita colors and fonts on GNOME-family desktops (GNOME, Budgie, Pantheon, Cinnamon) and Breeze on KDE; pick up the system accent color and dark/light preference, with the in-app theme override still winning. Other desktops keep Material 3. The layout stays as it is.
2. **Native chrome (later):** a libadwaita-style header bar with a view switcher on GNOME, and Breeze sidebar navigation and cards on KDE. This waits until step 1 has been checked on real GNOME and KDE machines.

Flutter stays the framework: React Native has no maintained Linux target.

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
