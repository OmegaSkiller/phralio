import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'document.dart';
import 'file_import.dart';

/// Downloads a user-chosen public HTTPS page and a bounded set of its images.
/// Redirects are inspected before following them; scripts are never executed.
class RemoteImport {
  RemoteImport({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const maxPageBytes = 4 * 1024 * 1024;
  static const maxImages = 24;
  static const maxImageBytes = 2 * 1024 * 1024;

  static Uri validate(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        InternetAddress.tryParse(uri.host) != null ||
        uri.host == 'localhost' ||
        uri.host.endsWith('.localhost') ||
        uri.host.endsWith('.local') ||
        uri.host.endsWith('.internal')) {
      throw const FormatException('Enter a public HTTPS URL.');
    }
    return uri.replace(fragment: '');
  }

  Future<({Uint8List bytes, String contentType, Uri finalUrl})> _get(
    Uri start,
    int maxBytes, {
    String? allowedHost,
  }) async {
    var url = start;
    for (var redirect = 0; redirect <= 3; redirect++) {
      if (allowedHost != null && url.host != allowedHost) {
        throw const FormatException(
          'This image redirects outside the page site.',
        );
      }
      final request = http.Request('GET', url)
        ..followRedirects = false
        ..headers['Accept'] =
            'text/html, text/plain, text/markdown, image/png, image/jpeg, image/webp, image/gif';
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 10));
      if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
        final location = response.headers['location'];
        if (location == null || redirect == 3) {
          throw const FormatException('This URL redirects too many times.');
        }
        url = validate(url.resolve(location).toString());
        continue;
      }
      if (response.statusCode != 200) {
        throw FormatException('This URL returned HTTP ${response.statusCode}.');
      }
      if ((response.contentLength ?? 0) > maxBytes) {
        throw const FormatException('This page or image is too large.');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 10),
      )) {
        if (builder.length + chunk.length > maxBytes) {
          throw const FormatException('This page or image is too large.');
        }
        builder.add(chunk);
      }
      return (
        bytes: builder.takeBytes(),
        contentType:
            response.headers['content-type']
                ?.split(';')
                .first
                .trim()
                .toLowerCase() ??
            '',
        finalUrl: url,
      );
    }
    throw const FormatException('This URL redirects too many times.');
  }

  Future<ImportedReading> page(String rawUrl) async {
    final result = await _get(validate(rawUrl), maxPageBytes);
    final text = FileImport.decodeText(result.bytes);
    final contentType = result.contentType;
    final book = switch (contentType) {
      'text/html' ||
      'application/xhtml+xml' => FileImport.parseWeb(text, result.finalUrl),
      'text/markdown' => FileImport.parse((
        name: 'page.md',
        bytes: result.bytes,
      )),
      'text/plain' => FileImport.parse((name: 'page.txt', bytes: result.bytes)),
      _ => throw const FormatException('This URL is not a readable text page.'),
    };
    return hydrateImages(book, allowedHost: result.finalUrl.host);
  }

  Future<ImportedReading> hydrateImages(
    ImportedReading book, {
    String? allowedHost,
  }) async {
    final resolved = <ReadingImage>[];
    var total = 0;
    for (final image in book.images.take(maxImages)) {
      if (image.bytes != null) {
        resolved.add(image);
        continue;
      }
      Uint8List? bytes;
      try {
        final source = image.source;
        if (source != null && source.startsWith('data:image/')) {
          final data = UriData.parse(source);
          if ([
                'image/png',
                'image/jpeg',
                'image/webp',
                'image/gif',
              ].contains(data.mimeType) &&
              source.length <= maxImageBytes * 2) {
            bytes = FileImport.safeImage(
              Uint8List.fromList(data.contentAsBytes()),
            );
          }
        } else if (source != null) {
          final uri = validate(source);
          if (allowedHost == null || uri.host == allowedHost) {
            final response = await _get(
              uri,
              maxImageBytes,
              allowedHost: allowedHost,
            );
            if (response.contentType.startsWith('image/')) {
              bytes = FileImport.safeImage(response.bytes);
            }
          }
        }
      } catch (_) {
        // Keep text and image position when an optional image cannot load.
      }
      if (bytes != null && total + bytes.length <= 16 * 1024 * 1024) {
        total += bytes.length;
      } else {
        bytes = null;
      }
      resolved.add(
        ReadingImage(
          position: image.position,
          alt: image.alt,
          bytes: bytes,
          source: image.source,
        ),
      );
    }
    return book.withImages(resolved);
  }

  void close() => _client.close();
}
