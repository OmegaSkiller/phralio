# Library and appearance implementation

1. Extend the existing SQLite library without deleting documents or settings.
   Store metadata, word count, stars and an import fingerprint; load full text
   only when reading. Preserve the global word position on duplicate imports.
2. Import TXT and DRM-free EPUB using the native file picker. Decode and parse
   off the UI isolate. Read EPUB spine order into one text stream, so progress
   and restoration always refer to the whole book. Never execute book markup,
   extract archive paths to disk, or fetch remote resources. Bound source size,
   ZIP expansion and decoded text. Reject malformed or encrypted reading content.
3. Use Lucide for application icons. Keep the original Phralio brand mark.
   Persist System/Light/Dark appearance and a reduce-transparency option.
4. Add restrained Flutter-rendered glass to navigation and playback controls:
   blur, tint and a subtle rim. This is inspired by Apple Liquid Glass, not a
   native UIGlassEffect. Keep text surfaces opaque; use solid controls for high
   contrast or reduced transparency, with no decorative motion.
5. Verify TXT encodings, EPUB order and malformed input, schema migration,
   duplicate imports, stars, restart restoration, both themes and large type.
   Run the native reading flow on iOS and Android serially.

Scope: local text reading. EPUB illustrations, original page layout, DRM,
cloud synchronization and PDF are not part of this change. Progress represents
the current location, rather than a historical count of every word viewed.
