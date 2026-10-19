# 🤝 Contributing to Bedug

Thank you for your interest in contributing!

- [README.md](./README.md) covers setup, commands, the Checks to run and the commit message format.
- [AGENTS.md](./AGENTS.md) holds the code rules (platform design, liquid glass, localization, guardrails). They apply to humans too.
- Check existing issues before opening a new one, and open an issue first for large changes.

---

## 🌿 Branch Naming

```
feature/your-feature-name     # new feature
fix/short-description         # bug fix
refactor/what-changed         # refactor, no behavior change
docs/what-changed             # documentation only
```

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
- [ ] Rules in AGENTS.md followed
- [ ] Checks pass (`flutter analyze && flutter test`)
- [ ] `flutter build macos` succeeds
```
