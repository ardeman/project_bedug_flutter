# 🤖 AI Agent Instructions — Bedug Flutter App

> Read this entire file before making any changes to the codebase.
> This file is for AI coding agents (Claude, ChatGPT, Gemini, Copilot, etc.).

---

## 🎨 Design System — Platform Adaptive (CRITICAL)

This app uses **three different design systems** per platform. Always check platform before rendering any UI.

```
Platform         Design System       Key Style
────────────────────────────────────────────────────
iOS / macOS   →  Liquid Glass        BackdropFilter + blur + frosted overlay
Android       →  Material Design 3   NavigationBar, Card, dynamic color
Windows       →  Fluent Design       NavigationRail, Acrylic-style containers
Linux         →  Material Design 3   Same as Android
```

### Platform Detection — Use This Everywhere

```dart
bool get _isApple => !kIsWeb && (Platform.isIOS || Platform.isMacOS);
```

Required imports:
```dart
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb lives here
```

### Theme Brightness Rule — Use App Theme

When user can switch theme mode inside the app, always derive brightness from `Theme.of(context)`, not platform brightness.

```dart
// ✅ Correct (respects app theme mode: system/light/dark)
final isDark = Theme.of(ctx).brightness == Brightness.dark;

// ❌ Wrong (can lag / mismatch when app theme is overridden)
final isDark = MediaQuery.of(ctx).platformBrightness == Brightness.dark;
```

### Liquid Glass Capability Gate

Project baseline is iOS 26+ and macOS 26+, so liquid-glass navigation is the default on Apple platforms.

### Location Behavior (CRITICAL)

- Prayer time source location supports:
  - Auto detect GPS
  - Manual city selection from settings
- If auto detect is disabled, city selection is required.
- If reverse geocoding cannot resolve an address, show nearest supported city name (not raw coordinates).

---

## ❌ Hard Rules — Never Break These

These were discovered through real bugs. Violating them causes crashes or broken UI.

### 1. Never use `CupertinoIcons`
They render as `?` boxes on macOS Flutter.
```dart
// ❌ Wrong
Icon(CupertinoIcons.slider_horizontal_3)

// ✅ Correct
Icon(Icons.tune)
```

### 2. Never use `CupertinoListTile`
Use `ListTile` instead.

### 3. Always wrap `ListTile` with `Material` in Sliver contexts
`ListTile` requires a `Material` ancestor. `SliverList` and `CustomScrollView` do not provide one.
```dart
// ✅ Correct
Material(
  color: Colors.transparent,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(...),
  ),
)
```

### 4. Never use `showModalBottomSheet` or `showCupertinoModalPopup` for blur overlays
`BackdropFilter` does NOT work inside these on macOS. Use `PageRouteBuilder` instead.
```dart
// ❌ Wrong — blur won't work
showModalBottomSheet(backgroundColor: Colors.transparent, ...);

// ✅ Correct — blur works
Navigator.of(ctx).push(
  PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.transparent,
    pageBuilder: (_, __, ___) => YourBlurOverlay(),
  ),
);
```

### 5. Always account for system padding in nav bar height
```dart
// ✅ Correct
height: 64 + MediaQuery.of(ctx).padding.bottom,
```

### 6. Always set `extendBody` and `extendBodyBehindAppBar` for liquid glass
```dart
Scaffold(
  extendBody: true,                  // content scrolls behind nav bar
  extendBodyBehindAppBar: true,      // content scrolls behind app bar
  ...
)
```

---

## 🧊 Liquid Glass Patterns

### Card / Container
```dart
Material(
  color: Colors.transparent,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.white.withOpacity(0.72),
            Colors.white.withOpacity(0.55),
          ]),
          border: Border.all(
              color: Colors.white.withOpacity(0.8), width: 0.8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: YourContent(),
      ),
    ),
  ),
)
```

### Nav Bar / App Bar (Frosted)
```dart
ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
    child: Container(
      color: isDark
          ? const Color(0xFF1C1C1E).withOpacity(0.72)
          : Colors.white.withOpacity(0.72),
      child: YourContent(),
    ),
  ),
)
```

### Full-screen Blur Overlay (Bottom Sheet, Modal)
```dart
// Widget
class MyOverlay extends ConsumerWidget {
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx), // tap outside to dismiss
      child: Scaffold(
        backgroundColor: Colors.black38,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // prevent tap-through
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: Colors.white.withOpacity(0.88),
                  child: YourSheetContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Usage
Navigator.of(ctx).push(PageRouteBuilder(
  opaque: false,
  barrierColor: Colors.transparent,
  pageBuilder: (_, __, ___) => MyOverlay(),
));
```

---

## 🗂️ Key Files

| File | Purpose |
|---|---|
| `lib/main.dart` | Entry point |
| `lib/app.dart` | MaterialApp, theme, locale |
| `lib/home/home_screen.dart` | Main scaffold + adaptive bottom nav |
| `lib/core/constants/app_colors.dart` | Color constants |
| `lib/core/providers/locale_provider.dart` | `localeProvider`, `settingsProvider` |
| `lib/core/services/prayer_service.dart` | `prayerProvider`, `nextPrayerProvider` |
| `lib/core/services/kemenag_method.dart` | `AppCalculationMethod` enum |
| `lib/core/widgets/calculation_method_picker.dart` | Shared Metode Hisab picker + label helpers |
| `lib/features/prayer_times/prayer_times_screen.dart` | Prayer times UI |

---

## 🗝️ Riverpod Providers

```dart
ref.watch(prayerProvider)                          // PrayerState { loading, error, times }
ref.read(prayerProvider.notifier).load()           // trigger reload
ref.watch(nextPrayerProvider)                      // NextPrayer { key, time }
ref.watch(settingsProvider)                        // AppSettings { method, themeMode, ... }
ref.read(settingsProvider.notifier).setMethod(m)   // update calculation method
ref.read(settingsProvider.notifier).setUseAutoLocation(v)
ref.read(settingsProvider.notifier).setSelectedCityId(id)
ref.watch(localeProvider)                          // Locale
```

---

## 🎨 Colors — Always Use `AppColors`

```dart
AppColors.emerald   // #10B981 — primary green
AppColors.teal      // secondary — used in gradients
AppColors.darkBg    // dark mode scaffold background
AppColors.lightBg   // light mode scaffold background
```

Never hardcode hex colors directly.

---

## ⚠️ Known Gotchas

| Symptom | Cause | Fix |
|---|---|---|
| `kIsWeb` undefined | Missing import | `import 'package:flutter/foundation.dart'` |
| Icon shows as `?` | `CupertinoIcons` on macOS | Use `Icons.*` |
| `No Material widget found` | `ListTile` in Sliver without ancestor | Wrap with `Material(color: Colors.transparent)` |
| `BackdropFilter` has no blur effect | Inside opaque modal | Use `PageRouteBuilder(opaque: false)` |
| Light colors remain after switching to dark mode | Using `platformBrightness` for app-controlled theme | Use `Theme.of(ctx).brightness` and ensure delegates rebuild when brightness changes |
| Bottom nav label clipped | Height too small | Add `MediaQuery.of(ctx).padding.bottom` |
| iOS/macOS build fails due deployment target | Deployment target too low | Set iOS and macOS deployment target to `26.0` in Podfiles and Xcode build settings |
| iOS/macOS build fails due toolchain mismatch | Xcode too old for iOS 26/macOS 26 targets | Use Xcode `26+` |
| `Can't find ')' to match '('` | Mismatched brackets from patching | Rewrite the full class cleanly |

---

## ✅ Pre-change Checklist

Before writing or editing any code, confirm:

- [ ] Platform check uses `_isApple` getter (not hardcoded)
- [ ] Theme-aware UI uses `Theme.of(context).brightness` for app-controlled theme modes
- [ ] No `CupertinoIcons` used
- [ ] No `CupertinoListTile` used
- [ ] `ListTile` inside `SliverList`/`CustomScrollView` is wrapped with `Material`
- [ ] Blur overlays use `PageRouteBuilder(opaque: false)`, not `showModalBottomSheet`
- [ ] Colors use `AppColors.*`
- [ ] All visible user strings use `AppLocalizations` (no hardcoded text)
- [ ] Error/exception messages shown to users are localized (no hardcoded throws)
- [ ] `Scaffold` has `extendBody: true` when using liquid glass nav bar
- [ ] Nav bar height includes `MediaQuery.of(ctx).padding.bottom`
- [ ] Tested mentally on macOS/iOS path AND Android path

---

## 🧾 Commit Messages (Conventional Commits)

Format:

```text
<type>(<scope>): <description>
```

Examples:
- `fix(theme): apply app-theme brightness immediately`
- `docs(readme): add commit message validation commands`

Validate latest commit subject:

```bash
git log -1 --pretty=%s | grep -E '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?: .+'
```

Install repo-managed hooks (Husky-like):

```bash
./scripts/install_git_hooks.sh
```
