#!/usr/bin/env python3
"""Builds the Bedug landing page into site/dist.

Content lives in site/i18n/<locale>.json, links in site/config.json and the
styles in site/static/. The fonts and the icon are copied from the app's own
assets so the brand has one source. Standard library only, so Cloudflare
Pages can run it as the build command: `python3 site/build.py`.
"""

import hashlib
import html
import json
import shutil
from pathlib import Path

SITE = Path(__file__).resolve().parent
ROOT = SITE.parent
DIST = SITE / "dist"
FONTS = ROOT / "assets" / "fonts" / "plus_jakarta_sans"
BRANDING = ROOT / "assets" / "branding"

# Only the weights the stylesheet uses.
FONT_FILES = (
    "PlusJakartaSans-Regular.ttf",
    "PlusJakartaSans-SemiBold.ttf",
    "PlusJakartaSans-ExtraBold.ttf",
)

# 24×24 stroke icons drawn with currentColor.
ICONS = {
    "clock": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    "bell": '<path d="M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/>',
    "calendar": '<rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 10h18M8 3v4M16 3v4"/>',
    "compass": '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>',
    "pin": '<path d="M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>',
    "globe": '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
    "devices": '<rect x="2" y="4" width="14" height="10" rx="1.5"/><path d="M6 18h6M9 14v4"/><rect x="17" y="8" width="5" height="12" rx="1.5"/>',
    "shield": '<path d="M12 3l7 3v5c0 5-3.5 8.5-7 10-3.5-1.5-7-5-7-10V6z"/><path d="M9 12l2 2 4-4"/>',
    "heart": '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>',
    "phone": '<rect x="6" y="2" width="12" height="20" rx="3"/><path d="M10.5 18.5h3"/>',
    "laptop": '<rect x="4" y="4" width="16" height="11" rx="1.5"/><path d="M2 19h20"/>',
    "monitor": '<rect x="3" y="4" width="18" height="12" rx="1.5"/><path d="M8 20h8M12 16v4"/>',
    "check": '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    "github": '<path d="M9 19c-4 1.3-4-2-6-2.5M15 21v-3.5c0-1 .1-1.4-.5-2 2.8-.3 5.5-1.4 5.5-6a4.6 4.6 0 0 0-1.3-3.2 4.2 4.2 0 0 0-.1-3.2s-1-.3-3.4 1.3a11.6 11.6 0 0 0-6.2 0C6.6 2.8 5.6 3.1 5.6 3.1a4.2 4.2 0 0 0-.1 3.2A4.6 4.6 0 0 0 4.2 9.5c0 4.6 2.7 5.7 5.5 6-.6.6-.6 1.2-.5 2V21"/>',
}

PRAYERS = ("fajr", "dhuhr", "asr", "maghrib", "isha")


def icon(name, cls="icon"):
    return (
        f'<svg class="{cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
        f'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" '
        f'aria-hidden="true">{ICONS[name]}</svg>'
    )


def attr(text):
    return html.escape(text, quote=True)


class Site:
    def __init__(self):
        self.config = json.loads((SITE / "config.json").read_text())
        self.locales = self.config["locales"]
        self.default = self.config["default_locale"]
        self.strings = {
            loc: json.loads((SITE / "i18n" / f"{loc}.json").read_text())
            for loc in self.locales
        }
        self.css_name = None

    # Paths --------------------------------------------------------------

    def prefix(self, loc):
        """URL path of a locale's home, e.g. "/" or "/en/"."""
        return "/" if loc == self.default else f"/{loc}/"

    def url(self, loc, page):
        return self.prefix(loc) + ("privacy/" if page == "privacy" else "")

    def fill(self, text):
        """Replaces {link} placeholders in content with configured URLs."""
        for key, value in self.config["links"].items():
            text = text.replace("{" + key + "}", value)
        return text

    # Shared chrome ------------------------------------------------------

    def head(self, loc, page, title, description):
        s = self.strings[loc]
        base = self.config["site_url"]
        alternates = "\n".join(
            f'<link rel="alternate" hreflang="{other}" href="{base}{self.url(other, page)}">'
            for other in self.locales
        )
        return f"""<!doctype html>
<html lang="{loc}" dir="{s['dir']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{attr(title)}</title>
<meta name="description" content="{attr(description)}">
<meta name="theme-color" content="#f7f4ee" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#0e1512" media="(prefers-color-scheme: dark)">
<link rel="canonical" href="{base}{self.url(loc, page)}">
{alternates}
<link rel="alternate" hreflang="x-default" href="{base}{self.url(self.default, page)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Bedug">
<meta property="og:title" content="{attr(title)}">
<meta property="og:description" content="{attr(description)}">
<meta property="og:url" content="{base}{self.url(loc, page)}">
<meta property="og:image" content="{base}/assets/icon.png">
<meta property="og:locale" content="{s['og_locale']}">
<link rel="icon" href="/assets/icon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/assets/icon.png">
<link rel="preload" href="/assets/fonts/PlusJakartaSans-ExtraBold.ttf" as="font" type="font/ttf" crossorigin>
<link rel="stylesheet" href="/assets/{self.css_name}">
</head>
<body>
<a class="skip" href="#main">{s['skip']}</a>"""

    def language_menu(self, loc, page):
        s = self.strings[loc]
        items = "".join(
            f'<li><a href="{self.url(other, page)}" hreflang="{other}" lang="{other}"'
            + (' aria-current="true"' if other == loc else "")
            + f">{self.strings[other]['lang_name']}</a></li>"
            for other in self.locales
        )
        return f"""<details class="lang">
<summary aria-label="{attr(s['language'])}">{icon('globe')}<span>{s['lang_name']}</span></summary>
<ul>{items}</ul>
</details>"""

    def header(self, loc, page):
        s = self.strings[loc]
        home = self.prefix(loc)
        # On the privacy page the section links point back to the home page.
        anchor = "" if page == "home" else home
        nav = "".join(
            f'<a href="{anchor}#{key}">{s["nav"][key]}</a>'
            for key in ("features", "download", "infaq", "roadmap")
        )
        return f"""<header class="top">
<div class="wrap top-inner">
<a class="brand" href="{home}"><img src="/assets/icon.svg" alt="" width="32" height="32"><span>Bedug</span></a>
<nav class="top-nav" aria-label="{attr(s['nav_label'])}">{nav}</nav>
{self.language_menu(loc, page)}
</div>
</header>"""

    def footer(self, loc, page):
        s = self.strings[loc]
        links = self.config["links"]
        return f"""<footer class="foot">
<div class="wrap foot-inner">
<div class="foot-brand">
<a class="brand" href="{self.prefix(loc)}"><img src="/assets/icon.svg" alt="" width="28" height="28"><span>Bedug</span></a>
<p>{s['footer_tagline']}</p>
</div>
<nav class="foot-links" aria-label="{attr(s['footer_label'])}">
<a href="{self.url(loc, 'privacy')}">{s['nav']['privacy']}</a>
<a href="{links['repo']}">{icon('github')}GitHub</a>
<a href="{links['issues']}">{s['footer_contact']}</a>
</nav>
<p class="foot-copy">© 2026 Ardeman</p>
</div>
</footer>
</body>
</html>
"""

    # Home ---------------------------------------------------------------

    def mock(self, s):
        m = s["mock"]
        # The mock shows Asr as the next prayer.
        rows = "".join(
            ('<li class="now">' if key == "asr" else "<li>")
            + f"<span>{s['prayers'][key]}</span><time>{m['times'][i]}</time></li>"
            for i, key in enumerate(PRAYERS)
        )
        return f"""<div class="phone" role="img" aria-label="{attr(m['label'])}">
<div class="phone-screen">
<div class="phone-hero">
<p class="phone-place">{icon('pin')}{m['place']}</p>
<p class="phone-hijri">{m['hijri']}</p>
<p class="phone-next">{s['next_prayer']}</p>
<p class="phone-name">{s['prayers']['asr']}</p>
<p class="phone-count" dir="ltr">−01:24:37</p>
</div>
<ul class="phone-list">{rows}</ul>
</div>
</div>"""

    def store_card(self, loc, store):
        s = self.strings[loc]
        label = s["stores"][store["id"]]
        url = store.get("url")
        inner = (
            f'{icon(store["icon"], "icon store-icon")}'
            f'<span class="store-text"><strong>{label["name"]}</strong>'
            f'<span>{label["devices"]}</span></span>'
        )
        if url:
            return f'<a class="store" href="{url}">{inner}<span class="chip chip-go">{s["download"]["get"]}</span></a>'
        return f'<div class="store is-soon">{inner}<span class="chip">{s["download"]["coming_soon"]}</span></div>'

    def infaq_links(self, loc):
        s = self.strings[loc]
        infaq = self.config["infaq"]
        # Trakteer (QRIS, e-wallets) suits Indonesian readers; Ko-fi suits the rest.
        order = ("trakteer", "kofi") if loc == "id" else ("kofi", "trakteer")
        buttons = [
            f'<a class="btn btn-gold" href="{infaq[key]}">{icon("heart")}{s["infaq"]["via"][key]}</a>'
            for key in order
            if infaq.get(key)
        ]
        if not buttons:
            return f'<p class="note">{s["infaq"]["links_soon"]}</p>'
        return f'<div class="btn-row">{"".join(buttons)}</div>'

    def home(self, loc):
        s = self.strings[loc]
        features = "".join(
            f'<li class="card">{icon(f["icon"], "icon card-icon")}<h3>{f["title"]}</h3><p>{f["body"]}</p></li>'
            for f in s["features"]["items"]
        )
        stores = "".join(self.store_card(loc, st) for st in self.config["stores"])
        infaq_points = "".join(
            f"<li>{icon('check')}<span>{p}</span></li>" for p in s["infaq"]["points"]
        )
        roadmap = "".join(
            f'<li><span class="phase">{r["phase"]}</span><h3>{r["title"]}</h3><p>{r["body"]}</p></li>'
            for r in s["roadmap"]["items"]
        )
        badges = "".join(f"<li>{b}</li>" for b in s["hero"]["badges"])
        return (
            self.head(loc, "home", s["meta"]["title"], s["meta"]["description"])
            + self.header(loc, "home")
            + f"""
<main id="main">
<section class="hero">
<div class="wrap hero-inner">
<div class="hero-copy">
<p class="eyebrow">{s['hero']['eyebrow']}</p>
<h1>{s['hero']['title']}</h1>
<p class="lead">{s['hero']['lead']}</p>
<div class="btn-row">
<a class="btn btn-primary" href="#download">{s['hero']['cta_download']}</a>
<a class="btn btn-ghost" href="#infaq">{icon('heart')}{s['hero']['cta_infaq']}</a>
</div>
<ul class="badges">{badges}</ul>
</div>
{self.mock(s)}
</div>
</section>

<section id="features" class="section">
<div class="wrap">
<h2>{s['features']['title']}</h2>
<p class="section-lead">{s['features']['lead']}</p>
<ul class="grid">{features}</ul>
</div>
</section>

<section id="download" class="section section-alt">
<div class="wrap">
<h2>{s['download']['title']}</h2>
<p class="section-lead">{s['download']['lead']}</p>
<div class="stores">{stores}</div>
<p class="note">{s['download']['note']}</p>
</div>
</section>

<section id="infaq" class="section">
<div class="wrap infaq">
<div class="infaq-mark">{icon('heart', 'icon infaq-icon')}</div>
<div>
<h2>{s['infaq']['title']}</h2>
<p class="section-lead">{s['infaq']['lead']}</p>
<ul class="ticks">{infaq_points}</ul>
<p class="note">{s['infaq']['in_app']}</p>
{self.infaq_links(loc)}
</div>
</div>
</section>

<section id="roadmap" class="section section-alt">
<div class="wrap">
<h2>{s['roadmap']['title']}</h2>
<p class="section-lead">{s['roadmap']['lead']}</p>
<ol class="roadmap">{roadmap}</ol>
<p class="note">{self.fill(s['roadmap']['follow'])}</p>
</div>
</section>
</main>
"""
            + self.footer(loc, "home")
        )

    # Privacy ------------------------------------------------------------

    def privacy(self, loc):
        s = self.strings[loc]
        p = s["privacy"]
        sections = "".join(
            f'<section><h2>{sec["heading"]}</h2>'
            + "".join(f"<p>{self.fill(par)}</p>" for par in sec["body"])
            + "</section>"
            for sec in p["sections"]
        )
        return (
            self.head(loc, "privacy", p["meta_title"], p["meta_description"])
            + self.header(loc, "privacy")
            + f"""
<main id="main" class="section">
<article class="wrap prose">
<h1>{p['title']}</h1>
<p class="updated">{p['updated']}</p>
<p class="lead">{p['intro']}</p>
<div class="summary">
<h2>{p['summary_title']}</h2>
<ul class="ticks">{''.join(f"<li>{icon('check')}<span>{x}</span></li>" for x in p['summary'])}</ul>
</div>
{sections}
</article>
</main>
"""
            + self.footer(loc, "privacy")
        )

    # 404 ----------------------------------------------------------------

    def not_found(self):
        # One page for every locale: Cloudflare Pages serves /404.html for any
        # missing path, so it shows each language's short message.
        loc = self.default
        s = self.strings[loc]
        messages = "".join(
            f'<div lang="{other}" dir="{self.strings[other]["dir"]}">'
            f'<h1>{self.strings[other]["not_found"]["title"]}</h1>'
            f'<p><a class="btn btn-primary" href="{self.prefix(other)}">{self.strings[other]["not_found"]["home"]}</a></p></div>'
            for other in self.locales
        )
        return (
            self.head(loc, "home", "404 · Bedug", s["meta"]["description"])
            + f'<main id="main" class="section"><div class="wrap not-found">'
            + f'<img src="/assets/icon.svg" alt="" width="96" height="96">{messages}</div></main>\n</body>\n</html>\n'
        )

    # Output -------------------------------------------------------------

    def sitemap(self):
        base = self.config["site_url"]
        entries = []
        for page in ("home", "privacy"):
            alternates = "".join(
                f'<xhtml:link rel="alternate" hreflang="{other}" href="{base}{self.url(other, page)}"/>'
                for other in self.locales
            )
            for loc in self.locales:
                entries.append(
                    f"<url><loc>{base}{self.url(loc, page)}</loc>{alternates}</url>"
                )
        return (
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" '
            'xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
            + "\n".join(entries)
            + "\n</urlset>\n"
        )

    def write(self, rel, text):
        path = DIST / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    def build(self):
        shutil.rmtree(DIST, ignore_errors=True)
        assets = DIST / "assets"
        (assets / "fonts").mkdir(parents=True)

        # Hash the stylesheet name so it can be cached for good.
        css = (SITE / "static" / "style.css").read_text()
        digest = hashlib.sha256(css.encode()).hexdigest()[:10]
        self.css_name = f"style.{digest}.css"
        (assets / self.css_name).write_text(css)

        for name in FONT_FILES:
            shutil.copy(FONTS / name, assets / "fonts" / name)
        shutil.copy(FONTS / "OFL.txt", assets / "fonts" / "OFL.txt")
        shutil.copy(BRANDING / "icon.svg", assets / "icon.svg")
        shutil.copy(SITE / "static" / "icon-512.png", assets / "icon.png")
        for name in ("_headers", "robots.txt"):
            shutil.copy(SITE / "static" / name, DIST / name)

        for loc in self.locales:
            base = "" if loc == self.default else f"{loc}/"
            self.write(f"{base}index.html", self.home(loc))
            self.write(f"{base}privacy/index.html", self.privacy(loc))
        self.write("404.html", self.not_found())
        self.write("sitemap.xml", self.sitemap())
        print(f"Built {len(self.locales)} locales into {DIST.relative_to(ROOT)}")


if __name__ == "__main__":
    Site().build()
