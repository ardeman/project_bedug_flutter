# 🤝 Contributing to Bedug

Thank you for your interest in contributing! This guide covers everything you need to know before submitting changes.

> **Using an AI assistant?** Read [README_AGENT.md](./README_AGENT.md) first — it contains critical rules specific to this codebase that prevent common mistakes.

---

## 📋 Before You Start

- Read [README.md](./README.md) for project overview
- Read [README_AGENT.md](./README_AGENT.md) for technical rules and gotchas
- Check existing issues before opening a new one
- For large changes, open an issue first to discuss

---

## 🌿 Branch Naming

```
feature/your-feature-name     # new feature
fix/short-description         # bug fix
refactor/what-changed         # refactor, no behavior change
docs/what-changed             # documentation only
```

---

## 🧾 Commit Messages (Conventional Commits)

Use this format:

```text
<type>(<scope>): <description>
```

Examples:
- `fix(theme): apply app-theme brightness immediately`
- `docs(contributing): add commit validation commands`

Recommended types:
- `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `build`, `ci`, `perf`, `style`, `revert`

Validate your latest commit subject:

```bash
git log -1 --pretty=%s | grep -E '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?: .+'
```

Install repo-managed hooks (Husky-like):

```bash
./scripts/install_git_hooks.sh
```

Quick test (should fail):

```bash
git commit --allow-empty -m "bad message"
```

---

## 💻 Development Setup

```bash
git clone https://github.com/yourusername/bedug.git
cd bedug
flutter pub get
flutter gen-l10n
flutter run -d macos   # recommended for primary testing
```

---

## ✅ Contribution Checklist

Before opening a pull request, make sure:

### Code Quality
- [ ] No hardcoded colors — use `AppColors.*`
- [ ] No hardcoded strings — use `AppLocalizations.of(context).*`
- [ ] No `print()` statements left in code
- [ ] No unused imports

### Platform Adaptive UI
- [ ] UI changes tested on **both** Apple (macOS/iOS) and Material (Android) paths
- [ ] Platform check uses `_isApple` getter — never hardcoded `Platform.isIOS` alone
- [ ] Theme-aware colors use `Theme.of(context).brightness` when app theme mode is user-controlled
- [ ] No `CupertinoIcons` — use `Icons.*` instead
- [ ] No `CupertinoListTile` — use `ListTile` with `Material` ancestor
- [ ] Blur overlays use `PageRouteBuilder(opaque: false)` — not `showModalBottomSheet`
- [ ] Native non-blur Apple sheets (e.g. `CupertinoActionSheet`) are acceptable when native behavior is intended

### Liquid Glass (Apple platforms)
- [ ] `Scaffold` has `extendBody: true` when using liquid glass nav bar
- [ ] `Scaffold` has `extendBodyBehindAppBar: true` when using liquid glass app bar
- [ ] Nav bar height includes `MediaQuery.of(ctx).padding.bottom`
- [ ] `ListTile` inside `SliverList` is wrapped with `Material(color: Colors.transparent)`
- [ ] Apple landscape screens account for left/right safe-area insets (no clipped trailing text near cutouts)
- [ ] Apple collapsing headers do not overflow at compact heights

### Localization
- [ ] New user-facing strings added to all 4 ARB files (`id`, `en`, `ar`, `ms`)
- [ ] `flutter gen-l10n` run after ARB changes
- [ ] No hardcoded Indonesian/English text in widgets

### General
- [ ] `flutter analyze` passes with no errors
- [ ] App builds successfully on macOS: `flutter build macos`

---

## 🌍 Adding a New Language

1. Create `lib/l10n/app_XX.arb` (where `XX` = language code)
2. Copy all keys from `app_id.arb` and translate values
3. Run `flutter gen-l10n`
4. Add locale to `supportedLocales` in `app.dart`
5. Test by changing language in Settings screen

---

## 🐛 Reporting Bugs

Please include:

- **Platform** (macOS 14.x / iOS 17.x / Android 14 / etc.)
- **Flutter version** (`flutter --version`)
- **Steps to reproduce**
- **Expected vs actual behavior**
- **Screenshot or screen recording** if UI-related

---

## 💡 Suggesting Features

Open a GitHub issue with:

- Clear description of the feature
- Which platform(s) it applies to
- Which design system it should follow (Liquid Glass / Material / Fluent)
- Mockup or reference if available

---

## 📐 Code Style

Follow standard Dart/Flutter conventions:

```dart
// ✅ Good — follows in-app theme mode
final isDark = Theme.of(ctx).brightness == Brightness.dark;

// ✅ Good — private classes prefixed with _
class _LiquidGlassCard extends StatelessWidget { ... }

// ✅ Good — const where possible
const EdgeInsets.symmetric(horizontal: 16, vertical: 5)

// ❌ Avoid — magic numbers without context
Container(height: 64.5)

// ✅ Better — named or explained
Container(height: kToolbarHeight + MediaQuery.of(ctx).padding.top)
```

---

## 📬 Pull Request Template

```
## Summary
Brief description of what changed and why.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Refactor
- [ ] Documentation

## Platforms Tested
- [ ] macOS
- [ ] iOS
- [ ] Android
- [ ] Windows
- [ ] Linux

## Checklist
- [ ] Contribution checklist above completed
- [ ] `flutter analyze` passes
- [ ] `flutter build macos` succeeds
```
