#!/usr/bin/env python3
"""Preserve resolved package licenses after flutter pub get, including native plugins."""
import json
from pathlib import Path
from urllib.parse import unquote, urlparse
root = Path(__file__).resolve().parent.parent
config = root / '.dart_tool/package_config.json'
out = root / 'third_party/licenses'
out.mkdir(parents=True, exist_ok=True)
rows = []
missing = []
for package in json.loads(config.read_text())['packages']:
    if package['name'] == 'phralio':
        continue
    uri = package['rootUri']
    directory = Path(unquote(urlparse(uri).path)) if uri.startswith('file:') else (config.parent / uri).resolve()
    candidates = [p for p in directory.iterdir() if p.is_file() and p.name.upper() in ['LICENSE','LICENSE.MD','LICENSE.TXT','COPYING']]
    if not candidates and directory.parent.name == 'packages':
        sdk_license = directory.parent.parent / 'LICENSE'
        if sdk_license.exists():
            candidates = [sdk_license]
    if not candidates:
        missing.append(package['name'])
        continue
    target = out / f'{package["name"]}.txt'
    target.write_text(candidates[0].read_text())
    rows.append(f'| `{package["name"]}` | [License]({target.relative_to(root)}) |')
header = '''# Third-party notices

The exact dependency graph is recorded in `pubspec.lock`. This inventory includes
runtime, native-plugin and development packages resolved for this milestone;
not every listed package ships in the app. Original license texts are retained
without replacing their copyright notices. Flutter also bundles runtime notices
in its asset license registry, accessible from Reading settings.

Direct dependencies: Riverpod (MIT), sqflite/native SQLite plugins (BSD-2-Clause),
characters, path, file_selector and crypto (BSD-3-Clause); archive and xml (MIT);
html (MIT, additional notices retained); lucide_icons_flutter (MIT). Flutter/Dart SDK code
uses BSD-style licenses with separately attributed components. The SQLite engine
is public domain with wrapper notices preserved. Development tooling includes
fake_async (Apache-2.0) and sqflite_common_ffi (BSD-2-Clause).

Lucide icon fonts ship through the community Flutter port. The upstream Lucide
ISC and Feather MIT notices are retained in `third_party/licenses/lucide-upstream.txt`
and bundled in the in-app license registry. Framework assets keep SDK notices. Original
Phralio artwork is governed by TRADEMARKS.md.

The optional icon generation tool uses Pillow12.3.0, whose HPND license applies
to that build tool; it is not linked or bundled in mobile binaries. Android/Xcode
platform libraries retain their platform license terms. A signed release still
requires review of the final binary/native dependency manifest.

Regenerate this inventory with `python3 tool/collect_notices.py` after resolution.

| Resolved package | Preserved notice |
| --- | --- |
'''
(root / 'THIRD_PARTY_NOTICES.md').write_text(header + '\n'.join(sorted(rows))+'\n')
print(f'Preserved {len(rows)} package notices. No license file: {missing}')
if missing:
    raise SystemExit(1)
