import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import 'library_store.dart';
import '../reader/reader_screen.dart';
import '../../l10n/l10n.dart';

class PasteScreen extends ConsumerStatefulWidget {
  const PasteScreen({super.key});
  @override
  ConsumerState<PasteScreen> createState() => _PasteScreenState();
}

class _PasteScreenState extends ConsumerState<PasteScreen> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    ref.read(usageAnalyticsProvider).view(UsageScreen.addText);
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final untitled = context.l10n.untitledReading;
    setState(() => _saving = true);
    try {
      final LibraryStore store = ref.read(storeProvider);
      final id = await store.add(
        _title.text.trim().isEmpty ? untitled : _title.text,
        _text.text,
      );
      ref
          .read(usageAnalyticsProvider)
          .record(UsageEvent.pasteSaved, source: ReadingSource.paste);
      final document = await store.document(id);
      ref.invalidate(libraryProvider);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        isApple(context)
            ? CupertinoPageRoute(
                builder: (_) => ReaderScreen(document: document),
              )
            : MaterialPageRoute(
                builder: (_) => ReaderScreen(document: document),
              ),
      );
    } on FormatException catch (e) {
      if (mounted) {
        await showProblem(
          context,
          context.l10n.localeName == 'en'
              ? e.message
              : context.l10n.pasteInvalid,
        );
      }
    } catch (_) {
      if (mounted) {
        await showProblem(context, context.l10n.textSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String hint,
    int lines,
  ) {
    return ReaderTextField(controller: controller, hint: hint, lines: lines);
  }

  @override
  Widget build(BuildContext context) => PlatformPage(
    title: context.l10n.addText,
    child: ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        Text(
          context.l10n.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: context.l10n.readingTitle,
          child: _field(context, _title, context.l10n.giveName, 1),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.yourText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ActionButton(
              label: context.l10n.paste,
              onPressed: _saving
                  ? null
                  : () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (mounted && data?.text != null) {
                        _text.text = data!.text!;
                      }
                    },
            ),
          ],
        ),
        Semantics(
          label: context.l10n.textToRead,
          child: _field(context, _text, context.l10n.pasteHint, 10),
        ),
        const SizedBox(height: 16),
        Text(context.l10n.pasteLimit, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 24),
        ActionButton(
          label: _saving ? context.l10n.saving : context.l10n.saveAndRead,
          primary: true,
          onPressed: _saving ? null : _save,
        ),
      ],
    ),
  );
}
