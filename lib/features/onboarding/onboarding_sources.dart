import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/design.dart';
import '../../core/file_import.dart';
import '../../core/document.dart';
import '../../l10n/l10n.dart';
import '../library/pick_reading_file.dart';
import 'onboarding_widgets.dart';

enum PracticeSource { text, clipboard, web, files }

/// Explicit, disposable imports: no SQLite write and no network request.
class OnboardingSourceSheet extends StatefulWidget {
  const OnboardingSourceSheet({
    super.key,
    required this.source,
    required this.onImported,
  });
  final PracticeSource source;
  final ValueChanged<ImportedReading> onImported;

  @override
  State<OnboardingSourceSheet> createState() => _OnboardingSourceSheetState();
}

class _OnboardingSourceSheetState extends State<OnboardingSourceSheet> {
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _run(Future<ImportedReading?> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final reading = await action();
      if (!mounted) return;
      if (reading != null) {
        widget.onImported(reading);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = widget.source == PracticeSource.files
              ? context.l10n.fileReadFailed
              : context.l10n.pasteInvalid,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _paste() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      if (data?.text?.trim().isNotEmpty == true) {
        _text.text = data!.text!;
      } else {
        setState(() => _error = context.l10n.clipboardEmpty);
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.clipboardEmpty);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = ReaderColors.of(context);
    final source = widget.source;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.obSourcePrivacy,
          style: ReaderTypography.body(color: colors.secondary, size: 15),
        ),
        const SizedBox(height: 20),
        if (source == PracticeSource.text ||
            source == PracticeSource.clipboard) ...[
          ReaderTextField(
            controller: _text,
            label: l.textToRead,
            hint: l.pasteHint,
            lines: 4,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionButton(label: l.paste, onPressed: _busy ? null : _paste),
              ActionButton(
                label: l.tourSample,
                onPressed: _busy
                    ? null
                    : () {
                        _text.text = l.obSampleText;
                        setState(() => _error = null);
                      },
              ),
            ],
          ),
          ActionButton(
            label: l.read,
            primary: true,
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final text = TextImport.validate(
                      l.obSampleTitle,
                      _text.text,
                    );
                    return ImportedReading(
                      title: text.title,
                      text: text.text,
                      format: 'TXT',
                    );
                  }),
          ),
        ],
        if (source == PracticeSource.web) ...[
          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'example.org',
                  style: ReaderTypography.body(
                    color: colors.secondary,
                    size: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.obSampleTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.obSampleText,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l.obWebHint),
          const SizedBox(height: 16),
          ActionButton(
            label: l.obExtract,
            primary: true,
            onPressed: _busy
                ? null
                : () => _run(() async {
                    const escape = HtmlEscape();
                    return FileImport.parseWeb(
                      '<html><head><title>${escape.convert(l.obSampleTitle)}</title></head>'
                      '<body><nav>Menu</nav><article><h1>${escape.convert(l.obSampleTitle)}</h1>'
                      '<p>${escape.convert(l.obSampleText)}</p></article><script>void(0)</script></body></html>',
                      Uri.parse('https://example.org/article'),
                    );
                  }),
          ),
        ],
        if (source == PracticeSource.files) ...[
          Text(l.obFileHint),
          const SizedBox(height: 16),
          for (final ext in ['txt', 'md', 'epub']) ...[
            ActionButton(
              label: ext == 'md' ? 'Markdown' : ext.toUpperCase(),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      final data = await rootBundle.load(
                        'assets/onboarding/practice.$ext',
                      );
                      return FileImport.parse((
                        name: 'practice.$ext',
                        bytes: data.buffer.asUint8List(
                          data.offsetInBytes,
                          data.lengthInBytes,
                        ),
                      ));
                    }),
            ),
            const SizedBox(height: 8),
          ],
          ActionButton(
            label: l.importFile,
            onPressed: _busy ? null : () => _run(() => pickReadingFile(l)),
          ),
        ],
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CupertinoActivityIndicator()),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(_error!, style: TextStyle(color: colors.destructive)),
            ),
          ),
      ],
    );
  }
}
