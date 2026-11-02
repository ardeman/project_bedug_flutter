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

    def test_hero_shows_the_existing_app_icon_before_the_headline(self):
        for locale in self.site.locales:
            with self.subTest(locale=locale):
                source = self.site.home(locale)
                hero = source.split('<div class="hero-copy">', 1)[1].split('<h1>', 1)[0]
                icons = [attrs for tag, attrs in Page(hero).elements
                         if tag == 'img' and attrs.get('class') == 'hero-icon']
                self.assertEqual(len(icons), 1)
                self.assertEqual(icons[0]['src'], '/assets/icon.svg')
                self.assertEqual(icons[0]['alt'], 'Bedug')

    def test_feature_menu_has_an_accessible_link_to_every_chapter(self):
        for locale in self.site.locales:
            with self.subTest(locale=locale):
                source = self.site.home(locale)
                menu = source.split('<nav class="feature-links"', 1)[1].split('</nav>', 1)[0]
                page = Page('<nav' + menu + '</nav>')
                nav = next(attrs for tag, attrs in page.elements if tag == 'nav')
                self.assertEqual(nav['aria-label'], self.site.strings[locale]['nav']['features'])
                targets = [attrs['href'] for tag, attrs in page.elements if tag == 'a']
                self.assertEqual(targets, [
                    '#feature-' + feature['screen']
                    for feature in self.site.strings[locale]['features']['showcase']
                ])

    def test_language_selector_is_in_footer_on_every_page(self):
        for locale in self.site.locales:
            for render in (self.site.home, self.site.privacy, self.site.changelog):
                with self.subTest(locale=locale, page=render.__name__):
                    source = render(locale)
                    header = source.split('<header', 1)[1].split('</header>', 1)[0]
                    footer = source.split('<footer', 1)[1].split('</footer>', 1)[0]
                    brand = next(attrs for tag, attrs in Page('<header' + header).elements
                                 if tag == 'a' and attrs.get('class') == 'brand')
                    self.assertEqual(brand['aria-label'], 'Bedug')
                    self.assertNotIn('class="lang"', header)
                    self.assertEqual(footer.count('class="lang"'), 1)
                    footer_elements = Page(footer).elements
                    github = next(attrs for tag, attrs in footer_elements
                                  if attrs.get('class') == 'foot-github')
                    self.assertEqual(github['aria-label'], 'GitHub')
                    self.assertEqual(github['href'], self.site.config['links']['repo'])
                    self.assertNotIn(self.site.config['links']['issues'],
                                     [attrs.get('href') for tag, attrs in footer_elements])
                    summary = next(attrs for tag, attrs in footer_elements if tag == 'summary')
                    self.assertEqual(summary['aria-label'], self.site.strings[locale]['language'])
                    menu = footer.split('<details class="lang">', 1)[1].split('</details>', 1)[0]
                    links = [attrs for tag, attrs in Page(menu).elements if tag == 'a']
                    self.assertEqual({a['hreflang'] for a in links}, set(self.site.locales))
                    for link in links:
                        self.assertEqual(link['href'], self.site.url(link['hreflang'], render.__name__))

    def test_unreleased_notes_keep_all_languages(self):
        latest = json.loads(BUILD.CHANGELOG.read_text())["releases"][0]
        self.assertIsNone(latest["date"])
        for change in latest["changes"]:
            self.assertEqual(set(change["text"]), set(self.site.locales))


if __name__ == "__main__":
    unittest.main()
