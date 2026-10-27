# AGENTS.md

Instructions for AI coding agents working in this repo. Read `README.md` for the overview, setup, commands and layout. This file does not repeat them.

## Definition of done

A change is done only when the **Checks** command in `README.md` passes. If you can't run it, say so; don't claim it passed. Run `dart format` on the files you touch. Add or update tests in `test/` for behavior you change. For UI changes, think through (or run) both the Apple path (iOS/macOS) and the Material path (Android); tests don't show glass glitches, clipped labels or safe-area overlaps.

## Conventions

- Use Conventional Commit subjects; see `README.md` for the format and hook setup.
- Import Material widgets from `package:material_ui/material_ui.dart` and Cupertino widgets from `package:cupertino_ui/cupertino_ui.dart`. Material screens use `material_3_expressive` components where available. Only `AppThemeScope` imports bundled Material to bridge `liquid_glass_easy` theming.
- Follow [Effective Dart](https://dart.dev/effective-dart) and the lints in `analysis_options.yaml`. Use `const` wherever you can, prefix private widgets with `_`, and explain magic numbers (e.g. `kToolbarHeight + MediaQuery.of(ctx).padding.top`, not `64.5`).
- State lives in Riverpod providers:

  ```dart
  ref.watch(prayerProvider)                          // PrayerState { loading, error, times }
  ref.read(prayerProvider.notifier).load()           // trigger reload
  ref.watch(nextPrayerProvider)                      // NextPrayer { key, time }
  ref.watch(settingsProvider)                        // AppSettings { method, themeMode, ... }
  ref.read(settingsProvider.notifier).setMethod(m)
  ref.read(settingsProvider.notifier).setUseAutoLocation(v)
  ref.read(settingsProvider.notifier).setSelectedCityId(id)
  ref.watch(localeProvider)                          // Locale
  ```

- User-facing text, including error messages shown to users, goes through `AppLocalizations` with keys in every ARB file under `lib/l10n/`. Never hardcode strings or throw hardcoded messages. Never edit `lib/generated/l10n/`; run `flutter gen-l10n`.
- Indonesian text follows KBBI spelling: "salat", not "sholat" or "shalat" (also "azan", "kiblat"). Malay text keeps its own standard spelling, "solat". Other spellings belong only in store keywords.
- Colors come from `AppColors` (`emerald` primary, `teal` secondary, `gold` highlight, each with a `…Dark` twin, plus the backgrounds, surfaces and the Adwaita and Breeze palettes). Never hardcode hex colors. In widgets, use `AppColors.accentOf(ctx)`, `AppColors.secondaryOf(ctx)` and `Theme.of(ctx).colorScheme.tertiary` (gold) rather than the constants, so colors follow dark mode and the Linux desktop accent; the theme itself is built in `lib/core/theme/app_theme.dart`.
- Text styles come from `Theme.of(ctx).textTheme` (font: bundled Plus Jakarta Sans), spacing from `AppSpacing` and corner radii from `AppRadii` (`lib/core/theme/app_tokens.dart`). Override a text style with `copyWith` instead of building a new `TextStyle` with a raw `fontSize`.
- Code comments are in English.
- Release notes live in `assets/changelog/changelog.json`, newest release first, each change typed `new`, `improved` or `fixed` and written in all four languages. The app's What's New screen and the website's changelog page both read it, so it is the one place user-facing text skips the ARB files. When a commit changes what users see, add a line to the top release. The top release's version must match `version:` in `pubspec.yaml` (a test checks this); its `date` stays `null` until it ships.
- Landing page text lives in `site/i18n/*.json`, with every key in all four languages; the site's only script is the home page's live phone mock (`site/static/live.js` with the vendored `adhan` library), and its CSP allows same-origin scripts only, with inline scripts and styles blocked. See "Website" in `README.md`.

## Platform design

Each platform gets its own design system. Check the platform before rendering any UI.

| Platform | Design system | Style |
| --- | --- | --- |
| iOS / macOS | Liquid Glass | `liquid_glass_easy` lenses (refraction) and lite glass |
| Android / Linux | Material 3 Expressive | `NavigationBar`, `Card`, dynamic color; on GNOME and KDE, Adwaita or Breeze colors, fonts and the system accent (`lib/core/design/linux_desktop.dart`) |
| Windows | Fluent Design | `NavigationRail`, acrylic-style containers |

- Detect Apple with `PlatformDesign.isApple` / `PlatformCapabilities.isApple` (`lib/core/design/`), or a local getter that checks `kIsWeb` first: `!kIsWeb && (Platform.isIOS || Platform.isMacOS)`. `kIsWeb` needs `package:flutter/foundation.dart`.
- Derive brightness from the app theme, never the platform: `Theme.of(ctx).brightness == Brightness.dark`. The user can override the theme in the app, and `MediaQuery.platformBrightness` lags or mismatches.
- iOS 26+ and macOS 26+ are the baseline, so liquid-glass navigation is the default on Apple platforms. Deployment targets stay at `26.0` in the Podfiles and Xcode settings.

### Liquid Glass

- `Scaffold` uses `extendBody: true` and `extendBodyBehindAppBar: true` so content scrolls behind the glass bars.
- All glass comes from [`liquid_glass_easy`](https://pub.dev/packages/liquid_glass_easy); don't hand-build it from `BackdropFilter`. Glass that floats over content (nav bar, app bar capsule, buttons, badges) is a refracting `LiquidGlassLens` or a package component (`LiquidGlassTabBar`, `LiquidGlassButton`), tinted with `glassTintOf(ctx)` from `lib/core/design/liquid_glass.dart`. Glass that scrolls with a list (prayer cards) or may render on Skia (the method picker on other platforms) is `LiquidGlassLite`: the package advises against lenses inside scrollables, and Skia can't refract.
- The nav bar (`GlassNavBar`, a `LiquidGlassTabBar`) floats in a `Stack` over the page, not in `bottomNavigationBar`. It is `64` tall plus a bottom margin, so lists end with enough padding to scroll clear of it.
- A tab's top bar is `GlassTopBar` (the title in a glass capsule over a scroll edge on Apple, the accent `AppBar` elsewhere) with `extendBodyBehindAppBar: PlatformCapabilities.isApple`. Prayer times has its own collapsing sliver bar. The scaffold sets the page's bottom padding to `GlassNavBar.occupiedHeight`, so lists and `SafeArea` keep clear of the floating nav bar.
- Glass card: `Material(color: Colors.transparent)` → `LiquidGlassLite(shape: continuousRoundedRectangle(cornerRadius: AppRadii.lg))` with a white tint (alpha ~0.62 light, ~0.07 dark). `GlassCard` in `lib/core/design/liquid_glass.dart` builds it, and falls back to a Material `Card` elsewhere.
- No Material widgets on Apple paths, including ink ripples, `ListTile`, `Divider` and Material spinners or scrollbars. Use `GlassIconButton` or `LiquidGlassButton` for buttons (`GlassPillButton` inside scrolling glass), `LiquidGlassSwitch` for switches, `showGlassMenu` (`lib/core/widgets/glass_menu.dart`) instead of `DropdownButton`, `ToggleButtons` or popup menus, and `PlatformListTile`, `GlassPressable`, `Hairline` and `AdaptiveSpinner` from `lib/core/design/glass_controls.dart`. The settings rows in `settings_screen.dart` show the pattern.
- Glass follows the system's Liquid Glass style and accessibility through `GlassAccessibility` (`lib/core/design/glass_accessibility.dart`, fed by a native event channel in `ios/Runner/AppDelegate.swift` and `macos/Runner/MainFlutterWindow.swift`): the Clear-to-Tinted amount moves tints from clear to opaque, Increase Contrast makes them opaque, and Reduce Transparency makes them the solid `colorScheme.surface`. Take tints from `glassTintOf` (floating glass), `glassCardTintOf` (cards) or `glassSheetTintOf` (sheets), never a raw white or black alpha, and pick icon colors over glass from how light the tinted glass is, not a fixed white.
- Don't give a lens an `Opacity` of zero to hide it; also set `visibility: false` so it stops reading the backdrop.
- Full-screen blur overlay (sheet, modal): push a `PageRouteBuilder(opaque: false, barrierColor: Colors.transparent)` whose page is a tap-to-dismiss `Scaffold(backgroundColor: Colors.black38)` with the glass panel aligned to the bottom.
- Decorative layers (gradients, blur) stacked above tappable controls are wrapped in `IgnorePointer`, or they swallow taps on the app bar icons.
- On iOS/macOS the prayer-times app bar icons are round `LiquidGlassButton`s with Material `Icons.*`. Their color moves from white (over the accent hero) to `onSurface` as the bar collapses.
- Apple sliver app bars: the collapsed height and action offsets account for the Dynamic Island in portrait, landscape layouts respect horizontal safe-area cutouts, and the expanded header uses compact sizing so collapsing never overflows a `RenderFlex`.

### macOS window and nav bar

- Keep the window chrome in `macos/Runner/MainFlutterWindow.swift`: `titleVisibility = .hidden`, `titlebarAppearsTransparent = true`, `.fullSizeContentView`, `isMovableByWindowBackground = true`, `isOpaque = false` with a clear background and a corner radius on the Flutter view, and traffic-light buttons repositioned at an explicit top/left inset, updated on every resize.
- The nav bar's selection pill can be tapped or dragged between tabs on every Apple platform; `LiquidGlassTabBar` handles it.

### Sheets

- Native, non-blur Apple sheets are fine where native behavior is wanted: the calculation method picker (`lib/core/widgets/calculation_method_picker.dart`) uses `showCupertinoSheet` on iOS/macOS, `M3EBottomSheet` on Material paths and a liquid-glass route on other desktop paths.
- Guard every sheet against opening twice; repeated taps while it opens stack a second sheet. Keep an open flag and reset it in `finally` (see `_showMethodPicker` in `prayer_times_screen.dart`).

## Location

- The prayer-time location is either auto-detected from GPS or a city picked in Settings. With auto detect off, a city is required.
- When reverse geocoding can't resolve an address, show the nearest supported city (`lib/core/constants/city_catalog.dart`), never raw coordinates.
- In the denied-forever permission state, show one actionable guidance message, not duplicate guide lines.

## Guardrails

These come from real crashes and broken UI.

- **No `CupertinoIcons`:** they render as `?` boxes on macOS. Use `Icons.*`.
- **No `CupertinoListTile`.**
- **`ListTile` inside a `SliverList` / `CustomScrollView`** must be wrapped in `Material(color: Colors.transparent)`, or it throws "No Material widget found".
- **No `showModalBottomSheet` or `showCupertinoModalPopup` for blur overlays:** `BackdropFilter` doesn't blur inside them on macOS. Use the `PageRouteBuilder(opaque: false)` overlay above.
- **Mismatched brackets after a patch** (`Can't find ')' to match '('`): rewrite the whole class cleanly instead of patching again.
- **Android release builds shrink code with R8**, which strips or renames classes that plugins using Pigeon JNI (e.g. `shared_preferences_android` 2.5+) look up by name, so the app opens to a blank screen. Debug builds hide it. Add keep rules to `android/app/proguard-rules.pro`, and test a release build on a device after upgrading such plugins.
- **Platform folders** (`android/`, `ios/`, `macos/`, etc.) are mostly generated. Edit them only for platform config (window chrome, permissions, deployment targets, app ID). Never edit `**/GeneratedPluginRegistrant.*`, `ios/Flutter/Generated.xcconfig` or anything under `build/` or `.dart_tool/`.
- **App identity:** don't change the package name `bedug` or the ID `com.ardeman.bedug` without being asked. The display name is `Bedug` and the publisher is `Ardeman` on every platform.
- **App icons:** edit the SVGs in `assets/branding/`, never the generated platform icons. iOS and macOS use `assets/branding/AppIcon.icon`, edited in Icon Composer and referenced by both Xcode projects; keep `ios: false` and `macos: generate: false` for `flutter_launcher_icons`, and keep the flat layers in `assets/branding/layers/` in sync with what you import into it.
- **Version:** bump `version:` in `pubspec.yaml` only when asked.

## Keeping docs current

- When you change a command, the layout or the setup, update `README.md`. When you change a convention or rule, update this file.
- Never copy content between docs. Link to the owning file instead (see the documentation map in `README.md`).
- `CLAUDE.md` and `GEMINI.md` must contain only the import of this file.

## Decisions

Record architectural choices here as one line each: date, decision, reason.

- `flutter_riverpod` for state, `shared_preferences` for settings.
- Kemenag RI is the default calculation method; `adhan` provides the others.
- Apple platforms target iOS 26+ / macOS 26+ so Liquid Glass can be the default without a capability gate.
- Native Apple controls came from `cupertino_native` (SF Symbols, buttons), not `CupertinoIcons`, which don't render on macOS. Superseded below.
- The calculation method picker uses a native Cupertino sheet on Apple platforms, an Expressive sheet on Material paths and `PageRouteBuilder` for other blur overlays.
- 2026-10-19: App icons are SVG sources in `assets/branding/` rendered by `scripts/render_brand_icons.swift` and generated with `flutter_launcher_icons`, so the brand art has one editable source.
- 2026-10-19: Apple builds use CocoaPods only (Swift Package Manager off in `pubspec.yaml`) and the Podfiles silence plugin warnings, because `cupertino_native` had no SPM support and mixed builds let plugin warnings through.
- 2026-10-19: Revenue comes from AdMob ads on Android and iOS plus an in-app "infaq" that removes them (external Trakteer/Ko-fi links on Windows and Linux), so the free app earns while supporters get it ad-free.
- 2026-10-19: Re-theme as "refined emerald" with Plus Jakarta Sans bundled under `assets/fonts/` (not `google_fonts`), so the app stays offline first and its typeface was designed in Indonesia.
- 2026-10-19: On Linux the theme follows GNOME (Adwaita) or KDE (Breeze) and reads the accent from the XDG settings portal over D-Bus (`dbus` package), so the app looks native without a GTK plugin.
- 2026-10-19: Liquid Glass on iOS and macOS comes from `liquid_glass_easy` (refracting lenses, lite glass in lists) and `cupertino_native` is removed, because the package gives real refraction everywhere and `cupertino_native` is being deprecated.
- 2026-10-20: The landing page is a script-free static site in `site/`, generated by a standard-library Python script and served by a static-assets Cloudflare Worker at `bedug.ardeman.com`, so it needs no toolchain, builds from the app's own brand assets and gets per-branch previews.
- 2026-10-20: Android and Windows keep the flat icon art; iOS and macOS use the layered Icon Composer icon `assets/branding/AppIcon.icon` (built from `assets/branding/layers/`), so the system renders Liquid Glass and the Default, Dark, Clear and Tinted modes itself.
- 2026-10-20: The app ID is `com.ardeman.bedug` on every platform (was `com.bedug.app`), changed before the first store upload so it sits under the publisher's reverse domain.
- 2026-10-20: Picker selection ticks go through `SelectionFeedback`: haptics on iPhone and Android, the system click on iPad, and a bundled tick (`assets/sounds/selection_tick.wav`, played with `audioplayers`) on macOS, Windows and Linux, because Flutter's haptics and system click do nothing on desktop.
- 2026-10-20: Indonesian text uses the KBBI spelling "salat" in the app, the site and the store name ("Bedug: Jadwal Salat", since "Bedug" was taken), with "sholat" and other variants only in the store keywords, so the app reads correctly and is still found by every spelling.
- 2026-10-20: The home page's phone mock is live: the Worker (`site/worker.js`) adds the visitor's approximate location from Cloudflare's IP geolocation, and a small same-origin script computes that place's times with the vendored `adhan` JS port (Kemenag, as in the app), so visitors see their own prayer times; this ends the site being script-free, and without scripts the static Jakarta mock remains.
- 2026-10-20: The changelog is one JSON file with every language inline (`assets/changelog/changelog.json`), bundled into the app and read by `site/build.py`, so release notes are written once and the app and the site never drift.

- 2026-10-20: Material paths use Expressive theme styling with Flutter components (tonal surfaces, emphasized type and animated button corners); Apple, Windows and GNOME/KDE retain their platform styling.

- 2026-10-20: Use `material_3_expressive` with the official `material_ui` / `cupertino_ui` libraries (Flutter 3.47+, Dart 3.13+) for Expressive components and spring motion; bridge the bundled theme for Liquid Glass and preserve native platform paths.

- 2026-10-20: Home screen widgets use `home_widget` to share seven calculated days with native WidgetKit and Android RemoteViews, so countdowns and prayer transitions work without a running Flutter engine; cache expiry asks users to reopen Bedug.

- 2026-10-24: Glass follows the system's Clear/Tinted Liquid Glass amount by reading the undocumented `NSGlassTintAmount` global default (macOS; Clear when it is missing), plus Reduce Transparency and Increase Contrast, because Apple has no API for the style and an in-app switch would disagree with the system one.

- 2026-10-27: Dzikir comes in selectable collections, each one JSON file under `assets/content/dzikir/` with the Arabic once and every translation inline, so users follow the collection they practise and a new one is data, not code.

- 2026-10-27: Dzikir cards count recitations themselves (tap to count, long-press to reset, kept only while the screen is open) instead of a separate tasbih screen, back in scope after 2026-10-21, so counting follows the text being read and needs no stored worship data.

- 2026-10-27: The Quran comes from Tanzil (Uthmani text, verbatim, and its hosted translations), built into `assets/content/quran/` by `scripts/build_quran_content.py` with the text and each translation in separate files, and set in the bundled Amiri Quran font; reading position, bookmarks and text size stay in `shared_preferences`, so the reader is offline, private and loads only the translation it shows.

- 2026-10-27: The khatam planner measures progress in juz (ayahs only within a juz) and moves it only when the reader marks an ayah, because ayah lengths vary too much for even daily portions and the last-read position also moves when browsing.

- 2026-10-27: The ayah of the day comes from a hand-curated list of occasions and themes, each with its reason in every language, with the ayah texts copied into the same file by `scripts/build_daily_ayahs.py`, so each day's pick is meaningful and explained, and the card and the widget never load the 2.5 MB Quran.

- 2026-10-27: Hijri calendar events are data (`assets/content/hijri_events.json`, by Hijri month and day ranges with every name inline) matched against the standard Umm al-Qura conversion, and their reminders fire at Maghrib the evening before, because that is when the Hijri day begins and the same file then feeds the calendar, the list and the notifications.

- 2026-10-27: The Hijri date adjustment (±2 days) is one setting passed explicitly to every Hijri conversion (`hijriOf`, `hijriToGregorian`), not a global offset in the `hijri` package, so the label, calendar, events, reminders and ayah of the day can't disagree and tests stay free of shared state.
