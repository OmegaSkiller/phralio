import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../../core/remote_import.dart';
import '../reader/reader_screen.dart';
import '../../l10n/l10n.dart';

class UrlScreen extends ConsumerStatefulWidget {
  const UrlScreen({super.key});
  @override
  ConsumerState<UrlScreen> createState() => _UrlScreenState();
}

class _UrlScreenState extends ConsumerState<UrlScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(usageAnalyticsProvider).view(UsageScreen.addUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    final importer = RemoteImport();
    try {
      final reading = await importer.page(_controller.text);
      final store = ref.read(storeProvider);
      final id = await store.importReading(reading);
      ref
          .read(usageAnalyticsProvider)
          .record(UsageEvent.importSucceeded, source: ReadingSource.web);
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
    } on FormatException catch (error) {
      if (mounted) {
        showProblem(
          context,
          context.l10n.localeName == 'en'
              ? error.message
              : context.l10n.urlReadFailed,
        );
      }
    } catch (_) {
      if (mounted) {
        showProblem(context, context.l10n.urlDownloadFailed);
      }
    } finally {
      importer.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PlatformPage(
    title: context.l10n.readFromUrl,
    child: ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        Text(context.l10n.urlHint),
        const SizedBox(height: 16),
        isApple(context)
            ? CupertinoTextField(
                controller: _controller,
                placeholder: context.l10n.urlPlaceholder,
                keyboardType: TextInputType.url,
                autocorrect: false,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ReaderColors.of(context).surface,
                  borderRadius: BorderRadius.circular(20),
                ),
              )
            : TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: context.l10n.pageUrl,
                  filled: true,
                  fillColor: ReaderColors.of(context).surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
        const SizedBox(height: 16),
        Text(
          context.l10n.urlPrivacy,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: ReaderColors.of(context).secondary,
          ),
        ),
        const SizedBox(height: 24),
        ActionButton(
          label: _busy ? context.l10n.opening : context.l10n.saveAndRead,
          icon: LucideIcons.link,
          primary: true,
          onPressed: _busy ? null : _open,
        ),
      ],
    ),
  );
}
