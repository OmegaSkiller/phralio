# Security and privacy

The app stores reading text and settings in local SQLite. It has no account or
content upload. SQLite is not additionally encrypted by this app; device security
and OS backup policies apply. Clipboard content is read only after the user taps
Paste. Document contents must never be included in diagnostics or telemetry.

Optional Umami analytics is disabled by default and requires both build-time
configuration and a saved in-app opt-in. It sends fixed screen paths and event
names, limited device metadata, and an optional fixed import source (`txt`, `epub`,
`paste`, `sample`) to the configured HTTPS server. It never includes reading text,
titles, filenames, document IDs or exact positions. The analytics server receives
the request IP address and User-Agent. There is no persistent event queue; failed
or offline events are dropped. Opting out clears the session token and discards
pending events, although a request already in flight may reach the server.

This is a pre-release milestone without a security support SLA. Do not disclose
private documents, credentials or exploitable security details in public pull
requests. A verified private reporting contact must be configured by the owner
before public distribution; none is invented here.

Production signing keys and store credentials belong outside this repository.
