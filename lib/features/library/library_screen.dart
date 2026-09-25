import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/identity.dart';
import '../../app/providers.dart';
import '../reader/reader_screen.dart';
import '../reader/settings_screen.dart';
import 'paste_screen.dart';

const sampleText = '''A little more room for words.

Reading can be a place to settle, not another task to race through. Bring a passage here, choose a comfortable pace, and let each word arrive at the same quiet point.

Start slowly. Notice how commas make a small space, and how a full stop gives a thought time to land. You can pause whenever you like, return to a sentence, or change the pace as you go.

The number on the screen is a setting, not a score. Different writing asks for different attention. A familiar story and a difficult argument do not need the same rhythm.

Your reading stays on this device. There is no account to create and no cloud to wait for. When you leave, your place is saved. Come back when you are ready.

One word. Then the next.''';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ReaderColors.of(context);
    final library = ref.watch(libraryProvider);
    return PlatformPage(
      title: ProductIdentity.displayName,
      trailing: IconAction(
        label: 'Reading settings',
        icon: isApple(context)
            ? CupertinoIcons.slider_horizontal_3
            : Icons.tune,
        onPressed: () => pushPage(context, const SettingsScreen()),
      ),
      child: library.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your library could not be loaded.'),
              ActionButton(
                label: 'Try again',
                onPressed: () => ref.invalidate(libraryProvider),
              ),
            ],
          ),
        ),
        data: (documents) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(),
                    const SizedBox(height: 24),
                    Text(
                      'Make room\nfor a good read.',
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.12,
                        letterSpacing: -1.0,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your words. Your pace.',
                      style: TextStyle(fontSize: 17, color: colors.secondary),
                    ),
                    const SizedBox(height: 24),
                    ActionButton(
                      label: 'Add text',
                      primary: true,
                      icon: isApple(context) ? CupertinoIcons.add : Icons.add,
                      onPressed: () => pushPage(context, const PasteScreen()),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'YOUR LIBRARY',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.6,
                        color: colors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (documents.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('A quiet shelf, ready for your words.'),
                      const SizedBox(height: 16),
                      ActionButton(
                        label: 'Try a short reading',
                        onPressed: () async {
                          try {
                            await ref
                                .read(storeProvider)
                                .add('A little more room', sampleText);
                            ref.invalidate(libraryProvider);
                          } catch (_) {
                            if (context.mounted) {
                              showProblem(
                                context,
                                'The reading could not be saved. Please try again.',
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final document = documents[index];
                  final detail =
                      '${document.tokens.length} words · ${(document.progress * 100).round()}% read';
                  final content = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 46,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.title,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  color: colors.text,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                detail,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          isApple(context)
                              ? CupertinoIcons.chevron_right
                              : Icons.chevron_right,
                          size: 20,
                          color: colors.secondary,
                        ),
                      ],
                    ),
                  );
                  void open() async {
                    await pushPage(context, ReaderScreen(document: document));
                    ref.invalidate(libraryProvider);
                  }

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.separator),
                      ),
                    ),
                    child: isApple(context)
                        ? CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: open,
                            child: content,
                          )
                        : InkWell(onTap: open, child: content),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Saved on this device. No account needed.',
                  style: TextStyle(fontSize: 13, color: colors.subtle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
