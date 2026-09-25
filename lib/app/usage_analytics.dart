import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// These fixed names and paths prevent reading content or user-entered titles
/// from reaching analytics. Events are aggregate product interactions only.
enum UsageScreen {
  library('/app/library', 'Library'),
  reader('/app/reader', 'Reader'),
  settings('/app/settings', 'Settings'),
  addText('/app/add-text', 'Add text'),
  licenses('/app/licenses', 'Licenses');

  const UsageScreen(this.path, this.title);
  final String path;
  final String title;
}

enum ReadingSource {
  txt('txt'),
  epub('epub'),
  paste('paste'),
  sample('sample');

  const ReadingSource(this.wire);
  final String wire;
}

enum UsageEvent {
  appForeground('app_foreground'),
  usageEnabled('usage_enabled'),
  importRequested('import_requested'),
  importCancelled('import_cancelled'),
  importSucceeded('import_succeeded'),
  importFailed('import_failed'),
  pasteSaved('paste_saved'),
  sampleAdded('sample_added'),
  starAdded('star_added'),
  starRemoved('star_removed'),
  libraryFilterChanged('library_filter_changed'),
  readingStarted('reading_started'),
  readingPaused('reading_paused'),
  readingFinished('reading_finished'),
  readingSeeked('reading_seeked'),
  readingSpeedChanged('reading_speed_changed'),
  appearanceChanged('appearance_changed'),
  transparencyChanged('transparency_changed'),
  smartPausesChanged('smart_pauses_changed'),
  focalHighlightChanged('focal_highlight_changed'),
  readerTypeSizeChanged('reader_type_size_changed');

  const UsageEvent(this.wire);
  final String wire;
}

class AnalyticsConfig {
  AnalyticsConfig({
    required String baseUrl,
    required this.websiteId,
    required this.hostname,
  }) : endpoint = _endpoint(baseUrl) {
    if (!RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')
            .hasMatch(websiteId) ||
        hostname.isEmpty ||
        hostname.length > 120 ||
        !RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(hostname)) {
      throw const FormatException('Invalid Umami website ID or hostname.');
    }
  }

  final Uri endpoint;
  final String websiteId;
  final String hostname;

  static Uri _endpoint(String baseUrl) {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const FormatException('Umami requires an HTTPS server URL.');
    }
    return Uri.parse(
      '${base.toString().replaceAll(RegExp(r'/+$'), '')}/api/send',
    );
  }

  static AnalyticsConfig? fromEnvironment() {
    const baseUrl = String.fromEnvironment('UMAMI_URL');
    const websiteId = String.fromEnvironment('UMAMI_WEBSITE_ID');
    const hostname = String.fromEnvironment('UMAMI_HOSTNAME');
    if (baseUrl.isEmpty || websiteId.isEmpty || hostname.isEmpty) return null;
    try {
      return AnalyticsConfig(
        baseUrl: baseUrl,
        websiteId: websiteId,
        hostname: hostname,
      );
    } on FormatException {
      return null;
    }
  }
}

/// Best-effort delivery: never blocks reading, stores no offline event queue,
/// and drops queued events immediately when the user turns sharing off.
class UsageAnalytics {
  UsageAnalytics({
    AnalyticsConfig? config,
    http.Client? client,
    bool enabled = false,
    String? platform,
    String? language,
  }) : _config = config ?? AnalyticsConfig.fromEnvironment(),
       _client = client ?? http.Client(),
       // Keep the public constructor argument separate from private state.
       // ignore: prefer_initializing_formals
       _enabled = enabled,
       _platform =
           platform ??
           switch (defaultTargetPlatform) {
             TargetPlatform.iOS => 'iOS',
             TargetPlatform.android => 'Android',
             _ => 'other',
           },
       _language =
           language ?? PlatformDispatcher.instance.locale.toLanguageTag();

  final AnalyticsConfig? _config;
  final http.Client _client;
  final String _platform;
  final String _language;
  String? _cache;
  bool _enabled;
  bool _closed = false;
  int _queued = 0;
  int _consentGeneration = 0;
  Future<void> _tail = Future.value();

  bool get available => _config != null;
  bool get enabled => _enabled && available && !_closed;
  set enabled(bool value) {
    if (_enabled && !value) _consentGeneration++;
    _enabled = value;
    if (!value) _cache = null;
  }

  Future<void> view(UsageScreen screen) => _enqueue(screen);

  Future<void> record(
    UsageEvent event, {
    UsageScreen screen = UsageScreen.library,
    ReadingSource? source,
  }) => _enqueue(screen, event: event, source: source);

  Future<void> _enqueue(
    UsageScreen screen, {
    UsageEvent? event,
    ReadingSource? source,
  }) {
    if (!enabled || _queued >= 16) return Future.value();
    _queued++;
    final consentGeneration = _consentGeneration;
    final work = _tail.then((_) async {
      if (enabled && consentGeneration == _consentGeneration) {
        await _send(screen, event, source, consentGeneration);
      }
    });
    _tail = work.whenComplete(() => _queued--);
    return _tail;
  }

  Future<void> _send(
    UsageScreen screen,
    UsageEvent? event,
    ReadingSource? source,
    int consentGeneration,
  ) async {
    final config = _config;
    if (config == null || !enabled) return;
    final payload = <String, Object>{
      'website': config.websiteId,
      'hostname': config.hostname,
      'url': screen.path,
      'title': screen.title,
      if (PlatformDispatcher.instance.views.isNotEmpty)
        'screen':
            '${PlatformDispatcher.instance.views.first.physicalSize.width.round()}x${PlatformDispatcher.instance.views.first.physicalSize.height.round()}',
      'language': _language,
      'referrer': '',
      'os': _platform,
      'device': 'mobile',
      'browser': 'Phralio',
      if (event != null) 'name': event.wire,
      if (source != null) 'data': {'source': source.wire},
    };
    try {
      final response = await _client
          .post(
            config.endpoint,
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'Phralio/Flutter ($_platform; Mobile)',
              if (_cache case final String cache) 'x-umami-cache': cache,
            },
            body: jsonEncode({'type': 'event', 'payload': payload}),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200 ||
          !enabled ||
          consentGeneration != _consentGeneration) {
        return;
      }
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['cache'] is String) {
        _cache = body['cache'] as String;
      }
    } catch (_) {
      // Analytics cannot interrupt an offline reading or expose diagnostics.
    }
  }

  void close() {
    _closed = true;
    enabled = false;
    _client.close();
  }
}
