import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../app/design.dart';

/// Native navigation on both platforms; LicenseRegistry includes bundled notices.
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});
  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late final entries = LicenseRegistry.licenses.toList();
  @override
  Widget build(BuildContext context) => PlatformPage(
    title: 'Open-source licenses',
    child: FutureBuilder<List<LicenseEntry>>(
      future: entries,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Licenses could not be loaded.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Loading licenses…'));
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
