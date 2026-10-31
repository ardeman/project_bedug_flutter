#!/usr/bin/env python3
"""Builds the Quran reader's content in assets/content/quran/ from Tanzil.

Downloads the Uthmani text, the translations and the surah metadata from
tanzil.net and writes them as JSON:

  surahs.json          surah names, ayah counts, revelation place, juz and
                       mushaf page starts
  text.json            the Arabic text, one list of ayahs per surah
  translation_XX.json  each language's translation in the same shape

The text is kept verbatim, with Tanzil's copyright block, as its license
requires. Run from the repository root:

  python3 scripts/build_quran_content.py
"""

import json
import pathlib
import urllib.request
import xml.etree.ElementTree as ElementTree

OUT = pathlib.Path("assets/content/quran")

TEXT_URL = (
    "https://tanzil.net/pub/download/index.php?marks=true&sajdah=true"
    "&rub=false&tatweel=true&quranType=uthmani&outType=txt-2&agree=true"
)
TRANSLATION_URL = "https://tanzil.net/trans/?transID={}&type=txt-2"
METADATA_URL = "https://tanzil.net/res/text/metadata/quran-data.xml"

# App language → Tanzil translation ID. Arabic readers read the text itself.
TRANSLATIONS = {
    "id": "id.indonesian",
    "en": "en.sahih",
    "ms": "ms.basmeih",
}

# Surah names as transliterated by Kemenag RI, also used for Malay. English
# uses Tanzil's transliteration and Arabic the name itself.
KEMENAG_NAMES = [
    "Al-Fatihah", "Al-Baqarah", "Ali 'Imran", "An-Nisa'", "Al-Ma'idah",
    "Al-An'am", "Al-A'raf", "Al-Anfal", "At-Taubah", "Yunus", "Hud", "Yusuf",
    "Ar-Ra'd", "Ibrahim", "Al-Hijr", "An-Nahl", "Al-Isra'", "Al-Kahf",
    "Maryam", "Taha", "Al-Anbiya'", "Al-Hajj", "Al-Mu'minun", "An-Nur",
    "Al-Furqan", "Asy-Syu'ara'", "An-Naml", "Al-Qasas", "Al-'Ankabut",
    "Ar-Rum", "Luqman", "As-Sajdah", "Al-Ahzab", "Saba'", "Fatir", "Yasin",
    "As-Saffat", "Sad", "Az-Zumar", "Gafir", "Fussilat", "Asy-Syura",
    "Az-Zukhruf", "Ad-Dukhan", "Al-Jasiyah", "Al-Ahqaf", "Muhammad",
    "Al-Fath", "Al-Hujurat", "Qaf", "Az-Zariyat", "At-Tur", "An-Najm",
    "Al-Qamar", "Ar-Rahman", "Al-Waqi'ah", "Al-Hadid", "Al-Mujadalah",
    "Al-Hasyr", "Al-Mumtahanah", "As-Saff", "Al-Jumu'ah", "Al-Munafiqun",
    "At-Tagabun", "At-Talaq", "At-Tahrim", "Al-Mulk", "Al-Qalam", "Al-Haqqah",
    "Al-Ma'arij", "Nuh", "Al-Jinn", "Al-Muzzammil", "Al-Muddassir",
    "Al-Qiyamah", "Al-Insan", "Al-Mursalat", "An-Naba'", "An-Nazi'at",
    "'Abasa", "At-Takwir", "Al-Infitar", "Al-Mutaffifin", "Al-Insyiqaq",
    "Al-Buruj", "At-Tariq", "Al-A'la", "Al-Gasyiyah", "Al-Fajr", "Al-Balad",
    "Asy-Syams", "Al-Lail", "Ad-Duha", "Asy-Syarh", "At-Tin", "Al-'Alaq",
    "Al-Qadr", "Al-Bayyinah", "Az-Zalzalah", "Al-'Adiyat", "Al-Qari'ah",
    "At-Takasur", "Al-'Asr", "Al-Humazah", "Al-Fil", "Quraisy", "Al-Ma'un",
    "Al-Kausar", "Al-Kafirun", "An-Nasr", "Al-Lahab", "Al-Ikhlas",
    "Al-Falaq", "An-Nas",
]


def fetch(url):
    with urllib.request.urlopen(url) as response:
        return response.read().decode("utf-8")


def parse_tanzil(source, ayah_counts):
    """Splits a Tanzil `surah|ayah|text` file into its ayahs and its notice."""
    ayahs = [[] for _ in ayah_counts]
    notice = []
    for line in source.splitlines():
        if line.startswith("#"):
            notice.append(line[1:].strip())
        elif line.strip():
            surah, ayah, text = line.split("|", 2)
            assert int(ayah) == len(ayahs[int(surah) - 1]) + 1, line
            ayahs[int(surah) - 1].append(text.strip())
    assert [len(a) for a in ayahs] == ayah_counts
    return ayahs, "\n".join(line for line in notice if line).strip()


def notice_field(notice, name):
    for line in notice.splitlines():
        if line.startswith(f"{name}:"):
            return line.split(":", 1)[1].strip()
    raise ValueError(f"{name} missing from the notice")


def write(name, data):
    path = OUT / name
    path.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(f"{path}: {path.stat().st_size // 1024} KB")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    metadata = ElementTree.fromstring(fetch(METADATA_URL))
    suras = metadata.findall("./suras/sura")
    assert len(suras) == len(KEMENAG_NAMES) == 114
    ayah_counts = [int(s.get("ayas")) for s in suras]

    write("surahs.json", {
        "surahs": [
            {
                "arabic": s.get("name"),
                "name": {"id": kemenag, "en": s.get("tname"), "ms": kemenag},
                "ayahs": int(s.get("ayas")),
                "revelation": "meccan" if s.get("type") == "Meccan" else "medinan",
            }
            for s, kemenag in zip(suras, KEMENAG_NAMES)
        ],
        "juz": [
            [int(j.get("sura")), int(j.get("aya"))]
            for j in metadata.findall("./juzs/juz")
        ],
        "pages": [
            [int(p.get("sura")), int(p.get("aya"))]
            for p in metadata.findall("./pages/page")
        ],
    })

    ayahs, notice = parse_tanzil(fetch(TEXT_URL), ayah_counts)
    write("text.json", {
        "source": "Tanzil Quran Text (Uthmani 1.1), tanzil.net, CC BY 3.0",
        "notice": notice,
        "surahs": ayahs,
    })

    for language, translation_id in TRANSLATIONS.items():
        ayahs, notice = parse_tanzil(
            fetch(TRANSLATION_URL.format(translation_id)), ayah_counts
        )
        write(f"translation_{language}.json", {
            "source": f"{notice_field(notice, 'Translator')}, via tanzil.net",
            "notice": notice,
            "surahs": ayahs,
        })


if __name__ == "__main__":
    main()
