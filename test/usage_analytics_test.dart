import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phralio/app/usage_analytics.dart';
import 'package:phralio/core/settings.dart';

void main() {
  final config = AnalyticsConfig(
    baseUrl: 'https://stats.example.org',
    websiteId: '12345678-1234-1234-1234-123456789abc',
    hostname: 'app.example.org',
  );

  test(
    'consent defaults off and only fixed app metadata reaches Umami',
    () async {
      final requests = <http.Request>[];
      final analytics = UsageAnalytics(
        config: config,
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{"cache":"session-token"}', 200);
        }),
        platform: 'iOS',
        language: 'en-US',
      );
      await analytics.view(UsageScreen.reader);
      expect(requests, isEmpty);

      analytics.enabled = true;
      await analytics.view(UsageScreen.reader);
      await analytics.record(
        UsageEvent.readingStarted,
        screen: UsageScreen.reader,
        source: ReadingSource.epub,
      );
      expect(requests, hasLength(2));
      expect(
        requests.first.url.toString(),
        'https://stats.example.org/api/send',
      );
      expect(requests.first.headers['User-Agent'], contains('Phralio/Flutter'));
      expect(requests.last.headers['x-umami-cache'], 'session-token');
      final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body['type'], 'event');
      final payload = Map<String, dynamic>.from(body['payload'] as Map);
      expect(payload.remove('screen'), matches(r'^\d+x\d+$'));
      expect(payload, {
        'website': config.websiteId,
        'hostname': config.hostname,
        'url': '/app/reader',
        'title': 'Reader',
        'language': 'en-US',
        'referrer': '',
        'os': 'iOS',
        'device': 'mobile',
        'browser': 'Phralio',
        'name': 'reading_started',
        'data': {'source': 'epub'},
      });
      expect(requests.last.body, isNot(contains('book title')));
      analytics.close();
    },
  );

  test(
    'opt-out clears queued events even after sharing is re-enabled',
    () async {
      final firstReply = Completer<http.Response>();
      var sends = 0;
      final analytics = UsageAnalytics(
        config: config,
        enabled: true,
        client: MockClient((_) {
          sends++;
          return firstReply.future;
        }),
      );
      final first = analytics.record(UsageEvent.appForeground);
      final queued = analytics.record(UsageEvent.importRequested);
      await Future<void>.delayed(Duration.zero);
      analytics.enabled = false;
      analytics.enabled = true;
      firstReply.complete(http.Response('{"cache":"old-session"}', 200));
      await Future.wait([first, queued]);
      expect(sends, 1);
      analytics.close();
    },
  );

  test('offline delivery is ignored and settings restore consent', () async {
    final analytics = UsageAnalytics(
      config: config,
      enabled: true,
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await analytics.record(UsageEvent.appForeground);
    expect(analytics.enabled, true);
    analytics.close();
    expect(ReaderSettings.fromJson({}).shareUsage, false);
    expect(
      ReaderSettings.fromJson(ReaderSettings(shareUsage: true).toJson())
          .shareUsage,
      true,
    );
    expect(
      () => AnalyticsConfig(
        baseUrl: 'http://stats.example.org',
        websiteId: config.websiteId,
        hostname: config.hostname,
      ),
      throwsFormatException,
    );
  });
}
