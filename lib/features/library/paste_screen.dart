import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import 'library_store.dart';
import '../reader/reader_screen.dart';

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
    setState(() => _saving = true);
    try {
      final LibraryStore store = ref.read(storeProvider);
      final id = await store.add(_title.text, _text.text);
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
      if (mounted) await showProblem(context, e.message);
    } catch (_) {
      if (mounted) {
        await showProblem(
          context,
          'Your text could not be saved. It is still here; please try again.',
        );
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
    final colors = ReaderColors.of(context);
    return isApple(context)
        ? CupertinoTextField(
            controller: controller,
            placeholder: hint,
            maxLines: lines,
            padding: const EdgeInsets.all(16),
            style: TextStyle(color: colors.text, fontSize: 17),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.separator),
              borderRadius: BorderRadius.circular(12),
            ),
          )
        : TextField(
            controller: controller,
            maxLines: lines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: colors.surface,
              border: const OutlineInputBorder(),
            ),
          );
  }

  @override
  Widget build(BuildContext context) => PlatformPage(
    title: 'Add text',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Semantics(
          label: 'Reading title',
          child: _field(context, _title, 'Give this reading a name', 1),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your text',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ActionButton(
              label: 'Paste',
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
          label: 'Text to read',
          child: _field(
            context,
            _text,
            'Paste a passage, article, or a thought worth returning to.',
            10,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Up to 200,000 characters. Stored only on this device.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 24),
        ActionButton(
          label: _saving ? 'Saving…' : 'Save and read',
          primary: true,
          onPressed: _saving ? null : _save,
        ),
      ],
    ),
  );
}
