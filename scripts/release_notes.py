#!/usr/bin/env python3
"""Writes the GitHub Release notes in English and Indonesian.

Usage: scripts/release_notes.py <version> <repo> <tag> > notes.md

The changes come from the release with that version in
assets/changelog/changelog.json; a table tells users which file to download.
The build number comes from `version:` in pubspec.yaml, which the builds use.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

TITLES = {
    "en": {"new": "New", "improved": "Improved", "fixed": "Fixed"},
    "id": {"new": "Baru", "improved": "Disempurnakan", "fixed": "Diperbaiki"},
}

# (file, English, Indonesian)
FILES = [
    ("bedug-android.apk", "Android phones and tablets", "Ponsel dan tablet Android"),
    ("bedug-windows.zip", "Windows 10 and 11 PCs (64-bit)", "PC Windows 10 dan 11 (64-bit)"),
    ("bedug-macos.zip", "Macs with Apple silicon, macOS 26 or later", "Mac dengan Apple silicon, macOS 26 atau lebih baru"),
    ("bedug-linux.tar.gz", "Linux PCs (64-bit)", "PC Linux (64-bit)"),
]

TEXT = {
    "en": {
        "new": "### What's new",
        "which": "### Which file?",
        "head": "| File | For |",
        "before": "### Before you install",
        "notes": [
            "- **Test build:** this is not the store version. The Android APK is signed with a debug key and the macOS app is not signed, so Android may ask you to allow installs from this source and macOS may warn you.",
            "- **Android:** open the APK and allow the install. An APK signed differently (such as a store copy) can't be installed over this one.",
            "- **Windows:** extract the zip (right-click → Extract All) and open `bedug.exe`. If Windows says it protected your PC, choose More info → Run anyway.",
            "- **Mac:** open the zip and drag Bedug into Applications. The first time, Control-click it and choose Open, or run `xattr -dr com.apple.quarantine /Applications/bedug.app`.",
            "- **Linux:** extract with `tar -xzf bedug-linux.tar.gz` and run `bundle/bedug`. It needs GTK 3 and GStreamer.",
        ],
    },
    "id": {
        "new": "### Yang baru",
        "which": "### File yang mana?",
        "head": "| File | Untuk |",
        "before": "### Sebelum memasang",
        "notes": [
            "- **Versi uji:** ini bukan versi toko. APK Android ditandatangani dengan kunci debug dan aplikasi macOS belum ditandatangani, jadi Android mungkin meminta izin memasang dari sumber ini dan macOS mungkin memberi peringatan.",
            "- **Android:** buka APK lalu izinkan pemasangan. APK yang ditandatangani berbeda (misalnya salinan dari toko) tidak bisa dipasang di atas yang ini.",
            "- **Windows:** ekstrak zip-nya (klik kanan → Extract All) lalu buka `bedug.exe`. Jika Windows bilang telah melindungi PC kamu, pilih More info → Run anyway.",
            "- **Mac:** buka zip-nya lalu seret Bedug ke Applications. Pertama kali, klik sambil menahan Control lalu pilih Open, atau jalankan `xattr -dr com.apple.quarantine /Applications/bedug.app`.",
            "- **Linux:** ekstrak dengan `tar -xzf bedug-linux.tar.gz` lalu jalankan `bundle/bedug`. Perlu GTK 3 dan GStreamer.",
        ],
    },
}


def build_number(version):
    """The build number in pubspec.yaml when it holds this version."""
    for line in (ROOT / "pubspec.yaml").read_text().splitlines():
        if line.startswith("version:"):
            name, _, build = line.split(":", 1)[1].strip().partition("+")
            return build if name == version and build else None
    return None


def release_changes(version):
    data = json.loads((ROOT / "assets/changelog/changelog.json").read_text())
    for release in data["releases"]:
        if release["version"] == version:
            return release["changes"]
    sys.exit(f"No release {version} in assets/changelog/changelog.json.")


def language_notes(lang, version, build, changes, download):
    text = TEXT[lang]
    out = []
    if build:
        label = "Version" if lang == "en" else "Versi"
        out += [f"{label} {version} (build {build})", ""]
    out += [text["new"], ""]
    for kind in ("new", "improved", "fixed"):
        items = [c["text"][lang] for c in changes if c["type"] == kind]
        if items:
            out += [f"**{TITLES[lang][kind]}**", ""]
            out += [f"- {item}" for item in items]
            out.append("")
    out += [text["which"], "", text["head"], "|---|---|"]
    for name, en, idn in FILES:
        out.append(f"| [`{name}`]({download}/{name}) | {en if lang == 'en' else idn} |")
    out += ["", text["before"], ""]
    out += text["notes"]
    out.append(
        "- **Checksums:** `SHA256SUMS.txt` lists each file's SHA-256."
        if lang == "en"
        else "- **Checksum:** `SHA256SUMS.txt` berisi SHA-256 tiap file."
    )
    return out


def main():
    version, repo, tag = sys.argv[1:4]
    changes = release_changes(version)
    build = build_number(version)
    download = f"https://github.com/{repo}/releases/download/{tag}"
    # The blank lines around the Markdown inside <details> are required.
    lines = ['<details open><summary><b>English</b></summary>', ""]
    lines += language_notes("en", version, build, changes, download)
    lines += ["", "</details>", "<details><summary><b>Bahasa Indonesia</b></summary>", ""]
    lines += language_notes("id", version, build, changes, download)
    lines += ["", "</details>"]
    print("\n".join(lines))


if __name__ == "__main__":
    main()
