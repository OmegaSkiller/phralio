#!/usr/bin/env python3
"""Synchronize identity into platform build files; no reader logic depends on it."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
identity = json.loads((root / 'tool/identity.json').read_text())

def replace(path, pattern, value):
    file = root / path
    file.write_text(re.sub(pattern, lambda _: value, file.read_text()))

def dart_string(value):
    return json.dumps(value, ensure_ascii=False)

(root / 'lib/app/identity.dart').write_text(
    '/// Generated from tool/identity.json. Run python3 tool/sync_identity.py.\n'
    'abstract final class ProductIdentity {\n' + ''.join(
        f'  static const {field} = {dart_string(identity[key])};\n'
        for field, key in [('displayName', 'display_name'), ('tagline', 'tagline'), ('copyright', 'copyright')]
    ) + '}\n'
)
replace('pubspec.yaml', r'(?m)^name: .*$', f"name: {identity['package_name']}")
for key, value in [('CFBundleDisplayName', identity['display_name']), ('CFBundleName', identity['package_name'])]:
    replace('ios/Runner/Info.plist', rf'<key>{key}</key>\s*<string>[^<]*</string>', f'<key>{key}</key>\n\t<string>{value}</string>')
p = root / 'ios/Runner.xcodeproj/project.pbxproj'
s = p.read_text()
s = re.sub(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', lambda m: f"PRODUCT_BUNDLE_IDENTIFIER = {identity['apple_bundle_id']}{'.RunnerTests' if m[1].endswith('.RunnerTests') else ''};", s)
p.write_text(s)
replace('android/app/src/main/AndroidManifest.xml', r'android:label="[^"]*"', f'android:label="{identity["display_name"]}"')
replace('android/app/build.gradle.kts', r'applicationId = "[^"]*"', f'applicationId = "{identity["android_application_id"]}"')
print('Identity synchronized. Run dart format lib/app/identity.dart.')
