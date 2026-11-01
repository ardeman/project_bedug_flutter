#!/usr/bin/env bash
# Copies the app screens the landing page shows from the iPhone renders in
# tool/screenshots/out/devices/ (run flutter test tool/screenshots
# --update-goldens first) into site/static/screens/ as WebP, in Indonesian
# and English; the Arabic and Malay pages use the English ones. Needs cwebp
# (brew install webp). The output is committed, since the Cloudflare build
# runs only Python.
set -euo pipefail

cd "$(dirname "$0")/.."
src=tool/screenshots/out/devices/iphone
out=site/static/screens
mkdir -p "$out"

for screen in quran dzikir qibla fasting; do
  for suffix in "" -id; do
    # 600 px wide shows sharp at the page's 300 px on 2x screens.
    cwebp -quiet -q 78 -resize 600 0 "$src/$screen$suffix.png" -o "$out/$screen$suffix.webp"
  done
done
du -ch "$out"/*.webp | tail -1
