#!/usr/bin/env bash
# Renders the store graphics for each listing language with headless Chrome,
# from the device renders in tool/screenshots/out/devices/ (run
# flutter test tool/screenshots --update-goldens first), the device frames in
# store/bezels/ (tool/fetch_bezels.sh) and assets/branding/icon.svg. Every
# screenshot shows its real device around it, with its status bar
# (store/device.mjs), in each way it is held:
#   store/google_play/<locale>/feature_graphic.png     1024 x 500
#   store/google_play/<locale>/screenshots/*.png       1920 x 1080 (16:9, tablets):
#     Pixel Tablet, sideways and upright
#   store/google_play/<locale>/phone_screenshots/*.png 1080 x 1920 (9:16, phones):
#     Pixel 9, upright and sideways
#   store/app_store/<locale>/screenshots/iphone/*.jpg  1206 x 2622 (iPhone 6.3",
#     the size App Store Connect requires): iPhone 17, upright and sideways
#   store/app_store/<locale>/screenshots/ipad/*.jpg    2752 x 2064 (iPad 13"):
#     iPad Pro, sideways and upright
#   store/app_store/<locale>/screenshots/mac/*.jpg     2880 x 1800: MacBook Air
#   store/app_store/<locale>/screenshots/duo/*.jpg     2007 x 2853 (iPhone Duo):
#     open upright and sideways, closed both ways, half folded on a table and
#     like a book
#   store/app_store/<locale>/header.png, search_result.png (creative assets)
# Run from the project root: store/render.sh
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
OUT="$ROOT/tool/screenshots/out/devices"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP:?}"' EXIT

if [ ! -f "$OUT/pixel/prayer.png" ]; then
  echo "Missing $OUT: run flutter test tool/screenshots --update-goldens first." >&2
  exit 1
fi
if [ ! -f store/bezels/screens.txt ]; then
  echo "Missing store/bezels: run tool/fetch_bezels.sh first." >&2
  exit 1
fi
# Android's status bar clock is Roboto, which ships with Flutter; the
# slides' own type is Plus Jakarta Sans, bundled with the app.
FONTS="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")/bin/cache/artifacts/material_fonts"

# The bedug from the app icon, without its background.
CHARACTER="$(sed -n '/<g transform="translate(512 520)/,/^  <\/g>$/p' assets/branding/icon.svg)"

JAKARTA="$ROOT/assets/fonts/plus_jakarta_sans"
STYLE="
  @font-face{font-family:Roboto;src:url('file://$FONTS/Roboto-Regular.ttf')}
  @font-face{font-family:'Plus Jakarta Sans';font-weight:700;src:url('file://$JAKARTA/PlusJakartaSans-Bold.ttf')}
  @font-face{font-family:'Plus Jakarta Sans';font-weight:800;src:url('file://$JAKARTA/PlusJakartaSans-ExtraBold.ttf')}
"'
  html,body{margin:0}
  body{font-family:"Plus Jakarta Sans",system-ui,sans-serif;color:#fff;
       background:radial-gradient(circle at 85% 15%,#5cc7ba 0,transparent 45%),
                  radial-gradient(circle at 10% 95%,#c99a3b40 0,transparent 40%),
                  linear-gradient(180deg,#2a8c82,#1f7a5a);overflow:hidden}
  h1{margin:0;font-weight:800;letter-spacing:0}
'

# shot <width> <height> <html body> <out.png>
shot() {
  printf '<!doctype html><html><head><meta charset="utf-8"><style>%s</style></head><body style="width:%spx;height:%spx">%s</body></html>' \
    "$STYLE" "$1" "$2" "$3" > "$TMP/page.html"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --window-size="$1,$2" --screenshot="$4" "file://$TMP/page.html" 2>/dev/null
}

# device <kind> <image> <box width> <box height> [style]: the screenshot
# $OUT/<image> in its device (store/device.mjs), as big as fits the box. The
# kind is the device's folder in $OUT; the prayer times' dark green header
# gets a light status bar.
device() {
  local tone=dark lang=en
  case "$2" in *prayer*) tone=light ;; esac
  case "$2" in *-id.png) lang=id ;; esac
  node store/device.mjs "$1" "$OUT/$2" "$3" "$4" "$tone" "$lang" "${5:-}"
}

# slide <width> <height> <font size> <caption> <devices html> <out>: the
# caption above the devices.
slide() {
  shot "$1" "$2" "<div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;gap:$(($3 * 2 / 3))px;height:$2px\">
      <h1 style=\"font-size:$3px;max-width:$(($1 * 9 / 10))px;text-align:center;line-height:1.1\">$4</h1>
      <div style=\"display:flex;align-items:center;justify-content:center\">$5</div>
    </div>" "$6"
}

# box_w <w>, box_h <h> <font>: room for the devices below the caption.
box_w() { echo $(($1 * 90 / 100)); }
box_h() { echo $(($1 - $2 * 4)); }

# one <w> <h> <font> <device> <screen> <suffix> <caption> <out>
one() {
  slide "$1" "$2" "$3" "$7" "$(device "$4" "$4/$5$6.png" "$(box_w "$1")" "$(box_h "$2" "$3")")" "$8"
}

# pair <w> <h> <font> <device> <screen> <screen> <suffix> <caption> <out>:
# two screens of one device, overlapping, for related screens.
pair() {
  local bw bh
  if [ "$1" -gt "$2" ]; then bw=$(($1 * 55 / 100)); bh=$(($2 * 62 / 100))
  else bw=$(($1 * 62 / 100)); bh=$(($2 * 55 / 100)); fi
  slide "$1" "$2" "$3" "$8" "<div style=\"display:flex;align-items:flex-start\">
      $(device "$4" "$4/$5$7.png" "$bw" "$bh" "transform:rotate(-2deg)")
      $(device "$4" "$4/$6$7.png" "$bw" "$bh" "transform:rotate(2deg);margin-left:-$((bw * 22 / 100))px;margin-top:$((bh * 22 / 100))px")
    </div>" "$9"
}

# turned <w> <h> <font> <device> <turned device> <screen> <suffix> <caption>
# <out>: one screen on a device held both ways, upright and sideways; the
# slide's own way gets the most room.
turned() {
  local up side
  if [ "$1" -gt "$2" ]; then
    side="$(device "$4" "$4/$6$7.png" $(($1 * 54 / 100)) $(($(box_h "$2" "$3") * 85 / 100)))"
    up="$(device "$5" "$5/$6$7.png" $(($1 * 34 / 100)) "$(box_h "$2" "$3")" "margin-left:$(($1 * 4 / 100))px")"
    slide "$1" "$2" "$3" "$8" "$side$up" "$9"
  else
    up="$(device "$4" "$4/$6$7.png" $(($1 * 80 / 100)) $(($(box_h "$2" "$3") * 56 / 100)))"
    side="$(device "$5" "$5/$6$7.png" "$(box_w "$1")" $(($(box_h "$2" "$3") * 36 / 100)) "margin-top:$(($2 * 3 / 100))px")"
    slide "$1" "$2" "$3" "$8" "<div style=\"display:flex;flex-direction:column;align-items:center\">$up$side</div>" "$9"
  fi
}

# set_of <w> <h> <font> <device> <slide 3: the device turned, or "" for
# none> <suffix> <out dir> captions...: the eight slides of one device.
set_of() {
  local w="$1" h="$2" f="$3" d="$4" t="$5" s="$6" dir="$7"
  shift 7
  mkdir -p "$dir"
  rm -f "${dir:?}/"*.png "${dir:?}/"*.jpg
  one "$w" "$h" "$f" "$d" prayer         "$s" "$1" "$dir/1-prayer.png"
  one "$w" "$h" "$f" "$d" quran          "$s" "$2" "$dir/2-quran.png"
  if [ -n "$t" ]; then
    turned "$w" "$h" "$f" "$d" "$t" qibla "$s" "$3" "$dir/3-qibla.png"
  else
    one "$w" "$h" "$f" "$d" qibla        "$s" "$3" "$dir/3-qibla.png"
  fi
  one "$w" "$h" "$f" "$d" dzikir         "$s" "$4" "$dir/4-dzikir.png"
  one "$w" "$h" "$f" "$d" events         "$s" "$5" "$dir/5-events.png"
  one "$w" "$h" "$f" "$d" fasting        "$s" "$6" "$dir/6-fasting.png"
  one "$w" "$h" "$f" "$d" zakat          "$s" "$7" "$dir/7-zakat.png"
  pair "$w" "$h" "$f" "$d" duas asmaul "$s" "$8" "$dir/8-duas.png"
}

# duo_set <suffix> <out dir> captions...: the iPhone Duo in every way it is
# held: open upright, half folded like a book, closed upright, open sideways,
# half folded on a table, open again, closed sideways, and open for the pair.
duo_set() {
  local s="$1" dir="$2" w=2007 h=2853 f=120
  shift 2
  mkdir -p "$dir"
  rm -f "${dir:?}/"*.png "${dir:?}/"*.jpg
  one "$w" "$h" "$f" duo                 prayer         "$s" "$1" "$dir/1-prayer.png"
  one "$w" "$h" "$f" duo-book            quran          "$s" "$2" "$dir/2-quran.png"
  one "$w" "$h" "$f" duo-outer           qibla          "$s" "$3" "$dir/3-qibla.png"
  one "$w" "$h" "$f" duo-landscape       dzikir         "$s" "$4" "$dir/4-dzikir.png"
  one "$w" "$h" "$f" duo-table           events         "$s" "$5" "$dir/5-events.png"
  one "$w" "$h" "$f" duo                 fasting        "$s" "$6" "$dir/6-fasting.png"
  one "$w" "$h" "$f" duo-outer-landscape zakat          "$s" "$7" "$dir/7-zakat.png"
  pair "$w" "$h" "$f" duo duas asmaul "$s" "$8" "$dir/8-duas.png"
}

# JPEG halves the size, and the App Store takes it.
to_jpeg() {
  local png
  for png in "$1/"*.png; do
    sips -s format jpeg -s formatOptions 90 "$png" --out "${png%.png}.jpg" >/dev/null
    rm "$png"
  done
}

# feature <tagline> <suffix> <out>: the bedug and the tagline beside a Pixel
# Tablet with a Pixel 9 in front of its corner.
feature() {
  shot 1024 500 "<div style=\"display:flex;align-items:center;height:500px;padding-left:56px;gap:8px\">
      <div style=\"width:380px;flex:none\">
        <svg viewBox=\"140 210 740 670\" width=\"138\" height=\"125\">$CHARACTER</svg>
        <h1 style=\"font-size:68px;margin-top:6px\">Bedug</h1>
        <p style=\"font-size:30px;font-weight:700;margin:6px 0 0;opacity:.95\">$1</p>
      </div>
      <div style=\"position:relative;flex:none\">
        $(device pixel-tablet "pixel-tablet/prayer$2.png" 500 340 "transform:rotate(-4deg);margin-top:-30px")
        <div style=\"position:absolute;left:410px;top:10px\">$(device pixel "pixel/qibla$2.png" 200 320 "transform:rotate(5deg)")</div>
      </div>
    </div>" "$3"
}

# "Al-Qur'an" never breaks at its hyphen.
QURAN="<span style=\"white-space:nowrap\">Al-Qur'an</span>"

CAPTIONS_ID=(
  "Waktu salat tepat, hitung mundur ke azan"
  "Baca $QURAN per halaman, seperti mushaf"
  "Arah kiblat di mana pun kamu berada"
  "Zikir pagi dan petang, dengan penghitung"
  "Hari besar Islam dan kalender Hijriah"
  "Catatan puasa Ramadan dan utang qada"
  "Hitung zakat maal dan zakat fitrah"
  "Doa harian dan Asmaul Husna, tanpa iklan"
)
CAPTIONS_EN=(
  "Prayer times, counting down to the adhan"
  "Read the Quran page by page, like a mushaf"
  "The qibla wherever you are"
  "Morning and evening dzikir, with a counter"
  "Islamic events and the Hijri calendar"
  "Your Ramadan fasting log and make-up fasts"
  "Work out your zakat maal and fitrah"
  "Daily duas and Asmaul Husna, no ads"
)

render_locale() { # locale suffix tagline captions...
  local locale="$1" s="$2" tagline="$3"; shift 3
  local play="store/google_play/$locale" apple="store/app_store/$locale/screenshots"
  feature "$tagline" "$s" "$play/feature_graphic.png"
  set_of 1920 1080 64 pixel-tablet pixel-tablet-portrait "$s" "$play/screenshots" "$@"
  set_of 1080 1920 68 pixel pixel-landscape "$s" "$play/phone_screenshots" "$@"
  set_of 1206 2622 84 iphone iphone-landscape "$s" "$apple/iphone" "$@"
  set_of 2752 2064 104 ipad ipad-portrait "$s" "$apple/ipad" "$@"
  set_of 2880 1800 100 mac "" "$s" "$apple/mac" "$@"
  duo_set "$s" "$apple/duo" "$@"
  local set
  for set in iphone ipad mac duo; do to_jpeg "$apple/$set"; done
}

render_locale id "-id" "Waktu salat, kiblat, dan $QURAN" "${CAPTIONS_ID[@]}"
render_locale en-US "" "Prayer times, qibla and the Quran" "${CAPTIONS_EN[@]}"

# App Store creative assets (Header and Search Results), PNG without alpha:
#   store/app_store/<locale>/header.png          3840 x 1646 (21:9, product page)
#   store/app_store/<locale>/search_result.png   3840 x 2560 (3:2, search results)
# An iPhone shows only the middle 2540 px or so of the header, with the
# Dynamic Island over the top 320 px and round buttons at the sides.
creative() { # locale suffix tagline
  local dir="store/app_store/$1" s="$2" tagline="$3"
  # The page shows the icon and the name right below, so the header shows
  # only the app: today's prayer times on a big iPhone in the middle, the
  # Quran and the qibla on iPhones either side, set lower to pass under the
  # round buttons, and iPads at the far edges for the wider iPad header.
  shot 3840 1646 "<div style=\"position:relative;height:1646px;overflow:hidden\">
      <div style=\"position:absolute;left:-380px;top:520px\">$(device ipad "ipad/dzikir$s.png" 1300 1000 "transform:rotate(-7deg)")</div>
      <div style=\"position:absolute;left:2920px;top:520px\">$(device ipad "ipad/events$s.png" 1300 1000 "transform:rotate(7deg)")</div>
      <div style=\"position:absolute;left:800px;top:720px\">$(device iphone "iphone/quran$s.png" 760 1600 "transform:rotate(-8deg)")</div>
      <div style=\"position:absolute;left:2280px;top:720px\">$(device iphone "iphone/qibla$s.png" 760 1600 "transform:rotate(8deg)")</div>
      <div style=\"position:absolute;left:1470px;top:380px\">$(device iphone "iphone/prayer$s.png" 900 1900)</div>
    </div>" "$TMP/header.png"
  shot 3840 2560 "<div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;height:2560px;gap:110px\">
      <div style=\"display:flex;align-items:center;gap:60px\">
        <svg viewBox=\"140 210 740 670\" width=\"420\" height=\"380\">$CHARACTER</svg>
        <h1 style=\"font-size:170px\">$tagline</h1>
      </div>
      <div style=\"display:flex;align-items:flex-end\">
        $(device ipad "ipad/quran$s.png" 2500 1800)
        $(device iphone "iphone/qibla$s.png" 800 1600 "margin-left:-260px;margin-bottom:-60px;transform:rotate(4deg)")
      </div>
    </div>" "$TMP/search.png"
  # PNG: App Store Connect turns down .jpg here ("invalid extension"). Chrome's
  # screenshots have an alpha channel, which Apple refuses; a pass through JPEG
  # at full quality drops it.
  rm -f "$dir/header.jpg" "$dir/search_result.jpg"
  local name
  for name in header search; do
    sips -s format jpeg -s formatOptions 100 "$TMP/$name.png" --out "$TMP/$name.jpg" >/dev/null
    sips -s format png "$TMP/$name.jpg" --out "$TMP/$name-opaque.png" >/dev/null
  done
  mv "$TMP/header-opaque.png" "$dir/header.png"
  mv "$TMP/search-opaque.png" "$dir/search_result.png"
}

creative id -id "Waktu salat, kiblat, dan $QURAN"
creative en-US "" "Prayer times, qibla and the Quran"

echo "Store graphics rendered."
