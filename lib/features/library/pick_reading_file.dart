import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import '../../core/file_import.dart';
import '../../core/remote_import.dart';
import '../../l10n/app_localizations.dart';

/// Shared native file import boundary for the library, desktop and practice tour.
/// File providers can report stale sizes, so enforce the limit while streaming.
Future<ImportedReading?> pickReadingFile(AppLocalizations l10n) async {
  final file = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: l10n.importFile,
        extensions: ['txt', 'epub', 'md', 'markdown'],
        mimeTypes: ['text/plain', 'application/epub+zip', 'text/markdown'],
        uniformTypeIdentifiers: [
          'public.plain-text',
          'net.daringfireball.markdown',
          'org.idpf.epub-container',
        ],
      ),
    ],
  );
  if (file == null) return null;
  if (await file.length() > FileImport.maxFileBytes) {
    throw FormatException(l10n.fileTooLarge);
  }
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in file.openRead()) {
    if (bytes.length + chunk.length > FileImport.maxFileBytes) {
      throw FormatException(l10n.fileTooLarge);
    }
    bytes.add(chunk);
  }
  var reading = await compute(FileImport.parse, (
    name: file.name,
    bytes: bytes.takeBytes(),
  ));
  if (reading.format == 'Markdown' && reading.images.isNotEmpty) {
    final importer = RemoteImport();
    try {
      reading = await importer.hydrateImages(reading);
    } finally {
      importer.close();
    }
  }
  return reading;
}
