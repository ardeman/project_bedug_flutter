#!/usr/bin/env python3
"""Fills the ayah of the day's text in assets/content/quran/daily_ayahs.json.

The file is curated by hand: occasions and themes, each with its reason and
its ayahs as `surah:ayah` refs. This script adds each ayah's Arabic text and
translations from the reader's files (written by build_quran_content.py), so
the prayer-times screen and the home screen widget show it without loading
the whole Quran. The text is copied verbatim, without the basmala Tanzil
puts before each first ayah. Run from the repository root after editing the
refs or rebuilding the Quran content:

  python3 scripts/build_daily_ayahs.py
"""

import json
import pathlib

QURAN = pathlib.Path("assets/content/quran")
DAILY = QURAN / "daily_ayahs.json"

# Language → the file with its text; Arabic readers read the text itself.
TEXTS = {
    "ar": "text.json",
    "id": "translation_id.json",
    "en": "translation_en.json",
    "ms": "translation_ms.json",
}


def load(name):
    return json.loads((QURAN / name).read_text(encoding="utf-8"))["surahs"]


def ayah(surahs, ref):
    surah, number = (int(part) for part in ref.split(":"))
    if not 1 <= surah <= len(surahs) or not 1 <= number <= len(surahs[surah - 1]):
        raise SystemExit(f"No ayah {ref}")
    text = surahs[surah - 1][number - 1]
    # Matches ayahWithoutBasmala in lib/features/quran/quran.dart.
    basmala = surahs[0][0] + " "
    if surah not in (1, 9) and number == 1 and text.startswith(basmala):
        text = text[len(basmala):]
    return text


def main():
    texts = {language: load(name) for language, name in TEXTS.items()}
    daily = json.loads(DAILY.read_text(encoding="utf-8"))
    for group in daily["occasions"] + daily["themes"]:
        for entry in group["ayahs"]:
            entry["text"] = {
                language: ayah(surahs, entry["ref"])
                for language, surahs in texts.items()
            }
    DAILY.write_text(
        json.dumps(daily, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
