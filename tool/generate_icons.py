#!/usr/bin/env python3
"""Rasterize the rectangle-based SVG master with Pillow; generate native vectors.
Install Pillow==12.3.0 in a local virtual environment. No font dependency.
"""
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent.parent
source = ET.parse(root / 'assets/brand/app-icon-source.svg').getroot()
rects = list(source)

def render(size):
    # Supersampling retains crisp edges at launcher sizes; output is opaque RGB.
    factor = 3
    image = Image.new('RGB', (size * factor, size * factor))
    draw = ImageDraw.Draw(image)
    scale = size * factor / 1024
    for rect in rects:
        a = rect.attrib
        x, y, w, h = (float(a.get(k, 0)) * scale for k in ['x', 'y', 'width', 'height'])
        draw.rounded_rectangle((x, y, x+w, y+h), radius=float(a.get('rx', 0))*scale, fill=a['fill'])
    return image.resize((size, size), Image.Resampling.LANCZOS)

icons = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((icons / 'Contents.json').read_text())['images']:
    size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].removesuffix('x')))
    render(size).save(icons / entry['filename'])
res = root / 'android/app/src/main/res'
for density, size in [('mdpi',48), ('hdpi',72), ('xhdpi',96), ('xxhdpi',144), ('xxxhdpi',192)]:
    target = res / f'mipmap-{density}'
    target.mkdir(parents=True, exist_ok=True)
    render(size).save(target / 'ic_launcher.png')
# Safe zone: foreground geometry within the center 66/108 viewport.
paths = []
for rect in rects[1:]:
    a = rect.attrib
    x, y, w, h, radius = (float(a.get(k, 0)) * 0.08 for k in ['x', 'y', 'width', 'height', 'rx'])
    x += 13.04
    y += 13.04
    # Same SVG geometry, mapped into Android's adaptive safe zone.
    paths.append(f'M{x+radius},{y} h{w-2*radius} q{radius},0 {radius},{radius} v{h-2*radius} q0,{radius} {-radius},{radius} h{-w+2*radius} q{-radius},0 {-radius},{-radius} v{-h+2*radius} q0,{-radius} {radius},{-radius} Z')
vector = '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="'+rects[1].attrib['fill']+'" android:pathData="'+' '.join(paths)+'"/></vector>\n'
(res / 'drawable').mkdir(exist_ok=True)
(res / 'drawable/ic_launcher_foreground.xml').write_text(vector)
(res / 'values/icon_background.xml').write_text('<resources><color name="icon_background">#006A60</color></resources>\n')
for version in ['v26','v33']:
    target = res / f'mipmap-anydpi-{version}'
    target.mkdir(exist_ok=True)
    mono = '<monochrome android:drawable="@drawable/ic_launcher_foreground"/>' if version == 'v33' else ''
    (target / 'ic_launcher.xml').write_text('<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/icon_background"/><foreground android:drawable="@drawable/ic_launcher_foreground"/>'+mono+'</adaptive-icon>\n')
render(512).save(root / 'assets/brand/play-store-icon.png')
print('Generated opaque iOS/legacy Android icons and adaptive/themed vectors.')
