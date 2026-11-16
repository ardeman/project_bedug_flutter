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

- Settings must survive app updates: save enums in `shared_preferences` by `name`, never `index`, fall back to the default when a stored value is unknown, and when a key's format changes, read the old key once to migrate it.
- User-facing text, including error messages shown to users, goes through `AppLocalizations` with keys in every ARB file under `lib/l10n/`. Never hardcode strings or throw hardcoded messages. Never edit `lib/generated/l10n/`; run `flutter gen-l10n`.
- Indonesian text follows KBBI spelling: "salat", not "sholat" or "shalat" (also "azan", "kiblat"). Malay text keeps its own standard spelling, "solat". Other spellings belong only in store keywords.
- Colors come from `AppColors` (`emerald` primary, `teal` secondary, `gold` highlight, each with a `…Dark` twin, plus the backgrounds, surfaces and the Adwaita and Breeze palettes). Never hardcode hex colors. In widgets, use `AppColors.accentOf(ctx)`, `AppColors.secondaryOf(ctx)` and `Theme.of(ctx).colorScheme.tertiary` (gold) rather than the constants, so colors follow dark mode and the Linux desktop accent; the theme itself is built in `lib/core/theme/app_theme.dart`.
- Text styles come from `Theme.of(ctx).textTheme` (font: bundled Plus Jakarta Sans), spacing from `AppSpacing` and corner radii from `AppRadii` (`lib/core/theme/app_tokens.dart`). Override a text style with `copyWith` instead of building a new `TextStyle` with a raw `fontSize`.
- Code comments are in English.
- When a commit changes what users see, add a line to the top release in `assets/changelog/changelog.json`. Before a release, a version bump or an icon change, read `docs/releasing.md`.
- For the landing page or the promo media project, read `docs/website.md`.

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
- Before writing or changing UI on iOS/macOS paths, read `docs/apple-ui.md` (Liquid Glass, the macOS window and nav bar, sheets).

## Location

- The prayer-time location is either auto-detected from GPS or a city picked in Settings. With auto detect off, a city is required.
- When reverse geocoding can't resolve an address, show the nearest supported city (`lib/core/constants/city_catalog.dart`), never raw coordinates.
- In the denied-forever permission state, show one actionable guidance message, not duplicate guide lines.

## Guardrails

These come from real crashes and broken UI.

- **No `CupertinoIcons`:** they render as `?` boxes on macOS. Use `Icons.*`.
- **No `CupertinoListTile`.**
- **`ListTile` inside a `SliverList` / `CustomScrollView`** must be wrapped in `Material(color: Colors.transparent)`, or it throws "No Material widget found".
- **No `showModalBottomSheet` or `showCupertinoModalPopup` for blur overlays:** `BackdropFilter` doesn't blur inside them on macOS. Use the `PageRouteBuilder(opaque: false)` overlay in `docs/apple-ui.md`.
- **Mismatched brackets after a patch** (`Can't find ')' to match '('`): rewrite the whole class cleanly instead of patching again.
- **Platform folders** (`android/`, `ios/`, `macos/`, etc.) are mostly generated. Edit them only for platform config (window chrome, permissions, deployment targets, app ID). Never edit `**/GeneratedPluginRegistrant.*`, `ios/Flutter/Generated.xcconfig` or anything under `build/` or `.dart_tool/`.
- **App identity:** don't change the package name `bedug` or the ID `com.ardeman.bedug` without being asked. The display name is `Bedug` and the publisher is `Ardeman` on every platform.
- **Version:** bump `version:` in `pubspec.yaml` only when asked; see `docs/releasing.md` for the build number.

## Keeping docs current

- When you change a command, the layout or the setup, update `README.md`. When you change a convention or rule, update this file, or the `docs/` file that owns it (see the documentation map in `README.md`).
- Never copy content between docs. Link to the owning file instead (see the documentation map in `README.md`).
- `CLAUDE.md` and `GEMINI.md` must contain only the import of this file, and `.github/copilot-instructions.md` only a pointer to it.

## Decisions

Record architectural choices in `docs/decisions.md`, one line each: date, decision, reason.
