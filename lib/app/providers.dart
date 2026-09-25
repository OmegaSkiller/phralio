import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/document.dart';
import '../core/settings.dart';
import '../features/library/library_store.dart';
import '../features/premium/capabilities.dart';

final storeProvider = Provider<LibraryStore>(
  (ref) => throw StateError('Library must be opened before launch.'),
);
final initialSettingsProvider = Provider<ReaderSettings>(
  (ref) => ReaderSettings(),
);
final capabilitiesProvider = Provider<ReaderCapabilities>(
  (ref) => const ReaderCapabilities(),
);
final libraryProvider = FutureProvider<List<ReaderDocument>>(
  (ref) => ref.watch(storeProvider).all(),
);
final settingsProvider = NotifierProvider<SettingsController, ReaderSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() => ref.watch(initialSettingsProvider);
  Future<void> update(ReaderSettings value) async {
    await ref.read(storeProvider).saveSettings(value);
    state = value;
  }
}
