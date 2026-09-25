# Third-party notices

The exact dependency graph is recorded in `pubspec.lock`. This inventory includes
runtime, native-plugin and development packages resolved for this milestone;
not every listed package ships in the app. Original license texts are retained
without replacing their copyright notices. Flutter also bundles runtime notices
in its asset license registry, accessible from Reading settings.

Direct dependencies: Riverpod (MIT), sqflite/native SQLite plugins (BSD-2-Clause),
characters, path, file_selector, crypto, http, markdown, intl and flutter_localizations (BSD-3-Clause); archive and xml (MIT);
html (MIT, additional notices retained); lucide_icons_flutter (MIT); flutter_svg
and its vector rendering dependencies (MIT/BSD notices below). Flutter/Dart SDK code
uses BSD-style licenses with separately attributed components. The SQLite engine
is public domain with wrapper notices preserved. Development tooling includes
fake_async (Apache-2.0) and sqflite_common_ffi (BSD-2-Clause).

Lucide icon fonts ship through the community Flutter port. The upstream Lucide
ISC and Feather MIT notices are retained in `third_party/licenses/lucide-upstream.txt`
and bundled in the in-app license registry. Framework assets keep SDK notices. Original
Phralio artwork is governed by TRADEMARKS.md.

IBM Plex Sans and Newsreader ship as original variable TTF files with their
SIL Open Font License notices in `assets/fonts/`, also available in-app.

The optional icon generation tool uses Node.js and sharp (Apache-2.0 and its
bundled libvips notices). These build tools are not bundled in mobile binaries. Android/Xcode
platform libraries retain their platform license terms. A signed release still
requires review of the final binary/native dependency manifest.

Regenerate this inventory with `python3 tool/collect_notices.py` after resolution.

| Resolved package | Preserved notice |
| --- | --- |
| `archive` | [License](third_party/licenses/archive.txt) |
| `args` | [License](third_party/licenses/args.txt) |
| `async` | [License](third_party/licenses/async.txt) |
| `boolean_selector` | [License](third_party/licenses/boolean_selector.txt) |
| `characters` | [License](third_party/licenses/characters.txt) |
| `clock` | [License](third_party/licenses/clock.txt) |
| `code_assets` | [License](third_party/licenses/code_assets.txt) |
| `collection` | [License](third_party/licenses/collection.txt) |
| `cross_file` | [License](third_party/licenses/cross_file.txt) |
| `crypto` | [License](third_party/licenses/crypto.txt) |
| `csslib` | [License](third_party/licenses/csslib.txt) |
| `fake_async` | [License](third_party/licenses/fake_async.txt) |
| `ffi` | [License](third_party/licenses/ffi.txt) |
| `file_selector_android` | [License](third_party/licenses/file_selector_android.txt) |
| `file_selector_ios` | [License](third_party/licenses/file_selector_ios.txt) |
| `file_selector_linux` | [License](third_party/licenses/file_selector_linux.txt) |
| `file_selector_macos` | [License](third_party/licenses/file_selector_macos.txt) |
| `file_selector_platform_interface` | [License](third_party/licenses/file_selector_platform_interface.txt) |
| `file_selector_web` | [License](third_party/licenses/file_selector_web.txt) |
| `file_selector_windows` | [License](third_party/licenses/file_selector_windows.txt) |
| `file_selector` | [License](third_party/licenses/file_selector.txt) |
| `file` | [License](third_party/licenses/file.txt) |
| `fixnum` | [License](third_party/licenses/fixnum.txt) |
| `flutter_driver` | [License](third_party/licenses/flutter_driver.txt) |
| `flutter_lints` | [License](third_party/licenses/flutter_lints.txt) |
| `flutter_localizations` | [License](third_party/licenses/flutter_localizations.txt) |
| `flutter_riverpod` | [License](third_party/licenses/flutter_riverpod.txt) |
| `flutter_svg` | [License](third_party/licenses/flutter_svg.txt) |
| `flutter_test` | [License](third_party/licenses/flutter_test.txt) |
| `flutter_web_plugins` | [License](third_party/licenses/flutter_web_plugins.txt) |
| `flutter` | [License](third_party/licenses/flutter.txt) |
| `fuchsia_remote_debug_protocol` | [License](third_party/licenses/fuchsia_remote_debug_protocol.txt) |
| `glob` | [License](third_party/licenses/glob.txt) |
| `hooks` | [License](third_party/licenses/hooks.txt) |
| `html` | [License](third_party/licenses/html.txt) |
| `http_parser` | [License](third_party/licenses/http_parser.txt) |
| `http` | [License](third_party/licenses/http.txt) |
| `integration_test` | [License](third_party/licenses/integration_test.txt) |
| `intl` | [License](third_party/licenses/intl.txt) |
| `leak_tracker_flutter_testing` | [License](third_party/licenses/leak_tracker_flutter_testing.txt) |
| `leak_tracker_testing` | [License](third_party/licenses/leak_tracker_testing.txt) |
| `leak_tracker` | [License](third_party/licenses/leak_tracker.txt) |
| `lints` | [License](third_party/licenses/lints.txt) |
| `listen` | [License](third_party/licenses/listen.txt) |
| `logging` | [License](third_party/licenses/logging.txt) |
| `lucide_icons_flutter` | [License](third_party/licenses/lucide_icons_flutter.txt) |
| `markdown` | [License](third_party/licenses/markdown.txt) |
| `matcher` | [License](third_party/licenses/matcher.txt) |
| `material_color_utilities` | [License](third_party/licenses/material_color_utilities.txt) |
| `meta` | [License](third_party/licenses/meta.txt) |
| `native_toolchain_c` | [License](third_party/licenses/native_toolchain_c.txt) |
| `path_parsing` | [License](third_party/licenses/path_parsing.txt) |
| `path` | [License](third_party/licenses/path.txt) |
| `petitparser` | [License](third_party/licenses/petitparser.txt) |
| `platform` | [License](third_party/licenses/platform.txt) |
| `plugin_platform_interface` | [License](third_party/licenses/plugin_platform_interface.txt) |
| `posix` | [License](third_party/licenses/posix.txt) |
| `process` | [License](third_party/licenses/process.txt) |
| `pub_semver` | [License](third_party/licenses/pub_semver.txt) |
| `record_use` | [License](third_party/licenses/record_use.txt) |
| `riverpod` | [License](third_party/licenses/riverpod.txt) |
| `sky_engine` | [License](third_party/licenses/sky_engine.txt) |
| `source_span` | [License](third_party/licenses/source_span.txt) |
| `sqflite_android` | [License](third_party/licenses/sqflite_android.txt) |
| `sqflite_common_ffi` | [License](third_party/licenses/sqflite_common_ffi.txt) |
| `sqflite_common` | [License](third_party/licenses/sqflite_common.txt) |
| `sqflite_darwin` | [License](third_party/licenses/sqflite_darwin.txt) |
| `sqflite_platform_interface` | [License](third_party/licenses/sqflite_platform_interface.txt) |
| `sqflite` | [License](third_party/licenses/sqflite.txt) |
| `sqlite3` | [License](third_party/licenses/sqlite3.txt) |
| `stack_trace` | [License](third_party/licenses/stack_trace.txt) |
| `state_notifier` | [License](third_party/licenses/state_notifier.txt) |
| `stream_channel` | [License](third_party/licenses/stream_channel.txt) |
| `string_scanner` | [License](third_party/licenses/string_scanner.txt) |
| `sync_http` | [License](third_party/licenses/sync_http.txt) |
| `synchronized` | [License](third_party/licenses/synchronized.txt) |
| `term_glyph` | [License](third_party/licenses/term_glyph.txt) |
| `test_api` | [License](third_party/licenses/test_api.txt) |
| `typed_data` | [License](third_party/licenses/typed_data.txt) |
| `uuid` | [License](third_party/licenses/uuid.txt) |
| `vector_graphics_codec` | [License](third_party/licenses/vector_graphics_codec.txt) |
| `vector_graphics_compiler` | [License](third_party/licenses/vector_graphics_compiler.txt) |
| `vector_graphics` | [License](third_party/licenses/vector_graphics.txt) |
| `vector_math` | [License](third_party/licenses/vector_math.txt) |
| `vm_service` | [License](third_party/licenses/vm_service.txt) |
| `web` | [License](third_party/licenses/web.txt) |
| `webdriver` | [License](third_party/licenses/webdriver.txt) |
| `xml` | [License](third_party/licenses/xml.txt) |
| `yaml` | [License](third_party/licenses/yaml.txt) |
