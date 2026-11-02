"""Generated page contracts; run from the repository root with unittest."""
import importlib.util
import json
import unittest
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("bedug_site", ROOT / "site/build.py")
BUILD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILD)


class Page(HTMLParser):
    def __init__(self, source):
        super().__init__()
        self.elements = []
        self.feed(source)

    def handle_starttag(self, tag, attrs):
        self.elements.append((tag, dict(attrs)))


class LandingPageTest(unittest.TestCase):
    def setUp(self):
        self.site = BUILD.Site()
        self.site.css_name = "style.test.css"

    def test_every_language_has_matching_keys(self):
        def keys(value, prefix=""):
            result = set()
            if isinstance(value, dict):
                for key, child in value.items():
                    result.add(prefix + key)
                    result.update(keys(child, prefix + key + "."))
            return result
        expected = keys(self.site.strings["en"])
        for locale, strings in self.site.strings.items():
            self.assertEqual(keys(strings), expected, locale)

    def test_localized_pages_work_without_scripts(self):
        for locale in self.site.locales:
            with self.subTest(locale=locale):
                source = self.site.home(locale)
                page = Page(source)
                ids = [a["id"] for _, a in page.elements if "id" in a]
                self.assertEqual(len(ids), len(set(ids)))
                for tag, attrs in page.elements:
                    if tag == "a" and attrs.get("href", "").startswith("#"):
                        self.assertIn(attrs["href"][1:], ids)
                    self.assertNotIn("style", attrs)
                    self.assertFalse(any(key.startswith("on") for key in attrs))
                    if "shot" in attrs.get("class", "").split():
                        self.assertTrue(attrs["alt"])
                        self.assertTrue((BUILD.SITE / "static" / attrs["src"].removeprefix("/assets/")).is_file())
                self.assertIn(self.site.strings[locale]["hero"]["eyebrow"], source)
                html = next(a for tag, a in page.elements if tag == "html")
                self.assertEqual(html["dir"], "rtl" if locale == "ar" else "ltr")
                self.assertEqual(sum(tag == "h1" for tag, _ in page.elements), 1)
                self.assertEqual(sum(tag == "script" for tag, _ in page.elements), 1)

    def test_unreleased_notes_keep_all_languages(self):
        latest = json.loads(BUILD.CHANGELOG.read_text())["releases"][0]
        self.assertIsNone(latest["date"])
        for change in latest["changes"]:
            self.assertEqual(set(change["text"]), set(self.site.locales))


if __name__ == "__main__":
    unittest.main()
