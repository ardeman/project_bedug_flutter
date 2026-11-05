#!/usr/bin/env python3
"""Builds the Bedug landing page into site/dist.

HTML layouts live in site/templates/, content in site/i18n/<locale>.json,
links in site/config.json, and styles, scripts and app screens in site/static/. The
fonts, the icon and the changelog come from the app's own assets so each has
one source. Standard library only, so Cloudflare
can run it as the build command: `python3 site/build.py`.
"""

import hashlib
import html
import json
import shutil
from pathlib import Path
from string import Template

SITE = Path(__file__).resolve().parent
ROOT = SITE.parent
DIST = SITE / "dist"
TEMPLATES = SITE / "templates"
FONTS = ROOT / "assets" / "fonts" / "plus_jakarta_sans"
BRANDING = ROOT / "assets" / "branding"
CHANGELOG = ROOT / "assets" / "changelog" / "changelog.json"

# Only the weights the stylesheet uses.
FONT_FILES = (
    "PlusJakartaSans-Regular.ttf",
    "PlusJakartaSans-SemiBold.ttf",
    "PlusJakartaSans-ExtraBold.ttf",
)

# Stroke icons for the website's own controls.
ICONS = {
    "globe": '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
    "heart": '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>',
    "check": '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    "github": '<path d="M9 19c-4 1.3-4-2-6-2.5M15 21v-3.5c0-1 .1-1.4-.5-2 2.8-.3 5.5-1.4 5.5-6a4.6 4.6 0 0 0-1.3-3.2 4.2 4.2 0 0 0-.1-3.2s-1-.3-3.4 1.3a11.6 11.6 0 0 0-6.2 0C6.6 2.8 5.6 3.1 5.6 3.1a4.2 4.2 0 0 0-.1 3.2A4.6 4.6 0 0 0 4.2 9.5c0 4.6 2.7 5.7 5.5 6-.6.6-.6 1.2-.5 2V21"/>',
}

# Official store badges in site/static/badges/, by store and by the
# region Apple localizes them for.
STORE_BADGES = {"appstore": "app-store"}
BADGE_REGIONS = {"id": "id-id", "en": "en-us", "ms": "ms-my"}

PRAYERS = ("fajr", "dhuhr", "asr", "maghrib", "isha")

# The icon beside each prayer in the app's list.
PRAYER_ICONS = {
    "fajr": "bedtime_outlined",
    "dhuhr": "wb_sunny_outlined",
    "asr": "wb_cloudy_outlined",
    "maghrib": "wb_twilight",
    "isha": "dark_mode_outlined",
}

# Exact glyph outlines exported by scripts/export_site_icons.swift.
MATERIAL_ICONS = json.loads(
    (SITE / "static/vendor/material-icons/paths.json").read_text(encoding="utf-8")
)


def material_icon(name):
    return (
        '<svg class="icon" viewBox="0 0 24 24" fill="currentColor" '
        f'aria-hidden="true" data-material-icon="{name}">'
        f'<path d="{MATERIAL_ICONS[name]}"/></svg>'
    )


# The iPhone renders (1206 × 2622) scaled to 600 px wide by site/screens.sh.
SHOT_SIZE = (600, 1305)

PAGES = ("home", "privacy", "terms", "changelog")


def icon(name, cls="icon"):
    return render_template("icon.html", cls=cls, paths=ICONS[name])


def attr(text):
    return html.escape(text, quote=True)


def render_template(name, **values):
    """Render trusted markup; callers escape attributes and plain-text content.

    Localized copy may contain intentional HTML. Substitution is strict and
    single-pass, so missing values fail the build and content is never evaluated.
    """
    return Template((TEMPLATES / name).read_text(encoding="utf-8")).substitute(values)


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
        return render_template(
            'head.html',
            loc=loc,
            dir=s['dir'],
            title_attr=attr(title),
            description_attr=attr(description),
            base=base,
            canonical_path=self.url(loc, page),
            alternates=alternates,
            default_path=self.url(self.default, page),
            og_locale=s['og_locale'],
            css_name=self.css_name,
            scripts=scripts,
            skip=s['skip'],
        )

    def language_menu(self, loc, page):
        s = self.strings[loc]
        items = "".join(
            f'<li><a href="{self.url(other, page)}" hreflang="{other}" lang="{other}"'
            + (' aria-current="true"' if other == loc else "")
            + f">{self.strings[other]['lang_name']}</a></li>"
            for other in self.locales
        )
        return render_template(
            "language-menu.html",
            label=attr(s["language"]),
            globe_icon=icon("globe"),
            language=s["lang_name"],
            items=items,
        )

    def header(self, loc, page):
        s = self.strings[loc]
        home = self.prefix(loc)
        # On other pages the section links point back to the home page.
        anchor = "" if page == "home" else home
        nav = "".join(
            f'<a href="{anchor}#{key}">{s["nav"][key]}</a>'
            for key in ("features", "infaq", "download", "roadmap")
        )
        return render_template(
            'header.html',
            home_class=' top-home' if page == 'home' else '',
            home=home,
            nav_label_attr=attr(s['nav_label']),
            nav=nav,
        )

    def footer(self, loc, page):
        s = self.strings[loc]
        links = self.config["links"]
        return render_template(
            'footer.html',
            home_url=self.prefix(loc),
            footer_tagline=s['footer_tagline'],
            footer_label_attr=attr(s['footer_label']),
            changelog_url=self.url(loc, 'changelog'),
            nav_changelog=s['nav']['changelog'],
            privacy_url=self.url(loc, 'privacy'),
            nav_privacy=s['nav']['privacy'],
            terms_url=self.url(loc, 'terms'),
            nav_terms=s['nav']['terms'],
            links_repo=links['repo'],
            links_publisher=links['publisher'],
            github_icon=icon('github'),
            language_menu=self.language_menu(loc, page),
        )

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
            + f'<span class="app-ico">{material_icon(PRAYER_ICONS[key])}</span>'
            + f'<span class="app-text"><small class="app-upnext">{m["up_next"]}</small>'
            + f'<small class="app-cat">{m["obligatory"]}</small>'
            + f'<span class="app-pname">{s["prayers"][key]}</span></span>'
            + f'<time dir="ltr">{m["times"][i]}</time></li>'
            for i, key in enumerate(PRAYERS)
        )
        tabs = "".join(
            ('<li class="on">' if i == 0 else "<li>")
            + f"{material_icon(name)}<span>{label}</span></li>"
            for i, (name, label) in enumerate(
                zip(("access_time_filled", "mosque_outlined", "menu_book_outlined",
                     "settings_outlined"), m["tabs"])
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
        return render_template(
            'mock.html',
            static_label_attr=attr(static_label),
            label_attr=attr(label),
            strings_attr=attr(strings),
            pin_icon=material_icon('location_on_outlined'),
            place=m['place'],
            refresh_icon=material_icon('refresh'),
            next_prayer=s['next_prayer'],
            next_time=m['times'][next_index],
            next_name=s['prayers']['asr'],
            timer_icon=material_icon('timer_outlined'),
            strip=strip,
            date=date,
            hijri=hijri,
            rows=rows,
            tabs=tabs,
        )

    def store_row(self, loc, store):
        s = self.strings[loc]
        label = s["stores"][store["id"]]
        url = store.get("url")
        badge = STORE_BADGES.get(store["id"])
        if url and badge:
            # Apple's official badge, black on light pages and white on dark.
            # Apple publishes no Arabic badge, so Arabic uses the English one.
            region = BADGE_REGIONS.get(loc, "en-us")
            src = f"/assets/badges/{badge}-{{}}-{region}.svg"
            status = (
                f'<a class="store-badge" href="{url}"><picture>'
                f'<source srcset="{src.format("white")}" media="(prefers-color-scheme: dark)">'
                f'<img src="{src.format("black")}" alt="{attr(label["badge"])}" height="44">'
                f"</picture></a>"
            )
        elif url:
            status = f'<a href="{url}">{s["download"]["get"]}</a>'
        else:
            status = s["download"]["coming_soon"]
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
            render_template(
                'showcase.html',
                screen=f['screen'],
                suffix=suffix,
                alt_attr=attr(f['alt']),
                width=SHOT_SIZE[0],
                height=SHOT_SIZE[1],
                number=i + 1,
                title=f['title'],
                body=f['body'],
            )
            for i, f in enumerate(s["features"]["showcase"])
        )

    def home(self, loc):
        s = self.strings[loc]
        more = "".join(
            f'<div><dt>{f["title"]}</dt><dd>{f["body"]}</dd></div>'
            for f in s["features"]["more"]
        )
        feature_links = "".join(
            f'<a href="#feature-{f["screen"]}">{f["title"]}</a>'
            for f in s["features"]["showcase"]
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
            + render_template(
                'home.html',
                hero_eyebrow=s['hero']['eyebrow'],
                hero_title=s['hero']['title'],
                hero_lead=s['hero']['lead'],
                hero_cta_download=s['hero']['cta_download'],
                heart_icon=icon('heart'),
                hero_cta_infaq=s['hero']['cta_infaq'],
                hero_note=s['hero']['note'],
                mock=self.mock(s),
                nav_features=s['nav']['features'],
                features_title=s['features']['title'],
                nav_features_attr=attr(s['nav']['features']),
                feature_links=feature_links,
                showcase=self.showcase(loc),
                features_more_title=s['features']['more_title'],
                more=more,
                infaq_title=s['infaq']['title'],
                infaq_body=s['infaq']['body'],
                privacy_url=self.url(loc, 'privacy'),
                infaq_privacy_link=s['infaq']['privacy_link'],
                infaq_in_app=s['infaq']['in_app'],
                infaq_links=self.infaq_links(loc),
                download_title=s['download']['title'],
                stores=stores,
                download_note=s['download']['note'],
                roadmap_title=r['title'],
                plan=plan,
                roadmap_follow=self.fill(r['follow']),
            )
            + self.footer(loc, "home")
        )

    # Privacy policy and terms of use ------------------------------------

    def legal(self, loc, page):
        """A policy page: title, summary list and sections from strings[page]."""
        p = self.strings[loc][page]
        sections = "".join(
            f'<section><h2>{sec["heading"]}</h2>'
            + "".join(f"<p>{self.fill(par)}</p>" for par in sec["body"])
            + "</section>"
            for sec in p["sections"]
        )
        summary_items = "".join(
            f"<li>{icon('check')}<span>{item}</span></li>"
            for item in p["summary"]
        )
        return (
            self.head(loc, page, p["meta_title"], p["meta_description"])
            + self.header(loc, page)
            + render_template(
                'legal.html',
                title=p['title'],
                updated=p['updated'],
                intro=p['intro'],
                summary_title=p['summary_title'],
                summary_items=summary_items,
                sections=sections,
            )
            + self.footer(loc, page)
        )

    def privacy(self, loc):
        return self.legal(loc, "privacy")

    def terms(self, loc):
        return self.legal(loc, "terms")

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
            + render_template(
                'changelog.html',
                title=c['title'],
                lead=c['lead'],
                releases=releases,
            )
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
            + render_template("not-found.html", messages=messages)
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
        for name in ("live.js", "experience.js"):
            shutil.copy(SITE / "static" / name, assets / name)
        shutil.copytree(SITE / "static" / "vendor", assets / "vendor")
        shutil.copytree(SITE / "static" / "badges", assets / "badges")
        for name in ("_headers", "robots.txt"):
            shutil.copy(SITE / "static" / name, DIST / name)

        for loc in self.locales:
            base = "" if loc == self.default else f"{loc}/"
            self.write(f"{base}index.html", self.home(loc))
            self.write(f"{base}privacy/index.html", self.privacy(loc))
            self.write(f"{base}terms/index.html", self.terms(loc))
            self.write(f"{base}changelog/index.html", self.changelog(loc))
        self.write("404.html", self.not_found())
        self.write("sitemap.xml", self.sitemap())
        print(f"Built {len(self.locales)} locales into {DIST.relative_to(ROOT)}")


if __name__ == "__main__":
    Site().build()
