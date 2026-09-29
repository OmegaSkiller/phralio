# Approved Phralio artwork

Masters are copied unchanged from `../../../phralio-brandkit/assets/` (the
workspace's `phralio-brandkit/assets/` directory). The adjacent brandkit remains
reference material; app builds are self-contained.

`logo-ink.svg`, `logo-paper.svg` and `mark-*.svg` are rendered directly by
flutter_svg. Their padding preserves minimum clear space. `app-icon-source.svg`
is a byte-for-byte copy of the square `app-icon.svg`; the older canonical
`logo-mark.svg` and `logo-horizontal.svg` names alias the new exact masters.

`AppIcon.icon` is the shared, layered Apple icon included in the iOS and macOS
Xcode targets. It uses the exact stem and bowl paths from the approved square
master over Paper `#F4F0E7`, with the aperture left empty. Its dark appearance
reverses the brand colors to a Paper mark on Ink `#182523`; Icon Composer
generates the monochrome and platform treatments. The adjacent
`icon-composer-layers/` SVGs are the editable source layers. After editing them,
reimport the changed layers in Icon Composer and save `AppIcon.icon`.

`app-icon-dark.svg` and `app-icon-tinted.svg` are static fallback art; the dark
source is transparent so Apple's background can show through.

The iOS `AppIcon.appiconset` uses Apple's current single-size 1024 px layout
with default, dark, and grayscale tinted variants. Xcode derives smaller
sizes. The macOS asset catalog remains a static fallback source. Xcode uses the
included `AppIcon.icon` in preference to each target's asset-catalog icon and
generates legacy icon images from it for older OS releases.

Regenerate platform launcher/splash assets with `python3 tool/generate_icons.py`
from the app root. This optional build tool requires Node.js and sharp 0.35.4
(`npm install --prefix /tmp/phralio-artwork sharp@0.35.4`, then set
`NODE_PATH=/tmp/phralio-artwork/node_modules`). Rasterization uses SVG paths,
with no traced approximations. iOS and Android let the platform apply its mask;
the older macOS raster fallback keeps its rounded tile. Android adaptive and
monochrome icons uniformly scale the mark inside the circular safe zone.

Splash assets use the same mark on Paper/Ink, with no motion. OS launch themes
follow system appearance; a stored app-specific theme takes effect after the
local settings load. iOS and Android retain their own launch-screen lifecycle.


The app's `phralio-logo-motion.json` is the supplied Lottie composition with
only its playback bounds changed: `ip: 180`, `op: 240`, `fr: 60`. This plays
source seconds 3–4 once (one second), retaining all original vector paths and
absolute keyframes. The complete reference export remains untouched in the
workspace's `phralio-logo-motion/` folder. Startup waits for actual animation
completion and local library readiness, rather than a fixed full-film delay.
Tap skips it; reduced motion uses the still logo without an animation delay.
