# Bedug

A cross-platform Muslim prayer times app with a Hijri calendar, in Indonesian, English, Arabic and Malay.

- **Prayer times** from Kemenag RI by default, or one of several global calculation methods, with a live countdown to the next prayer and adhan notifications.
- **Hijri calendar** view, following Umm al-Qura or MABIMS (Kemenag) and adjustable to local announcements.
- **Location** from GPS (auto detect) or a city picked in Settings.
- **Adaptive design:** Liquid Glass on iOS and macOS, Material 3 Expressive on Android and other Linux desktops (Adwaita/Breeze on GNOME/KDE), a Fluent-style layout on Windows.

## Features

- Live next-prayer countdown and adhan notifications.
- Location source:
  - Auto detect from device GPS, or
  - Manual city selection from Settings (required when auto detect is off).
- GPS prayer times appear before reverse geocoding finishes. The header initially shows the nearest supported city, then updates the address in the background; after a three-second lookup timeout it keeps the city, never raw coordinates.
- GPS timeouts are handled gracefully: high-accuracy settings on Android, a recent last-known position as fallback, and no raw exception text shown to users.
- In-app theme switching (System / Light / Dark) updates every card, bar and glass overlay at once.
- Calculation method picker: a native Cupertino sheet on iOS/macOS, an Expressive sheet on Material platforms, and a liquid-glass sheet on other desktop paths.
- Android prayer header: the location shares a row with the calculation-method and refresh buttons; the prayer label, name and countdown align to the start edge below it, mirroring for Arabic.
- Apple-specific polish:
  - Liquid Glass from `liquid_glass_easy`: a refracting tab bar with a draggable pill, glass app bar buttons and countdown, and lite glass prayer cards.
  - Prayer header that collapses into a compact bar, keeps the countdown visible and adapts to the Dynamic Island in portrait and to camera cutouts in landscape.
  - Half-folded iPhone Duo: the prayer summary stays above a reported horizontal fold; the schedule and refresh control scroll independently below it, with the fold kept clear.
  - macOS window with a hidden, transparent title bar, rounded corners and inset traffic-light buttons. Tabs can be selected by dragging across the nav bar.
  - A layered Icon Composer app icon, so iOS and macOS render it in Liquid Glass and in the Default, Dark, Clear and Tinted icon modes.

The Material screens use [Material 3 Expressive](https://m3.material.io/get-started) components from `material_3_expressive`: spring-driven buttons, icon buttons, switches and navigation, morphing loading indicators, tonal cards, grouped lists, segmented choices, dropdowns, search and calculation-method sheets. `material_ui` and `cupertino_ui` provide the underlying Flutter design libraries. Apple keeps Liquid Glass and native Cupertino sheets; GNOME/KDE keep their desktop palettes and Windows keeps its Fluent layout.

## Supported platforms

| Platform | Design system | Status |
| --- | --- | --- |
| iOS 26+ | Liquid Glass | ✅ |
| macOS 26+ | Liquid Glass | ✅ |
| Android | Material 3 Expressive | ✅ |
| Windows | Fluent Design | ✅ |
| Linux | Adwaita on GNOME, Breeze on KDE; Material 3 Expressive elsewhere | ✅ |

See the [roadmap](#roadmap) for the Linux plan.

## Getting started

Prerequisites: the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.47.8+, which has the fix for the eMudhra certificate advisory) on the stable channel, plus the toolchain for the platform you target: Xcode 26+ for iOS/macOS (deployment targets are 26.0), Android Studio for Android, and on Linux the GStreamer development packages that `audioplayers` builds against (`sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev`). Run `flutter doctor` to check.

```sh
flutter pub get
flutter gen-l10n
./scripts/install_git_hooks.sh
flutter run -d macos   # or: iphone, android, windows, linux
```

iOS and macOS builds use CocoaPods only: Swift Package Manager is turned off in `pubspec.yaml`. It was turned off for `cupertino_native`, which has since been removed; turning SPM back on is a separate change. Warnings from plugin code are silenced in `ios/Podfile` and `macos/Podfile`. Flutter still prints a "plugins do not support Swift Package Manager" notice on every Apple build; it's expected and harmless.

Today's live Hijri label advances at Maghrib calculated for the prayer location and shows an "After Maghrib" note until midnight. At midnight the Gregorian date catches up without advancing the Hijri label again. Prayer schedules and browsed calendar dates retain their Gregorian-day mapping. Without a prayer location/schedule, the label falls back to the standard calendar conversion. The Hijri date setting (below) moves every Hijri date the app shows.

### iOS launch testing

Open `ios/Runner.xcworkspace` in Xcode and choose **Runner** for Debug builds with breakpoints. Choose **Bedug Profile** to test launch speed and widgets on a physical iPhone: its Run action uses Profile with the debugger detached. The schemes share the same app and widget targets; Archive uses Release in both.

### Home screen widgets

On iOS and Android, open Bedug once to load a location, then add **Bedug** from the system widget gallery. Widgets show the next obligatory prayer, time, city and a live countdown. All widget sizes include a circular countdown. Small widgets keep the dial beside the prayer name and time, with a full-width digital countdown below. Medium iOS widgets also show a strip of the four prayers after the featured next prayer. Large iOS widgets pair a bigger countdown dial with the following four prayer rows distributed across the remaining height. Upcoming schedule entries include their prayer icons. The featured next prayer appears only above the schedule. The location line shows the city without administrative prefixes or region/country suffixes. On Android, resize to at least 350 dp wide and 180 dp tall for the four-prayer strip. The iOS ring and digital countdown update live; Android’s digital countdown ticks live while its dial refreshes with the widget (normally every 30 minutes, and at prayer transitions; the OS may delay updates). They follow the app language and theme. The widget caches seven days locally; open Bedug again to refresh or update your location after travel. Loading or location errors clear the cached times. Notification preferences do not affect widgets.

In **Settings → Widget Style**, preview small, medium/wide and large layouts, show or hide the analog dial, and show or hide the remaining four-prayer schedule. On iPhone and iPad, choose whether the headline shows the current prayer; individual widgets can override this in Edit Widget. Choices are saved automatically and refresh all home screen widgets. Large iPhone widgets switch to a centered countdown with a bigger dial when the prayer schedule is hidden. Previews use sample times; Apple previews keep representative WidgetKit proportions, system typography, the native background and evenly spaced schedule columns. Device sizes and system tinting can vary. Widget size is selected on the home screen.

On iPhone and iPad lock screens, add Bedug's **Next prayer** or **Today's prayers** widget while customizing the lock screen. Next prayer comes as a circular countdown ring with the prayer's time, a rectangle with the prayer, its time, a live countdown and the city without its "Kabupaten"/"Kota" prefix (the ring follows the analog dial setting), or an inline prayer and time above the clock. Today's prayers is a rectangular strip of the whole day: each prayer's sky symbol over its time, with a bar that is full once it has passed and fills live as the next one nears. The gallery titles and descriptions are localized in `ios/BedugPrayerWidget/Localizable.xcstrings`, because the gallery follows the device language rather than the app's. They share the home screen widgets' data and render in the system's lock screen tint. Android phones have no lock screen widgets, and macOS has none either.

For iOS signing, register the App Group `group.com.ardeman.bedug` with your Apple developer team and enable it for both `com.ardeman.bedug` (Runner) and `com.ardeman.bedug.PrayerWidget` (BedugPrayerWidget). Entitlements and the embedded WidgetKit target are already configured. The widget version follows Flutter's build name and number. The extension needs no CocoaPods or Flutter engine.

Device checks before shipping: add/remove and resize widgets; check prayer transitions and expiry while the app is closed; change city, calculation method, language and theme; test Arabic, light/dark and iOS tinted/clear modes. On Android also check reboot, clock changes and Doze; transition alarms are inexact and can be delayed by the OS.

User screenshots on 2026-10-21 confirmed the small dial, medium and large five-prayer layouts, appearance screen and both display toggles in Indonesian with full-color rendering. Dark and tinted/clear rendering still need checks for the enhanced layouts; Arabic light-mode checks are recorded below. The revised large layout with the schedule hidden still needs a device visual check. The responsive Android layouts (tall narrow and large lists, picker preview) still need a device check at each size, in Arabic and light/dark.

On 2026-10-27, an iPhone screenshot showed a sideways home-screen widget. The dial now draws ticks directly instead of applying rotation transforms. Follow-up checks on the connected iPhone 17 (iOS 27.0.1, profile build, through iPhone Mirroring) confirmed upright small, medium and large widgets in Arabic, full-color light mode, with readable labels and a ticking countdown while Bedug was closed. A temporary widget was added, resized through all three sizes and removed. Apple previews also have an outline so their rounded edges remain visible against the page in light and dark mode.

Validation of the original layouts on 2026-10-21: on the connected iPhone 17 (iOS 27.0.1), the shared App Group cache contained ordered future prayer times, location, language and theme data. The user confirmed small and medium layouts with a ticking countdown and no clipped text, Arabic and dark theme, tinted/clear rendering, city and calculation-method updates, and a prayer transition with Bedug closed. Seven-day cache expiry remains unverified; addition, removal and resizing are covered by the follow-up above. Android device checks remain pending; no Android device was connected.

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
| Regenerate the Android and Windows icons after editing `assets/branding/*.svg` (macOS) | `swift scripts/render_brand_icons.swift && dart run flutter_launcher_icons` |
| Regenerate the Android notification icon after editing `assets/branding/icon_notification.svg` | `python3 scripts/generate_notification_icon.py` |
| Rebuild the Quran text and translations from tanzil.net | `python3 scripts/build_quran_content.py` |
| Fill the ayah of the day's text after editing its refs | `python3 scripts/build_daily_ayahs.py` |
| Edit the iOS and macOS icon (re-import any changed layer from `assets/branding/layers/`) | `open -a "Icon Composer" assets/branding/AppIcon.icon` |
| Release build | `flutter build <apk\|appbundle\|ipa\|macos\|windows\|linux>` |
| Build the landing page into `site/dist/` | `python3 site/build.py` |
| Preview the landing page (with the Worker, so the phone mock is live) | `python3 site/build.py && npx wrangler dev` |

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
  app.dart           MaterialApp, locale
  home/              Main scaffold with the adaptive bottom nav
  core/
    constants/       AppColors, city catalog
    design/          Platform and Linux desktop detection, adaptive scaffold, liquid glass, SF Symbol names
    providers/       localeProvider, settingsProvider, systemAccentProvider
    theme/           buildAppTheme, BrandColors (accent from the theme), AppSpacing / AppRadii tokens
    services/        Prayer times, Kemenag method, notifications
    utils/           Hijri helpers, MABIMS calendar and sun/moon positions (Meeus), Qibla
    widgets/         Shared widgets (calculation method picker, recitation card)
  features/
    prayer_times/    Prayer times screen, day picker and Hijri month grid
    worship/         Worship tab (hosts Qibla, dzikir, duas and the Asmaul Husna)
    dzikir/          Dzikir collections and reader
    duas/            Daily duas by situation
    asmaul_husna/    The 99 names of Allah
    quran/           Quran tab: surah, juz and bookmark lists, and the reader
    qibla/           Qibla compass card
    prayer/          Prayer card widget
    settings/        Settings screen
    changelog/       What's New screen and the changelog model
  l10n/              ARB files (app_id.arb is the template)
  generated/l10n/    Generated localizations (do not edit)
bin/                 Command-line helper scripts
assets/branding/     App icon sources (SVG) and their 1024px renders
  AppIcon.icon/      Icon Composer icon for iOS and macOS
  layers/            Flat Icon Composer layers for the Apple icon
assets/fonts/        Bundled fonts (Plus Jakarta Sans, and Amiri Quran for the Quran text; both OFL)
assets/changelog/    Release notes in every language, shared by the app and the site
site/                Landing page (bedug.ardeman.com), see "Website" below
vendor/              Patched Liquid Glass runtime (see vendor/liquid_glass_easy/README.bedug.md)
scripts/             Git hook scripts, icon renderer, Quran content builder
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

- **Offline first, private by default.** Everything works without a network or an account, and the user's worship data (bookmarks and reading history) stays on the device. Any sync is opt-in and comes later.
- **Trusted, licensed content.** Quran text, translations, duas and dzikir come from named sources whose license allows bundling (for example Tanzil for Quran text, Kemenag RI for the Indonesian translation). Each source is credited in the app.
- **Content is data, not UI strings.** Religious texts ship as JSON under `assets/content/`, one file per collection with the Arabic once and every translation inline, like the changelog. Only UI labels go through `AppLocalizations`.
- **Every feature on every platform design** (Liquid Glass, Material 3 Expressive, Fluent), in all four languages, including right-to-left Arabic.

**Phase 1: Daily prayer (next)**

1. **Qibla direction (done):** compass card in the new Worship tab, using `adhan`'s `Qibla` bearing and the device heading from `flutter_compass` on iOS and Android. Desktop has no compass, so the dial stays north-up and shows the bearing, the distance and the Qibla's angle from the sun while it is up.
2. **Notification control (done; device delivery checks pending):** a master switch, and for each time an on/off switch with its own early reminder (5, 10, 15 or 30 minutes before) and sound: the system sound, a bundled bedug drum or siren (previewed when picked), on Android any tone already on the phone (the system picker, opened from `MainActivity.kt`, with one channel per tone), or silent. No recorded azan. The sounds ship as `.wav` in `android/app/src/main/res/raw/` (one Android channel per sound) and `assets/sounds/` (previews), and as `.caf` in `ios/Runner/Sounds/` and `macos/Runner/Sounds/`. Android, iOS and macOS queue six days of alerts, refreshed on opening/resuming the app, at midnight while running, and when preferences change. Android falls back to inexact alarms without exact-alarm access; Settings links to system notification settings and exact-alarm permission. Scheduled alerts are not available on Windows or Linux yet.
3. **Extra times (done):** imsak (10 minutes before Subuh; fasting starts at Subuh), sunrise (end of Subuh), estimated dhuha start (20 minutes after sunrise), and the last third of the night for tahajud. The night is measured from the previous day’s Maghrib to the selected day’s Subuh, so the displayed time belongs to that morning. Dhuha is a fixed-offset estimate, not an official Kemenag timetable.
4. **Home screen widgets (implemented; iPhone checks recorded under [Home screen widgets](#home-screen-widgets), remaining device checks pending):** next prayer and live countdown on iOS and Android. The app shares seven independently calculated days on load/resume, midnight, and calculation, city or language changes. iOS uses a WidgetKit timeline; Android uses a native chronometer and inexact transition alarms (updates may be delayed in Doze). After seven days, open Bedug to refresh.

Android notification icon validation on 2026-10-21: the release APK includes the dedicated Bedug drawable after resource shrinking and was installed on the Pixel 5 (Android 14). A temporary shell notification using a raster preview of the same SVG showed the drum silhouette clearly. Delivery of an actual scheduled prayer alert with the packaged vector still needs confirmation.

Prayer tracking and prayer-progress features (completion logs, streaks and qada counts) are outside the product scope.

**Phase 2: Dzikir and dua**

1. **Morning and evening dzikir** (dzikir pagi/petang; done): Arabic, transliteration, translation and repeat count from a dzikir collection the user picks in Settings, with a counter on each card (tap to count up to the repeat, long-press to reset; counts last while the screen is open) (the picker appears once a second collection ships). Each collection is one JSON file in `assets/content/dzikir/` with every language inline, registered in `lib/features/dzikir/dzikir.dart`; items tag their `sessions` (morning, evening), and a collection whose items have none, such as a ratib, is listed whole without the morning/evening switch. Hisnul Muslim, Al-Ma'tsurat (Sughra and Kubra, after al-Banna's 1351 H text with the order of common Indonesian printings) and MPTT's Ratéb Siribèe ship, translated by Bedug; their text and hadith references need a review by someone qualified before release. Optional reminders, off by default, fire 15 minutes after Subuh and Asar with the system sound (Android, iOS and macOS, like the prayer alerts); a collection without sessions gets none, and the switches come back with the next collection that has them.
2. **Daily duas and the Asmaul Husna (done):** duas grouped by situation (sleeping and waking, eating, dressing, the toilet, wudu, home, the mosque, travel, rain, sneezing, hardship and any time), each with Arabic, transliteration, translation and its hadith or verse, from `assets/content/duas/daily.json`; and the 99 names, numbered with transliteration and meaning, from `assets/content/asmaul_husna.json` (at-Tirmidzi 3507 in the order common in Indonesia). Both open from the Worship tab and share the dzikir's card (`lib/core/widgets/recitation_card.dart`). Translations and meanings are by Bedug and need the same qualified review as the dzikir before release.
3. **After-prayer dzikir (done):** its own Worship tab entry, from `assets/content/after_prayer_dzikir.json` (Hisnul Muslim's chapter after the salam) in the dzikir format but outside the collection picker. Items may carry a `note` in every language for when they apply, such as "After Fajr"; Ayat al-Kursi and the three Quls reuse the Hisnul Muslim collection's text and translation. It needs the same review as the other dzikir before release.

**Phase 3: Quran**

1. **Reader (done; device visual checks pending):** a Quran tab with surah, juz and bookmark lists and a "continue reading" row. The reader shows one surah, opens at any ayah, and has the Arabic in the bundled Amiri Quran face with the app language's translation under it (none for Arabic), a text-size control, a bookmark on each ayah and the next surah at the end; the ayah at the top of the screen is saved as the last-read position. `scripts/build_quran_content.py` writes `assets/content/quran/` from tanzil.net: the Uthmani text (CC BY 3.0, verbatim, with its notice), Kemenag's Indonesian, Saheeh International's English and Basmeih's Malay translations, and the surah and juz metadata, with Kemenag's transliterated surah names for Indonesian and Malay. Tanzil opens each first ayah with the basmala, so the reader moves it into the surah's heading. Last-read, bookmarks and text size live in `shared_preferences`. Unlike other content, the text and each translation are separate files, because together they are about 5 MB and only one translation is read at a time. **Open:** Tanzil marks its translations for non-commercial use, so each translator's or publisher's permission is needed before an ad-supported release.
2. **Khatam planner (done; device visual checks pending):** a card at the top of the Quran tab starts a plan of 7, 15, 30 or 60 days and then shows today's target ayah, the share read and the days left, with Continue (the ayah after the last one marked), Change (a new length that spreads what is left from today) and End. Progress is what the reader marks with the flag on an ayah, not the last-read position, so browsing and bookmarks never move it. Progress and targets are measured in juz, which are close to equal in length, and only within a juz by ayahs (`lib/features/quran/khatam.dart`). The plan lives in `shared_preferences`.
3. **Ayah of the day (done; device visual checks pending):** a card under the picked day's prayer times and a home screen widget (small, medium and large on iOS; resizable on Android), both opening the reader at the ayah. `assets/content/quran/daily_ayahs.json` is curated by hand: occasions (Hijri dates such as Ramadan's last ten nights, Arafah and the two Eids, whole Hijri months such as Ramadan and Rabiulawal, and Fridays), then themes for other days, each with why it is shown in every language. The most specific occasion wins (a few Hijri days over a month over Friday) and ordinary days take the themes in turn (`lib/features/quran/daily_ayah.dart`). Hijri dates are the daytime date's in the chosen calendar source, moved by the Hijri date adjustment. `scripts/build_daily_ayahs.py` copies each ayah's text and translations from the reader's files into the same JSON, so the card and the widget never load the whole Quran. The app shares seven days with the widget, which changes at midnight; the selection and its reasons need the same qualified review as the dzikir before release.
4. **Audio recitation (later):** streamed per ayah with download for offline use; needs a source and a storage budget first.

**Phase 4: The Islamic year**

1. **Events on the Hijri calendar (done; device visual and delivery checks pending):** the Islamic New Year, Ashura, the Mawlid, Isra Mi'raj, the first day of Ramadan, Eid al-Fitr, Arafah, Eid al-Adha, the days of Tashreeq and Ayyamul Bidh (13 to 15 of every month, without 13 Dhu al-Hijjah, a day of Tashreeq), from `assets/content/hijri_events.json` with every name inline (`lib/features/hijri_events/`). Event days get a dot in the Hijri month grid and their names under the picked date; a Worship tab entry lists the year ahead with how many days away each is. Optional reminders, off by default, come at Maghrib the evening before, when the Hijri day begins (once before a run of days), with the system sound on Android, iOS and macOS. Dates are the daytime date's in the chosen calendar source, as the ayah of the day's are, moved by the Hijri date adjustment.
2. **Hijri date adjustment (done; device visual checks pending):** **Settings → Prayer times → Hijri date** moves the calculated date 1 or 2 days either way (`hijri_adjustment` in `shared_preferences`), because local announcements (such as Indonesia's sidang isbat) can differ from it. Every conversion goes through `hijriOf` and `hijriToGregorian` in `lib/core/utils/hijri_utils.dart` with the setting, so the date label, the month grid, the events list and its reminders, and the ayah of the day (card and widget) move together.
3. **Calendar source (done; device visual checks pending):** **Settings → Prayer times → Hijri calendar** picks whose calendar the Hijri dates follow (`hijri_source` in `shared_preferences`): Umm al-Qura (Saudi Arabia, the `hijri` package's table, the default) or MABIMS, the Indonesian government's (Kemenag) criteria, also used by Malaysia, Brunei and Singapore: a month starts the day after the first evening, at or after the conjunction, when at sunset the moon is at least 3° high (as seen, with refraction) and 6.4° from the sun (from the Earth's centre). `lib/core/utils/lunar_astronomy.dart` computes the positions after Meeus (chapters 25 and 47) and `lib/core/utils/mabims_calendar.dart` checks them at Kemenag's Lhoknga observatory in Aceh, in the far west where the criteria are met first; from there the elongation and altitude match the values Kemenag published for 1 Ramadan 1446 (6°24′ and 4°41′), and `test/hijri_utils_test.dart` checks every first day Kemenag published for 1444–1448 AH. The setting travels with the ±2-day adjustment as one `HijriReckoning` through `hijriOf`, `hijriToGregorian` and `buildHijriMonth`, and the adjustment stays on top, because sighting-based announcements can't be calculated ahead. Others (KHGT, Diyanet) may follow.
4. **Ramadan mode:** sahur and iftar countdown and a fasting log.
5. **Sunnah fasting reminders:** Monday and Thursday, Ayyamul Bidh, Arafah, Ashura.

**Phase 5: Beyond the device (later)**

1. **Zakat calculator:** zakat maal and fitrah, with the nisab entered manually first and a gold-price source added later.
2. **Nearby mosques:** needs a maps or places provider, so it waits on a cost and privacy review.
3. **Optional backup and sync** of bookmarks and reading history across devices.

**Navigation.** Three tabs can't hold this. Phase 1 adds a **Worship** tab (Qibla, and later dzikir and dua); Phase 3 adds a **Quran** tab (done), giving four: Prayer times, Worship, Quran, Settings, and a Calendar tab later makes five.

**Open decisions**

- Licenses for each language's Quran translation (Kemenag, Saheeh International, Basmeih), duas and dzikir.
- Whether Phase 1 ships as one release or feature by feature.

### Linux: follow the desktop environment

Linux should look like the desktop it runs on instead of Android's Material 3.

1. **Theme first (done; check on real GNOME and KDE machines):** detect the desktop from `XDG_CURRENT_DESKTOP` (fallback `DESKTOP_SESSION`); use Adwaita colors and fonts on GNOME-family desktops (GNOME, Budgie, Pantheon, Cinnamon) and Breeze on KDE; pick up the system accent color and dark/light preference, with the in-app theme override still winning. Other desktops use Material 3 Expressive styling. The layout stays as it is. Without a portal accent (GNOME before 47) the accent stays emerald.
2. **Native chrome (later):** a libadwaita-style header bar with a view switcher on GNOME, and Breeze sidebar navigation and cards on KDE. This waits until step 1 has been checked on real GNOME and KDE machines.

Flutter stays the framework: React Native has no maintained Linux target.

### Design: re-theme the app

The current look needs a redesign on every platform. Screens read the accent from the theme (`AppColors.accentOf`, `BrandColors` in `lib/core/theme/app_theme.dart`), so a new palette and type scale go in one place.

1. **Re-theme:** "refined emerald": a deep emerald on warm sand (light) or green-black (dark), gold as the highlight, Plus Jakarta Sans, flat cards with large radii and pill-shaped controls.
   1. **Tokens and theme (done):** palette in `AppColors`, `AppSpacing` / `AppRadii` and the component themes in `lib/core/theme/`.
   2. **Screen migration (done; device visual checks pending):** move each screen's inline styles (sizes, colors, radii, paddings) onto the text theme and tokens, one screen per commit: prayer times (done), liquid glass (done; device visual checks pending), method picker (done; device visual checks pending), calendar (done; device visual checks pending), settings (done; device visual checks pending), worship (done; device visual checks pending). Check each on Apple, Android, Windows and Linux in light and dark.
2. **Liquid glass package (done; check on iOS and macOS devices):** replace our `BackdropFilter` glass (nav bar, cards, sheets) on iOS and macOS with [`liquid_glass_easy`](https://pub.dev/packages/liquid_glass_easy), a shader lens with real refraction. Keep the `IgnorePointer`, double-open and safe-area rules from `AGENTS.md`.
3. **Apple app icon (done):** a layered Icon Composer icon (`assets/branding/AppIcon.icon`) gives iOS and macOS a Liquid Glass icon with Default, Dark, Clear and Tinted modes; Android and Windows keep the flat icon.
4. **Home screen widget (implemented; iPhone visual checks passed, see [validation status](#home-screen-widgets)):** a native WidgetKit extension with next prayer and countdown, shared Flutter data, and system rendering for full-color, tinted and clear modes.

Visual validation on 2026-10-21: the Pixel 5 (Android 14, release APK, Indonesian) and macOS 27.0.1 (debug build, English, 800 × 650 window) rendered prayer times, the expanded calendar, Settings, Worship and calculation-method controls in light and dark themes. The Android calendar toggle originally blended into its selected background; inheriting the button foreground fixed it, confirmed in a rebuilt release APK in both themes. An iPhone 17 (wired, profile build, Indonesian, portrait) rendered the same screens and the native method sheet in both themes: the expanded and collapsed prayer bars clear the Dynamic Island, and the glass buttons, countdown, date strip and wrapped labels stay readable. Temporary appearance and location settings were restored. Windows/Linux, mobile landscape and device checks with Arabic and enlarged text remain pending. See the follow-up validation below for macOS.


Android header validation on 2026-10-21: the Pixel 5 release build (Android 14, Indonesian, dark theme) shows the location on the calculation-method and refresh buttons’ centerline, with a long GPS address truncated clear of the actions. The prayer label, name and countdown align to the start edge below. Header tests also cover Arabic, landscape, larger text and collapse.

Follow-up validation on 2026-10-21: at 800 × 650 on macOS, the expanded calendar scrolls clear of the floating navigation in English and Arabic. Arabic tab taps and dragging the glass pill now open the matching screen and keep the pill under the selected label; regression tests cover both text directions on the Apple paths. These visual checks used the light theme. The expanded Arabic prayer header still lets the location overlap the action buttons and needs a separate fix. Dark Arabic, enlarged text, mobile landscape and the remaining platform checks are still pending.

iPhone validation on 2026-10-27 (iPhone 17, iOS 27.0.1, profile build, portrait, through iPhone Mirroring): the Quran list and inactive khatam planner fit in Indonesian dark mode and Arabic light/dark modes. Al-Fatihah's Arabic and Indonesian translation remained readable with the reader's text size increased twice, then restored. The complete Hijri month grid and event dots fit above navigation in Indonesian and Arabic dark mode; month navigation and Return to today worked. The source picker switched between Umm al-Qura and MABIMS, and a +1-day adjustment moved the date label and selected grid day together. MABIMS, zero adjustment, Indonesian and system appearance were restored. **Failed:** the expanded Arabic prayer header's long location still overlaps the refresh button on iPhone too. (Fixed afterwards: the Apple header now keeps the actions on the right in either direction and starts the Arabic location just left of them; a test covers it, and it still needs a look on the device.) Switching back to Indonesian also left Arabic region/country text in the location until a manual refresh; locale refresh needs investigation. Active khatam controls, reader bookmarks and persistence, remaining reader/theme combinations, system text scaling, notification delivery and other platforms remain pending.

Landscape on the same iPhone (a temporary build forcing landscape-left, screens switched by a launcher because Mirroring stopped forwarding taps after rotation, Indonesian dark mode): the expanded prayer header fits, with the location and refresh button clear of the Dynamic Island. **Failed:** the floating navigation covers the week strip on Prayer times and the compass-accuracy hint on the Kiblat card. Both lists end with room to scroll clear of it, and the bar is now compact in short windows (52 tall, 12 off the edge, covering 68 instead of 89 points); this still needs a look on the device. Touch interaction in landscape remains unverified.

### Revenue: ads and infaq

Bedug stays free. It earns from ads on mobile, and users can give an **infaq** (in Indonesian: *infak*) that supports development and turns the ads off. The feature is always called "infaq", never "tip" or "donation". All copy says the infaq **supports Bedug's development**, because App Store guidelines 3.2.1(vi) and 3.2.2 reject apps that look like they collect money for charity.

| Platform | Ads | Infaq |
| --- | --- | --- |
| Android | AdMob (`google_mobile_ads`) | In-app purchase (`in_app_purchase`, Play Billing, which in Indonesia supports e-wallets and carrier billing) |
| iOS | AdMob | In-app purchase (StoreKit) |
| macOS | None: AdMob has no macOS SDK | In-app purchase (StoreKit) |
| Windows, Linux | None: AdMob has no desktop SDK | External links via `url_launcher`: [Trakteer](https://trakteer.id) (QRIS, e-wallets, bank transfer) listed first for the Indonesian locale, [Ko-fi](https://ko-fi.com) (PayPal, cards) listed first for other locales |

Store rules require developer support on iOS, macOS and Android to go through in-app purchase, so the external links appear only on Windows and Linux.

**Distribution channels**

The infaq method depends on where the build is distributed, not only on the platform. Store billing works only inside its own store, and some stores ban ad SDKs. Each build passes `--dart-define=CHANNEL=<channel>`, and `infaqProvider` and the ad code read it.

| Channel | Builds | Ads | Infaq |
| --- | --- | --- | --- |
| `play` | Android on Google Play | AdMob | Play Billing |
| `appstore` | iOS App Store, Mac App Store | AdMob on iOS only | StoreKit |
| `direct` | Windows (Microsoft Store), Linux (Flathub); later perhaps an Android APK and a macOS DMG | AdMob on an Android APK only (expect lower fill: app-ads.txt can't verify an app without a store listing) | Dahlunas infaq code (Phase 3), Trakteer / Ko-fi links until then |
| `fdroid` (later) | Android on F-Droid | None | Trakteer / Ko-fi links, plus F-Droid's Donate metadata |

- Rollout order: `play` and `appstore` (iOS and the Mac App Store) first, since that's where users and ad revenue are. Then `direct` for Windows on the Microsoft Store and Linux on Flathub. A direct Android APK, a macOS DMG, Snap, AppImage and `fdroid` are skipped for now.
- F-Droid bans proprietary SDKs, so a define flag is not enough there. Its build recipe must remove `google_mobile_ads` and `in_app_purchase` from `pubspec.yaml` with a pre-build patch, and the code must compile without them.
- In-app purchase on macOS works only in a Mac App Store build. A DMG build uses the links.
- Skipped for now: Huawei AppGallery (no Google services, so it would need Huawei's own IAP and ads SDK), Samsung Galaxy Store (check whether its policy requires Samsung IAP first), and EU alternative iOS marketplaces.

**Phase 1: Infaq (done in code; store products and device purchase checks pending)**

1. **Store setup (manual):** paid-apps agreement, tax and bank details. Create the same product IDs in App Store Connect and Play Console:
   - non-consumables `infaq_small`, `infaq_medium` and `infaq_large`, priced as in Coba Lagi: a US base price of $0.99, $2.99 and $4.99, with Indonesia set by hand to Rp 5,000, 19,000 and 49,000, the same in both stores. Any of them turns the ads off and is restored on a new device, so the small one is in effect the ad-free price. Keep the US base: with an Indonesian base, Apple rounds Rp 5,000 and Rp 19,000 both up to $0.99 elsewhere. Family Sharing, once on, can't be turned off again.
   Create the Trakteer and Ko-fi pages. In the App Store review notes, explain: "Infaq is a voluntary in-app purchase that funds Bedug's development. No money goes to a charity or a third party."
2. **`lib/features/infaq/` (done):** `infaqProvider` picks in-app purchase or links from the build channel (`DistributionChannel` in `lib/core/services/distribution_channel.dart`; without `CHANNEL`, a build gets its platform's store), listens for purchases from launch, loads the products, buys and completes purchases, restores earlier infaq, and handles cancellation and errors. It stores an `adFree` flag in `shared_preferences`, set by any infaq bought or restored; the page says Restore purchases brings it back after a reinstall.
3. **UI (done; device visual checks pending):** an "Infaq" row in Settings → About opens a page (`InfaqScreen`) with the tiers and their store prices, a restore row and a thank-you state after payment; on direct builds, Trakteer and Ko-fi rows. It is a pushed page like the other Settings pages rather than a sheet, so it uses the same grouped rows on every platform and needs no double-open guard. No nag pop-ups.
4. **l10n keys (done)** (`infaq*`) in every ARB file, and tests (`test/infaq_test.dart`) for the provider with a fake `InAppPurchase` and for the page.

**Phase 2: Ads (Android and iOS)**

1. **Setup:** AdMob app and ad-unit IDs in `AndroidManifest.xml` and `Info.plist`. Test IDs in debug builds.
2. **Consent:** the UMP consent form (GDPR and other regions) and App Tracking Transparency on iOS (`app_tracking_transparency`). When the user declines, serve non-personalized ads. Update the iOS privacy manifest, the App Store privacy labels and the Play Data Safety form, and tick **Contains ads** in Play Console.
3. **Target audience 13+** in Play Console and App Store Connect. Including children under 13 brings in Google's Families policy and Apple's Kids rules: child-directed ads only, which earn less.
4. **Placement:** one adaptive banner above the nav bar on the Calendar and Settings tabs, padded for the glass nav bar and the safe area. No ads on prayer times, qibla or (later) the Quran, dzikir and dua screens, and no interstitials. The banner carries a short "Your infaq turns off the ads" line that opens the infaq sheet. Hide every ad when `adFree` is set.
5. **Content filter:** in the AdMob console, block gambling, alcohol, dating and other sensitive categories. This matters for a Muslim audience, and online gambling ads are a known problem in Indonesia.
6. **Tests:** ads are hidden when `adFree` is set and are never built on macOS, Windows or Linux.

**Phase 3: Infaq through Dahlunas on direct builds**

[Dahlunas](https://github.com/ardeman/project-dahlunas-go), Ardeman's own shop, sells Bedug infaq codes (project 2) at the same Rp 5,000, 19,000 and 49,000, paid by QRIS through Midtrans. It is in Dahlunas's sandbox since 2026-10-26; Dahlunas's production shop opens after Midtrans approves the account. Only `direct` (and later `fdroid`) builds use it: store builds keep in-app purchase, as store rules require. A code is active on one device at a time and moves to another up to 3 times. The contract is Dahlunas's `docs/activation.md`, with the code format in `docs/code-format.md`.

1. **Install ID:** on first launch, 16 random bytes in `shared_preferences`, as 32 lowercase hex characters; never a hardware or advertising ID.
2. **Code entry:** a "Have a code?" row on the infaq page on direct builds. It posts the code, the install ID and `"move": true` to `https://dahlunas.ardeman.com/activations`, verifies the returned `DA1.` activation with Dahlunas's public key for Bedug (Ed25519, `cryptography` package or a small pure-Dart verifier), stores code and activation, and sets `adFree`. Show the moves left, and the support email on `move_limit`.
3. **Checks:** verify the stored activation offline on every launch. About once a week while online, post with `"move": false`; on `moved`, clear the activation and `adFree` and offer to enter the code again. Network failures and `busy` keep the current state, so prayer times never depend on Dahlunas.
4. **Links:** a "Give infaq" row opening the Dahlunas shop in the browser, in place of Trakteer and Ko-fi once Dahlunas's production shop is open; until then keep the links.
5. **Keys:** debug builds bundle the sandbox public key (key 1) `31267471750b709622d73dbf2dc88df415d67895609910fa967a0545b04f7e50` and use `https://dah-lunas-sandbox.web.app`; release builds bundle the production key, made when Dahlunas adds Bedug to production.
6. **Privacy policy and l10n:** say that entering a code sends it and the random install ID to Dahlunas, which keeps the ID's hash to allow one device at a time; `infaqCode*` keys in every ARB file. Tests against the fixture in Dahlunas's `docs/activation.md`.

**Owner setup (not code)**

- Create the AdMob, Trakteer and Ko-fi accounts and put the handles in the code (`InfaqLinks` in `lib/features/infaq/infaq_provider.dart` assumes `trakteer.id/bedug` and `ko-fi.com/bedug`). Debug builds use AdMob test IDs, so coding doesn't wait on this.
- Enroll in Apple's Small Business Program so the App Store takes 15% instead of 30% (Google applies 15% to the first US$1M a year automatically).

## Website

The landing page at [bedug.ardeman.com](https://bedug.ardeman.com) is a static site built by `site/build.py` (Python standard library only) and served by a Cloudflare Worker (`wrangler.jsonc`). Its only script makes the home page's phone mock live: the Worker adds the visitor's approximate location from Cloudflare to the home pages, and `live.js` shows that place's prayer times, Hijri date and countdown. It has a home page, a changelog and a privacy policy in Indonesian (at `/`), English (`/en/`), Arabic (`/ar/`, right to left) and Malay (`/ms/`).

| Path | Holds |
| --- | --- |
| `site/i18n/<locale>.json` | All page text, one file per language with the same keys |
| `assets/changelog/changelog.json` | The changelog page's releases, shared with the app's What's New screen |
| `site/config.json` | Site URL, locales, links, and the store and infaq URLs (`null` shows "coming soon") |
| `site/static/` | Stylesheet, the phone mock's `live.js` with the vendored `adhan` JS library (`vendor/`, MIT), Cloudflare `_headers`, `robots.txt`, and a 512px copy of `assets/branding/icon.png` for social previews (refresh it with `sips -Z 512` when the icon changes) |
| `site/dist/` | Build output, not committed |
| `wrangler.jsonc` | Cloudflare Worker config that serves `site/dist/` |
| `site/worker.js` | The Worker script: serves `site/dist/` and adds the visitor's location to the home pages |

The build copies the font and `icon.svg` from `assets/`, so the brand has one source, and builds the changelog page from `assets/changelog/changelog.json`. When a store listing or the Trakteer and Ko-fi pages go live, put the URL in `site/config.json`. When the app gains or changes a feature that the home page or the privacy policy describes, update every `site/i18n/*.json`.

**Cloudflare setup (once):**

1. In the Cloudflare dashboard, go to **Workers & Pages → Create → Import a repository** and pick this repository.
2. Project name `bedug` (it must match `name` in `wrangler.jsonc`), build command `python3 site/build.py`, deploy command `npx wrangler deploy` (the default), path `/`.
3. Under the Worker's **Settings → Build → Build watch paths**, include `site/**`, `assets/fonts/**`, `assets/branding/**`, `assets/changelog/**` and `wrangler.jsonc` (and remove the default `*`), so app-only commits don't redeploy the site.
4. Under **Settings → Domains & Routes**, add the custom domain `bedug.ardeman.com`. This needs `ardeman.com` as a zone in the same Cloudflare account.

Every push to `master` deploys, and other branches get preview URLs.

## iOS release (TestFlight)

The App Store Connect record is **Bedug: Jadwal Salat** (bundle ID `com.ardeman.bedug`, SKU `bedug`, primary language Indonesian), signed by team `B36A8H9S8E` with automatic signing. To ship a build to TestFlight:

1. `flutter build ipa --build-number=<n>`, where `<n>` is higher than the last uploaded build (Xcode's Organizer lists uploaded archives under **Archives**, and App Store Connect lists every build under **TestFlight**). This leaves `version:` in `pubspec.yaml` alone.
2. Upload with an App Store Connect API key (App Manager role):

   ```sh
   xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
   ```

   `altool` reads the key from `~/.appstoreconnect/private_keys/AuthKey_<key id>.p8`; set `ASC_KEY_ID` and `ASC_ISSUER_ID` (shown in App Store Connect under **Users and Access → Integrations**) in your shell. A build number that was already uploaded fails with `DUPLICATE`. Without a key, `open build/ios/archive/Runner.xcarchive` and choose **Distribute App → App Store Connect → Distribute** in Xcode's Organizer, never "TestFlight Internal Only", whose builds can never reach external testers or the store.
3. Wait for processing (10–30 minutes; Apple sends an email). `ITSAppUsesNonExemptEncryption` is `false` in `Info.plist`, so App Store Connect doesn't ask about export compliance.
4. With automatic distribution on in the internal testing group, each new build reaches testers without a click; otherwise add the build to the group. Testers install it with the TestFlight app on the Apple ID they were invited with. Add people under **TestFlight → Internal Testing** (they must be users in Users and Access); external testers need a group under **External Testing** and a Beta App Review.

The store listing follows KBBI ("salat") in the name and subtitle, and reaches people who type other spellings through the hidden Keywords field:

- **Subtitle:** `Azan, Kiblat & Imsakiyah`
- **Keywords:** `sholat,shalat,solat,adzan,waktu,muslim,ramadan,imsak,doa,masjid,kalender,hijriah,puasa`

macOS uses the same bundle ID; add it in App Store Connect with **+** next to the iOS app. A Mac App Store build also needs the App Sandbox and Apple Distribution plus installer certificates.

## macOS

- The window chrome lives in `macos/Runner/MainFlutterWindow.swift`: hidden title, transparent title bar, full-size content, rounded corners, movable by background, and traffic-light buttons placed at a fixed inset that is kept on resize.
- Deployment target is macOS 26.0 and needs Xcode 26+.

## Tech stack

| Category | Package |
| --- | --- |
| State management | `flutter_riverpod` |
| Prayer times | `adhan` |
| Hijri calendar | `hijri` (Umm al-Qura); MABIMS calculated in-app |
| Location | `geolocator`, `geocoding` |
| Notifications | `flutter_local_notifications` |
| Liquid Glass | `liquid_glass_easy` |
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
| `site/i18n/*.json` | Website visitors | Landing page copy and the privacy policy |
| `assets/changelog/changelog.json` | App users and website visitors | What changed in each release |

Codex, Cursor, GitHub Copilot, Windsurf, Jules, Aider, Zed and other agents that follow the [AGENTS.md](https://agents.md) convention read `AGENTS.md` directly.

## License

MIT License.
