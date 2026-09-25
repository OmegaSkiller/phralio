import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../../l10n/l10n.dart';

/// Native navigation on both platforms; LicenseRegistry includes bundled notices.
class LicensesScreen extends ConsumerStatefulWidget {
  const LicensesScreen({super.key});
  @override
  ConsumerState<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends ConsumerState<LicensesScreen> {
  late final entries = LicenseRegistry.licenses.toList();
  @override
  void initState() {
    super.initState();
    ref.read(usageAnalyticsProvider).view(UsageScreen.licenses);
  }

  @override
  Widget build(BuildContext context) => PlatformPage(
    title: context.l10n.licenses,
    child: FutureBuilder<List<LicenseEntry>>(
      future: entries,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(context.l10n.licensesLoadFailed));
        }
        if (!snapshot.hasData) {
          return Center(child: Text(context.l10n.licensesLoading));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final entry = snapshot.data![index];
            final title = entry.packages.join(', ');
            return ActionButton(
              label: title,
              onPressed: () => pushPage(
                context,
                PlatformPage(
                  title: title,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      entry.paragraphs.map((p) => p.text).join('\n\n'),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
