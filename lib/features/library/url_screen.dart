import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../../core/remote_import.dart';
import '../reader/reader_screen.dart';

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
      if (mounted) showProblem(context, error.message);
    } catch (_) {
      if (mounted) {
        showProblem(
          context,
          'This page could not be downloaded. Check the URL and try again.',
        );
      }
    } finally {
      importer.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PlatformPage(
    title: 'Read from URL',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Paste a public HTTPS article or text page.'),
        const SizedBox(height: 16),
        isApple(context)
            ? CupertinoTextField(
                controller: _controller,
                placeholder: 'https://example.org/article',
                keyboardType: TextInputType.url,
                autocorrect: false,
                padding: const EdgeInsets.all(16),
              )
            : TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Page URL',
                  border: OutlineInputBorder(),
                ),
              ),
        const SizedBox(height: 16),
        const Text(
          'The readable text and supported images are saved on this device. Scripts, navigation and forms are removed.',
        ),
        const SizedBox(height: 24),
        ActionButton(
          label: _busy ? 'Opening…' : 'Save and read',
          icon: LucideIcons.link,
          primary: true,
          onPressed: _busy ? null : _open,
        ),
      ],
    ),
  );
}
