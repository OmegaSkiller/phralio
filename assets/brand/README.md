# Approved Phralio artwork

Masters are copied unchanged from `../../../phralio-brandkit/assets/` (the
workspace's `phralio-brandkit/assets/` directory). The adjacent brandkit remains
reference material; app builds are self-contained.

`logo-ink.svg`, `logo-paper.svg` and `mark-*.svg` are rendered directly by
flutter_svg. Their padding preserves minimum clear space. `app-icon-source.svg`
is a byte-for-byte copy of the square `app-icon.svg`; the older canonical
`logo-mark.svg` and `logo-horizontal.svg` names alias the new exact masters.

Regenerate platform launcher/splash assets with `python3 tool/generate_icons.py`
from the app root. This optional build tool requires Node.js and sharp 0.35.4
(`npm install --prefix /tmp/phralio-artwork sharp@0.35.4`, then set
`NODE_PATH=/tmp/phralio-artwork/node_modules`). Rasterization uses SVG paths;
no traced approximations or baked-in platform corner masks. Android adaptive
and monochrome icons uniformly scale the mark inside the circular safe zone.

Splash assets use the same mark on Paper/Ink, with no motion. OS launch themes
follow system appearance; a stored app-specific theme takes effect after the
local settings load. iOS and Android retain their own launch-screen lifecycle.
