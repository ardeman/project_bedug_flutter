#!/usr/bin/env python3
"""Generate the Android notification vector from its path-only branding SVG."""

from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/branding/icon_notification.svg"
TARGET = ROOT / "android/app/src/main/res/drawable/ic_stat_bedug.xml"
ANDROID = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", ANDROID)
svg = ET.parse(SOURCE).getroot()
_, _, width, height = svg.attrib["viewBox"].split()
vector = ET.Element("vector", {
    f"{{{ANDROID}}}width": f"{width}dp",
    f"{{{ANDROID}}}height": f"{height}dp",
    f"{{{ANDROID}}}viewportWidth": width,
    f"{{{ANDROID}}}viewportHeight": height,
})
for path in svg:
    if path.tag != "{http://www.w3.org/2000/svg}path":
        raise ValueError("Notification artwork must use paths only")
    ET.SubElement(vector, "path", {
        f"{{{ANDROID}}}fillColor": path.attrib["fill"],
        f"{{{ANDROID}}}fillType": "evenOdd" if path.get("fill-rule") == "evenodd" else "nonZero",
        f"{{{ANDROID}}}pathData": path.attrib["d"],
    })
ET.indent(vector, space="    ")
TARGET.write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<!-- Generated from assets/branding/icon_notification.svg. -->\n'
    + ET.tostring(vector, encoding="unicode") + "\n"
)
