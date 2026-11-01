#!/usr/bin/env python3
"""Builds the Bedug landing page into site/dist.

Content lives in site/i18n/<locale>.json, links in site/config.json and the
styles, the home page's one script and the app screens in site/static/. The
fonts, the icon and the changelog come from the app's own assets so each has
one source. Standard library only, so Cloudflare
can run it as the build command: `python3 site/build.py`.
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
CHANGELOG = ROOT / "assets" / "changelog" / "changelog.json"

# Only the weights the stylesheet uses.
FONT_FILES = (
    "PlusJakartaSans-Regular.ttf",
    "PlusJakartaSans-SemiBold.ttf",
    "PlusJakartaSans-ExtraBold.ttf",
)

# 24×24 stroke icons drawn with currentColor. The mock's prayer and tab icons
# stand in for the Material icons the app uses.
ICONS = {
    "clock": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    "timer": '<circle cx="12" cy="13.5" r="7.5"/><path d="M12 9.5v4M9.5 2.5h5"/>',
    "refresh": '<path d="M19.5 12a7.5 7.5 0 1 1-2.2-5.3M19.5 4v4.5H15"/>',
    "pin": '<path d="M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>',
    "globe": '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
    "book": '<path d="M12 6.5C10 5 7 4.5 4 5v13c3-.5 6 0 8 1.5 2-1.5 5-2 8-1.5V5c-3-.5-6 0-8 1.5z"/><path d="M12 6.5v13"/>',
    "mosque": '<path d="M4 21V11h16v10M2 21h20M12 3c-3 2-5 4-5 6.5V11h10V9.5C17 7 15 5 12 3zM10 21v-4a2 2 0 0 1 4 0v4"/>',
    "gear": '<circle cx="12" cy="12" r="3"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/>',
    "sun": '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    "cloud": '<path d="M7 18.5a4.5 4.5 0 0 1-.4-9A6 6 0 0 1 18 10a4.3 4.3 0 0 1-.5 8.5z"/>',
    "sunset": '<path d="M5 18a7 7 0 0 1 14 0M2 18h20M12 3v5M9 6l3 3 3-3"/>',
    "moon": '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>',
    "bed": '<path d="M3 18V7M3 14h18v4M21 14v-2a3 3 0 0 0-3-3h-7v5"/><circle cx="7" cy="11" r="1.8"/>',
    "heart": '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>',
    "check": '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    "github": '<path d="M9 19c-4 1.3-4-2-6-2.5M15 21v-3.5c0-1 .1-1.4-.5-2 2.8-.3 5.5-1.4 5.5-6a4.6 4.6 0 0 0-1.3-3.2 4.2 4.2 0 0 0-.1-3.2s-1-.3-3.4 1.3a11.6 11.6 0 0 0-6.2 0C6.6 2.8 5.6 3.1 5.6 3.1a4.2 4.2 0 0 0-.1 3.2A4.6 4.6 0 0 0 4.2 9.5c0 4.6 2.7 5.7 5.5 6-.6.6-.6 1.2-.5 2V21"/>',
}

PRAYERS = ("fajr", "dhuhr", "asr", "maghrib", "isha")

# The icon beside each prayer in the app's list.
PRAYER_ICONS = {
    "fajr": "bed",
    "dhuhr": "sun",
    "asr": "cloud",
    "maghrib": "sunset",
    "isha": "moon",
}

# The iPhone renders (1206 × 2622) scaled to 600 px wide by site/screens.sh.
SHOT_SIZE = (600, 1305)

PAGES = ("home", "privacy", "changelog")


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
        self.releases = json.loads(CHANGELOG.read_text())["releases"]
        self.css_name = None

    # Paths --------------------------------------------------------------

    def prefix(self, loc):
        """URL path of a locale's home, e.g. "/" or "/en/"."""
        return "/" if loc == self.default else f"/{loc}/"

    def url(self, loc, page):
        return self.prefix(loc) + ("" if page == "home" else f"{page}/")

    def fill(self, text):
        """Replaces {link} placeholders in content with configured URLs."""
        for key, value in self.config["links"].items():
            text = text.replace("{" + key + "}", value)
        return text

    # Shared chrome ------------------------------------------------------

    def head(self, loc, page, title, description, scripts=""):
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
{scripts}</head>
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
        # On other pages the section links point back to the home page.
        anchor = "" if page == "home" else home
        nav = "".join(
            f'<a href="{anchor}#{key}">{s["nav"][key]}</a>'
            for key in ("features", "infaq", "download", "roadmap")
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
<a href="{self.url(loc, 'changelog')}">{s['nav']['changelog']}</a>
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
        # The static mock is the store screenshot's day: Jakarta on Thursday
        # 5 November 2026 (25 Jumada al-Ula 1448), with Asr next at 14:54.
        # live.js turns it into today for the visitor's place.
        day, weekday, month = 5, 4, 10
        next_index = PRAYERS.index("asr")
        strip = "".join(
            ('<li class="today">' if d == day else "<li>")
            + f"<span>{m['weekdays_short'][(weekday + d - day) % 7]}</span><b>{d}</b>"
            + (f"<small>{m['months_short'][month]}</small>" if d == day else "")
            + "</li>"
            for d in range(day - 2, day + 3)
        )
        date = m["date_format"].format(
            weekday=m["weekdays"][weekday], month=m["months"][month], day=day
        )
        hijri = m["hijri_format"].format(
            day=25, month=s["hijri_months"][4], year=1448
        )
        rows = "".join(
            ('<li class="next">' if i == next_index else "<li>")
            + f'<span class="app-ico">{icon(PRAYER_ICONS[key])}</span>'
            + f'<span class="app-text"><small class="app-upnext">{m["up_next"]}</small>'
            + f'<small class="app-cat">{m["obligatory"]}</small>'
            + f'<span class="app-pname">{s["prayers"][key]}</span></span>'
            + f'<time dir="ltr">{m["times"][i]}</time></li>'
            for i, key in enumerate(PRAYERS)
        )
        tabs = "".join(
            ('<li class="on">' if i == 0 else "<li>")
            + f"{icon(name)}<span>{label}</span></li>"
            for i, (name, label) in enumerate(
                zip(("clock", "mosque", "book", "gear"), m["tabs"])
            )
        )
        label = m["label"]
        static_label = label.replace("{place}", m["place"]).replace(
            "{next}", s["prayers"]["asr"]
        )
        strings = json.dumps(
            {
                key: m[key]
                for key in (
                    "weekdays_short",
                    "weekdays",
                    "months",
                    "months_short",
                    "date_format",
                    "hijri_format",
                )
            }
            | {"hijri_months": s["hijri_months"]},
            ensure_ascii=False,
        )
        return f"""<div class="phone" role="img" aria-label="{attr(static_label)}" data-label="{attr(label)}" data-strings="{attr(strings)}">
<div class="screen" aria-hidden="true">
<div class="app-hero">
<img class="app-drum" src="/assets/drum.svg" alt="" width="1024" height="1024">
<div class="app-top"><p class="app-place">{icon('pin')}<span>{m['place']}</span></p><span class="app-refresh">{icon('refresh')}</span></div>
<p class="app-next">{s['next_prayer']} · <time dir="ltr">{m['times'][next_index]}</time></p>
<p class="app-name">{s['prayers']['asr']}</p>
<p class="app-count">{icon('timer')}<span dir="ltr">00:14:00</span></p>
</div>
<div class="app-days">
<ol class="app-strip">{strip}</ol>
<p class="app-date"><strong>{date}</strong><span>{hijri}</span></p>
</div>
<ul class="app-list">{rows}</ul>
<ul class="app-tabs">{tabs}</ul>
</div>
</div>"""

    def store_row(self, loc, store):
        s = self.strings[loc]
        label = s["stores"][store["id"]]
        url = store.get("url")
        status = (
            f'<a href="{url}">{s["download"]["get"]}</a>'
            if url
            else s["download"]["coming_soon"]
        )
        return (
            f'<li><strong>{label["name"]}</strong><span>{label["devices"]}</span>'
            f'<span class="store-status">{status}</span></li>'
        )

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

    def showcase(self, loc):
        s = self.strings[loc]
        # Screens exist in Indonesian and English (site/screens.sh).
        suffix = "-id" if loc == "id" else ""
        return "".join(
            f'<article class="feature">'
            f'<img class="shot" src="/assets/screens/{f["screen"]}{suffix}.webp" '
            f'alt="{attr(f["alt"])}" width="{SHOT_SIZE[0]}" height="{SHOT_SIZE[1]}" loading="lazy">'
            f'<div class="feature-text"><h2>{f["title"]}</h2><p>{f["body"]}</p></div>'
            f"</article>"
            for f in s["features"]["showcase"]
        )

    def home(self, loc):
        s = self.strings[loc]
        more = "".join(
            f'<div><dt>{f["title"]}</dt><dd>{f["body"]}</dd></div>'
            for f in s["features"]["more"]
        )
        stores = "".join(self.store_row(loc, st) for st in self.config["stores"])
        r = s["roadmap"]
        plan = "".join(
            f'<div><h3>{r[phase]}</h3><ul>'
            + "".join(
                f'<li><strong>{i["title"]}</strong> {i["body"]}</li>'
                for i in r[f"items_{phase}"]
            )
            + "</ul></div>"
            for phase in ("next", "later")
        )
        return (
            self.head(
                loc,
                "home",
                s["meta"]["title"],
                s["meta"]["description"],
                '<script type="module" src="/assets/live.js"></script>\n',
            )
            + self.header(loc, "home")
            + f"""
<main id="main">
<section class="hero">
<div class="wrap hero-inner">
<div class="hero-copy">
<h1>{s['hero']['title']}</h1>
<p class="lead">{s['hero']['lead']}</p>
<div class="btn-row">
<a class="btn btn-primary" href="#download">{s['hero']['cta_download']}</a>
<a class="btn btn-ghost" href="#infaq">{icon('heart')}{s['hero']['cta_infaq']}</a>
</div>
<p class="hero-note">{s['hero']['note']}</p>
</div>
{self.mock(s)}
</div>
</section>

<section id="features" class="features">
<div class="wrap">{self.showcase(loc)}</div>
</section>

<section class="section more">
<div class="wrap">
<h2>{s['features']['more_title']}</h2>
<dl class="facts">{more}</dl>
</div>
</section>

<section id="infaq" class="pledge">
<div class="wrap pledge-inner">
<img class="pledge-drum" src="/assets/drum.svg" alt="" width="1024" height="1024">
<h2>{s['infaq']['title']}</h2>
<p class="pledge-body">{s['infaq']['body']}</p>
<p><a href="{self.url(loc, 'privacy')}">{s['infaq']['privacy_link']}</a></p>
<p class="note">{s['infaq']['in_app']}</p>
{self.infaq_links(loc)}
</div>
</section>

<section id="download" class="section">
<div class="wrap">
<h2>{s['download']['title']}</h2>
<ul class="stores">{stores}</ul>
<p class="note">{s['download']['note']}</p>
</div>
</section>

<section id="roadmap" class="section section-alt">
<div class="wrap">
<h2>{r['title']}</h2>
<div class="plan">{plan}</div>
<p class="note">{self.fill(r['follow'])}</p>
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

    # Changelog ----------------------------------------------------------

    def release_date(self, loc, iso):
        c = self.strings[loc]["changelog"]
        if iso is None:
            return f'<p class="release-date">{c["unreleased"]}</p>'
        year, month, day = (int(part) for part in iso.split("-"))
        text = c["date_format"].format(
            day=day, month=c["months"][month - 1], year=year
        )
        return f'<p class="release-date"><time datetime="{iso}">{text}</time></p>'

    def changelog(self, loc):
        s = self.strings[loc]
        c = s["changelog"]
        releases = "".join(
            f'<li class="release" id="v{attr(r["version"])}">'
            f'<div class="release-head"><h2>{c["version"].format(version=r["version"])}</h2>'
            + self.release_date(loc, r["date"])
            + "</div><ul class=\"changes\">"
            + "".join(
                f'<li><span class="change-type change-{ch["type"]}">{c["types"][ch["type"]]}</span>'
                # Changelog text is plain, unlike the i18n files.
                f'<p>{html.escape(ch["text"].get(loc, ch["text"]["en"]), quote=False)}</p></li>'
                for ch in r["changes"]
            )
            + "</ul></li>"
            for r in self.releases
        )
        return (
            self.head(loc, "changelog", c["meta_title"], c["meta_description"])
            + self.header(loc, "changelog")
            + f"""
<main id="main" class="section">
<article class="wrap prose">
<h1>{c['title']}</h1>
<p class="lead">{c['lead']}</p>
<ol class="releases">{releases}</ol>
</article>
</main>
"""
            + self.footer(loc, "changelog")
        )

    # 404 ----------------------------------------------------------------

    def not_found(self):
        # One page for every locale: Cloudflare serves /404.html for any
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
        for page in PAGES:
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
        # The faint drum behind the mock's hero, as in the app.
        shutil.copy(BRANDING / "icon_monochrome.svg", assets / "drum.svg")
        shutil.copytree(SITE / "static" / "screens", assets / "screens")
        shutil.copy(SITE / "static" / "icon-512.png", assets / "icon.png")
        shutil.copy(SITE / "static" / "live.js", assets / "live.js")
        shutil.copytree(SITE / "static" / "vendor", assets / "vendor")
        for name in ("_headers", "robots.txt"):
            shutil.copy(SITE / "static" / name, DIST / name)

        for loc in self.locales:
            base = "" if loc == self.default else f"{loc}/"
            self.write(f"{base}index.html", self.home(loc))
            self.write(f"{base}privacy/index.html", self.privacy(loc))
            self.write(f"{base}changelog/index.html", self.changelog(loc))
        self.write("404.html", self.not_found())
        self.write("sitemap.xml", self.sitemap())
        print(f"Built {len(self.locales)} locales into {DIST.relative_to(ROOT)}")


if __name__ == "__main__":
    Site().build()
