#!/usr/bin/env python3
"""Writes the store release notes from assets/changelog/changelog.json.

Usage: scripts/store_release_notes.py [version] [--check]

- Google Play: one file per version with every language in Play Console's
  <locale> tags, ready to paste: store/google_play/release_notes/<version>.txt
- App Store: one file per language, for the version being submitted:
  store/app_store/<locale>/release_notes.txt

The version defaults to the newest release. A change's optional "platforms"
list (android, ios, macos, windows, linux, web) keeps it out of stores it
doesn't reach; without it, the change applies to every app platform. Play
uses a change's optional short "store" text, since it allows only 500
characters per language; the App Store gets the full text. A language over
its store's limit fails the run rather than dropping changes.

--check writes nothing and fails if a file is missing or out of date.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHANGELOG = ROOT / "assets/changelog/changelog.json"

# Changelog language → store locale, default listing language first.
LOCALES = {"id": "id", "en": "en-US", "ms": "ms", "ar": "ar"}
ORDER = ("new", "improved", "fixed")
PLAY_LIMIT = 500
APP_STORE_LIMIT = 4000


def release(version):
    releases = json.loads(CHANGELOG.read_text())["releases"]
    if version is None:
        return releases[0]
    for r in releases:
        if r["version"] == version:
            return r
    sys.exit(f"No release {version} in {CHANGELOG.relative_to(ROOT)}.")


def reaches(change, platforms):
    listed = change.get("platforms")
    return listed is None or bool(set(listed) & platforms)


def bullets(changes, lang, key, limit, store):
    picked = sorted(changes, key=lambda c: ORDER.index(c["type"]))
    text = "\n".join(f"• {c.get(key, c['text'])[lang]}" for c in picked)
    if len(text) > limit:
        sys.exit(
            f"{store} notes in {lang} are {len(text)} characters, over the "
            f"{limit} limit. Shorten the changes' \"store\" text."
        )
    return text


def notes(r):
    play_changes = [c for c in r["changes"] if reaches(c, {"android"})]
    apple_changes = [c for c in r["changes"] if reaches(c, {"ios", "macos"})]
    files = {}
    play = []
    for lang, locale in LOCALES.items():
        body = bullets(play_changes, lang, "store", PLAY_LIMIT, "Google Play")
        play.append(f"<{locale}>\n{body}\n</{locale}>")
        apple = bullets(apple_changes, lang, "text", APP_STORE_LIMIT, "App Store")
        files[f"store/app_store/{locale}/release_notes.txt"] = apple + "\n"
    files[f"store/google_play/release_notes/{r['version']}.txt"] = "\n".join(play) + "\n"
    return files


def main():
    args = [a for a in sys.argv[1:] if a != "--check"]
    check = "--check" in sys.argv[1:]
    files = notes(release(args[0] if args else None))
    stale = []
    for name, content in files.items():
        path = ROOT / name
        if check:
            if not path.exists() or path.read_text() != content:
                stale.append(name)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
            print(name)
    if stale:
        sys.exit(
            "Out of date, run scripts/store_release_notes.py:\n  " + "\n  ".join(stale)
        )


if __name__ == "__main__":
    main()
