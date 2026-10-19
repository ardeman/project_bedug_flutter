# AGENTS.md

Instructions for AI coding agents working in this repo. Read `README.md` for the overview, setup, commands and layout. This file does not repeat them.

## Definition of done

A change is done only when the **Checks** command in `README.md` passes. If you can't run it, say so; don't claim it passed. Run `dart format` on the files you touch. Add or update tests in `test/` for behavior you change. For UI changes, think through (or run) both the Apple path (iOS/macOS) and the Material path (Android); tests don't show glass glitches, clipped labels or safe-area overlaps.

## Conventions

- Use Conventional Commit subjects; see `README.md` for the format and hook setup.
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
- Colors come from `AppColors` (`emerald` primary, `teal` secondary, `gold` highlight, each with a `…Dark` twin, plus the backgrounds, surfaces and the Adwaita and Breeze palettes). Never hardcode hex colors. In widgets, use `AppColors.accentOf(ctx)`, `AppColors.secondaryOf(ctx)` and `Theme.of(ctx).colorScheme.tertiary` (gold) rather than the constants, so colors follow dark mode and the Linux desktop accent; the theme itself is built in `lib/core/theme/app_theme.dart`.
- Text styles come from `Theme.of(ctx).textTheme` (font: bundled Plus Jakarta Sans), spacing from `AppSpacing` and corner radii from `AppRadii` (`lib/core/theme/app_tokens.dart`). Override a text style with `copyWith` instead of building a new `TextStyle` with a raw `fontSize`.
- Code comments are in English.
- Landing page text lives in `site/i18n/*.json`, with every key in all four languages; the site has no JavaScript (its CSP blocks scripts and inline styles). See "Website" in `README.md`.

## Platform design

Each platform gets its own design system. Check the platform before rendering any UI.

| Platform | Design system | Style |
| --- | --- | --- |
| iOS / macOS | Liquid Glass | `liquid_glass_easy` lenses (refraction) and lite glass |
| Android / Linux | Material Design 3 | `NavigationBar`, `Card`, dynamic color; on GNOME and KDE, Adwaita or Breeze colors, fonts and the system accent (`lib/core/design/linux_desktop.dart`) |
| Windows | Fluent Design | `NavigationRail`, acrylic-style containers |

- Detect Apple with `PlatformDesign.isApple` / `PlatformCapabilities.isApple` (`lib/core/design/`), or a local getter that checks `kIsWeb` first: `!kIsWeb && (Platform.isIOS || Platform.isMacOS)`. `kIsWeb` needs `package:flutter/foundation.dart`.
- Derive brightness from the app theme, never the platform: `Theme.of(ctx).brightness == Brightness.dark`. The user can override the theme in the app, and `MediaQuery.platformBrightness` lags or mismatches.
- iOS 26+ and macOS 26+ are the baseline, so liquid-glass navigation is the default on Apple platforms. Deployment targets stay at `26.0` in the Podfiles and Xcode settings.

### Liquid Glass

- `Scaffold` uses `extendBody: true` and `extendBodyBehindAppBar: true` so content scrolls behind the glass bars.
- All glass comes from [`liquid_glass_easy`](https://pub.dev/packages/liquid_glass_easy); don't hand-build it from `BackdropFilter`. Glass that floats over content (nav bar, app bar capsule, buttons, badges) is a refracting `LiquidGlassLens` or a package component (`LiquidGlassTabBar`, `LiquidGlassButton`), tinted with `glassTintOf(ctx)` from `lib/core/design/liquid_glass.dart`. Glass that scrolls with a list (prayer cards) or may render on Skia (the method picker on other platforms) is `LiquidGlassLite`: the package advises against lenses inside scrollables, and Skia can't refract.
- The nav bar (`GlassNavBar`, a `LiquidGlassTabBar`) floats in a `Stack` over the page, not in `bottomNavigationBar`. It is `64` tall plus a bottom margin, so lists end with enough padding to scroll clear of it.
- A tab's top bar is `GlassTopBar` (the title in a glass capsule over a scroll edge on Apple, the accent `AppBar` elsewhere) with `extendBodyBehindAppBar: PlatformCapabilities.isApple`. Prayer times has its own collapsing sliver bar. The scaffold sets the page's bottom padding to `GlassNavBar.occupiedHeight`, so lists and `SafeArea` keep clear of the floating nav bar.
- Glass card: `Material(color: Colors.transparent)` → `LiquidGlassLite(shape: continuousRoundedRectangle(cornerRadius: AppRadii.lg))` with a white tint (alpha ~0.62 light, ~0.07 dark).
- Don't give a lens an `Opacity` of zero to hide it; also set `visibility: false` so it stops reading the backdrop.
- Full-screen blur overlay (sheet, modal): push a `PageRouteBuilder(opaque: false, barrierColor: Colors.transparent)` whose page is a tap-to-dismiss `Scaffold(backgroundColor: Colors.black38)` with the glass panel aligned to the bottom.
- Decorative layers (gradients, blur) stacked above tappable controls are wrapped in `IgnorePointer`, or they swallow taps on the app bar icons.
- On iOS/macOS the prayer-times app bar icons are round `LiquidGlassButton`s with Material `Icons.*`. Their color moves from white (over the accent hero) to `onSurface` as the bar collapses.
- Apple sliver app bars: the collapsed height and action offsets account for the Dynamic Island in portrait, landscape layouts respect horizontal safe-area cutouts, and the expanded header uses compact sizing so collapsing never overflows a `RenderFlex`.

### macOS window and nav bar

- Keep the window chrome in `macos/Runner/MainFlutterWindow.swift`: `titleVisibility = .hidden`, `titlebarAppearsTransparent = true`, `.fullSizeContentView`, `isMovableByWindowBackground = true`, `isOpaque = false` with a clear background and a corner radius on the Flutter view, and traffic-light buttons repositioned at an explicit top/left inset, updated on every resize.
- The nav bar's selection pill can be tapped or dragged between tabs on every Apple platform; `LiquidGlassTabBar` handles it.

### Sheets

- Native, non-blur Apple sheets are fine where native behavior is wanted: the calculation method picker (`lib/core/widgets/calculation_method_picker.dart`) uses `showCupertinoSheet` on iOS/macOS and a liquid-glass route elsewhere.
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
- The calculation method picker uses a native Cupertino sheet on Apple platforms; blur overlays elsewhere use `PageRouteBuilder`.
- 2026-10-19: App icons are SVG sources in `assets/branding/` rendered by `scripts/render_brand_icons.swift` and generated with `flutter_launcher_icons`, so the brand art has one editable source.
- 2026-10-19: Apple builds use CocoaPods only (Swift Package Manager off in `pubspec.yaml`) and the Podfiles silence plugin warnings, because `cupertino_native` had no SPM support and mixed builds let plugin warnings through.
- 2026-10-19: Revenue comes from AdMob ads on Android and iOS plus an in-app "infaq" that removes them (external Trakteer/Ko-fi links on Windows and Linux), so the free app earns while supporters get it ad-free.
- 2026-10-19: Re-theme as "refined emerald" with Plus Jakarta Sans bundled under `assets/fonts/` (not `google_fonts`), so the app stays offline first and its typeface was designed in Indonesia.
- 2026-10-19: On Linux the theme follows GNOME (Adwaita) or KDE (Breeze) and reads the accent from the XDG settings portal over D-Bus (`dbus` package), so the app looks native without a GTK plugin.
- 2026-10-19: Liquid Glass on iOS and macOS comes from `liquid_glass_easy` (refracting lenses, lite glass in lists) and `cupertino_native` is removed, because the package gives real refraction everywhere and `cupertino_native` is being deprecated.
- 2026-10-20: The landing page is a script-free static site in `site/`, generated by a standard-library Python script and served by a static-assets Cloudflare Worker at `bedug.ardeman.com`, so it needs no toolchain, builds from the app's own brand assets and gets per-branch previews.
- 2026-10-20: Android and Windows keep the flat icon art; iOS and macOS use the layered Icon Composer icon `assets/branding/AppIcon.icon` (built from `assets/branding/layers/`), so the system renders Liquid Glass and the Default, Dark, Clear and Tinted modes itself.
- 2026-10-20: The app ID is `com.ardeman.bedug` on every platform (was `com.bedug.app`), changed before the first store upload so it sits under the publisher's reverse domain.
