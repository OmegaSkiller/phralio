# Phralio in the browser

The current mobile app and ../DESIGN.md own the identity and reading behavior.
This is a separate local WebExtension implementation, not a mobile storage migration.

- Use exact bundled split-P masters, IBM Plex Sans UI, all ten reader fonts and
  licenses. Newsreader leads editorial headings. Use white/black neutral surfaces
  and the current app's ten functional accent pairs, not the older warm UI palette.
- Toolbar click extracts the current page and opens an immersive reader tab that
  starts with saved settings. Browser/extension/store/PDF pages fail gracefully.
  A dedicated extension origin protects presentation and privileged controls from
  website styles and scripts. No always-on content script or all-sites permission.
- Reference inspected: the supplied Speed Reading Chrome listing. Borrow its
  centered stage, quiet surrounding prose and compact playback strip; do not copy
  third-party assets or its claims about comprehension/speed gains.
- The focal grapheme stays horizontally and vertically centered between the two
  scope marks, including with highlighting disabled. Fit long words on both sides
  of that fixed anchor. Progress sits below without displacing the reading field.
  Settings selects retain native menus with padded text and an inset Lucide chevron.
  No visible percentage in Read.
- Playing hides chrome. Click/Space pauses; paused chrome is fixed and only the
  text canvas moves word by word. Escape pauses before it navigates away.
- Home, Read, Saved and Settings remain available. Web pages, pasted text and
  explicit clipboard access replace mobile file import. Contents, images, stars,
  bookmarks and resume remain. A URL opens in the browser for a deliberate toolbar
  click, rather than granting persistent access to arbitrary sites.
- Browser glass is CSS, not native Apple Liquid Glass. Solid surfaces honor the
  app setting and OS reduced transparency/contrast. Respect reduced motion.
- No server, account, synchronization or analytics endpoint is introduced. No
  background clipboard reading, remote fonts, remote code or remote image fetches.
  Use only locally captured safe images; inaccessible images retain alt text.
- Render extracted content as text nodes. Never insert page HTML into the reader.
  Bound inputs, validate messages and serialize storage mutations in background.
  Pause hidden readers; never catch up by skipping unread words.
- Keep the existing ten locales through generated app catalogs plus translated
  extension-specific copy. Native selects and keyboard shortcuts support desktop.
- Build one source tree into Chrome MV3, Firefox MV3 and Safari MV3 manifests.
  Safari uses Apple's generated containing-app project. Store release is separate.
