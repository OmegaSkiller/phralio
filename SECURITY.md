# Security and privacy

The app stores reading text and settings in local SQLite. It has no account or
content upload. SQLite is not additionally encrypted by this app; device security
and OS backup policies apply. Clipboard content is read only after the user taps
Paste or Read clipboard. Document contents must never be included in diagnostics
or telemetry.

URL import fetches a user-entered public HTTPS page. Only HTML, Markdown or plain
text is accepted; executable markup is never rendered. Scripts, navigation,
forms and hidden content are removed. Redirects, page bytes and image bytes are
bounded, and only same-host images are fetched for article URLs. Imported text
and images are then stored locally for offline reading. Markdown image links to
public HTTPS hosts are fetched when the user imports that file. A remote site
receives the device's network address and request metadata during import.

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
