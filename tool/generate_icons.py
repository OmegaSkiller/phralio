#!/usr/bin/env python3
"""Generate native assets from approved SVGs, without redrawing or masking.

Requires Node.js + sharp (build tooling only). Use NODE_PATH when sharp is
installed outside the repository. All generated outputs are checked in.
"""
import json
import re
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parent.parent
brand = root / 'assets/brand'
source = brand / 'app-icon-source.svg'
paths = list(ET.parse(source).getroot().iter('{http://www.w3.org/2000/svg}path'))
background, mark = paths
paper, ink = background.attrib['fill'], mark.attrib['fill']
geometry = mark.attrib['d']
tx, ty, scale = map(float, re.fullmatch(r'translate\((\d+) (\d+)\) scale\((\d+)\)', mark.attrib['transform']).groups())

def render(svg, destination, width, height=None, opaque=False):
    destination.parent.mkdir(parents=True, exist_ok=True)
    script = """const sharp = require('sharp');
let p = sharp(process.argv[1], {density: 384}).resize(+process.argv[3], +process.argv[4]);
if (process.argv[5] === 'true') p = p.flatten({background: '#F4F0E7'}).removeAlpha();
p.png().toFile(process.argv[2]).catch(e => { console.error(e); process.exit(1); });"""
    subprocess.run(['node', '-e', script, str(svg), str(destination), str(width), str(height or width), str(opaque).lower()], check=True)

icons = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for item in json.loads((icons / 'Contents.json').read_text())['images']:
    size = round(float(item['size'].split('x')[0]) * float(item['scale'].removesuffix('x')))
    render(source, icons / item['filename'], size, opaque=True)
res = root / 'android/app/src/main/res'
for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    render(source, res / f'mipmap-{density}/ic_launcher.png', size, opaque=True)
render(source, brand / 'play-store-icon.png', 512, opaque=True)
# The unchanged mark is scaled uniformly within Android's circular safe zone.
factor = .88
offset = 512 * (1-factor)
vector = f'''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="1024" android:viewportHeight="1024"><group android:translateX="{tx*factor+offset}" android:translateY="{ty*factor+offset}" android:scaleX="{scale*factor}" android:scaleY="{scale*factor}"><path android:fillColor="{ink}" android:pathData="{geometry}"/></group></vector>\n'''
(res / 'drawable/ic_launcher_foreground.xml').write_text(vector)
(res / 'values/icon_background.xml').write_text(f'<resources><color name="icon_background">{paper}</color><color name="launch_background">{paper}</color><color name="launch_mark">{ink}</color></resources>\n')
(res / 'values-night/icon_background.xml').write_text(f'<resources><color name="launch_background">{ink}</color><color name="launch_mark">{paper}</color></resources>\n')
for version in ['v26','v33']:
    mono = '<monochrome android:drawable="@drawable/ic_launcher_foreground"/>' if version == 'v33' else ''
    (res / f'mipmap-anydpi-{version}/ic_launcher.xml').write_text('<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/icon_background"/><foreground android:drawable="@drawable/ic_launcher_foreground"/>'+mono+'</adaptive-icon>\n')
launch_vector = f'<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="104dp" android:height="120dp" android:viewportWidth="104" android:viewportHeight="120"><group android:translateX="16" android:translateY="16"><path android:fillColor="@color/launch_mark" android:pathData="{geometry}"/></group></vector>\n'
(res / 'drawable/launch_mark.xml').write_text(launch_vector)
for folder in ['drawable','drawable-v21']:
    (res / folder / 'launch_background.xml').write_text('<layer-list xmlns:android="http://schemas.android.com/apk/res/android"><item android:drawable="@color/launch_background"/><item android:gravity="center" android:drawable="@drawable/launch_mark"/></layer-list>\n')
# Android 12+ splash draws the same master within the system mask.
(res / 'drawable/splash_icon.xml').write_text(vector.replace(ink, '@color/launch_mark'))
(res / 'values-v31').mkdir(exist_ok=True)
(res / 'values-v31/styles.xml').write_text('''<resources><style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar"><item name="android:windowSplashScreenBackground">@color/launch_background</item><item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_icon</item><item name="android:windowLightStatusBar">true</item></style></resources>\n''')
(res / 'values-night-v31').mkdir(exist_ok=True)
(res / 'values-night-v31/styles.xml').write_text('''<resources><style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar"><item name="android:windowSplashScreenBackground">@color/launch_background</item><item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_icon</item><item name="android:windowLightStatusBar">false</item></style></resources>\n''')
launch = root / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
images=[]
for dark in [False, True]:
    for scale in [1,2,3]:
        name = f'LaunchImage{"-dark" if dark else ""}{"@"+str(scale)+"x" if scale > 1 else ""}.png'
        render(brand / f'mark-{"paper" if dark else "ink"}.svg', launch/name, 104*scale, 120*scale)
        item={'idiom':'universal','filename':name,'scale':f'{scale}x'}
        if dark: item['appearances']=[{'appearance':'luminosity','value':'dark'}]
        images.append(item)
(launch / 'Contents.json').write_text(json.dumps({'images':images,'info':{'version':1,'author':'xcode'}},indent=2)+'\n')
colors=[]
for dark, color in [(False,paper),(True,ink)]:
    rgb = {k:str(int(color[i:i+2],16)/255) for k,i in [('red',1),('green',3),('blue',5)]}
    item={'idiom':'universal','color':{'color-space':'srgb','components':{**rgb,'alpha':'1.0'}}}
    if dark: item['appearances']=[{'appearance':'luminosity','value':'dark'}]
    colors.append(item)
folder=root/'ios/Runner/Assets.xcassets/LaunchBackground.colorset';folder.mkdir(exist_ok=True)
(folder/'Contents.json').write_text(json.dumps({'colors':colors,'info':{'version':1,'author':'xcode'}},indent=2)+'\n')
print('Generated exact SVG-based icons and light/dark static splash assets.')
