# Security and privacy

The current app stores reading text and settings in local SQLite. It has no
account, backend, analytics or content upload. SQLite is not additionally
encrypted by this app; device security and OS backup policies apply. Clipboard
content is read only after the user taps Paste. Document contents must never be
included in diagnostics or telemetry.

This is a pre-release milestone without a security support SLA. Do not disclose
private documents, credentials or exploitable security details in public pull
requests. A verified private reporting contact must be configured by the owner
before public distribution; none is invented here.

Production signing keys and store credentials belong outside this repository.
