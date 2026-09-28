import 'package:flutter_test/flutter_test.dart';
import 'package:phralio/app/design.dart';
import 'package:phralio/app/native_controls.dart';

// Flutter test pointer injection cannot operate UIKit/AppKit menu children.
// On Apple platforms these helpers exercise the native channel's Dart callbacks;
// native hit testing and menu presentation are checked separately on the device.
// Android exercises the visible fallback controls end to end.
Future<void> tapIcon(WidgetTester tester, String label) async {
  if (NativeControl.available) {
    tester
        .widget<IconAction>(
          find.byWidgetPredicate((w) => w is IconAction && w.label == label),
        )
        .onPressed!();
  } else {
    await tester.tap(find.bySemanticsLabel(label));
  }
  await tester.pumpAndSettle();
}

Future<void> tapTab(WidgetTester tester, String label) async {
  if (NativeControl.available) {
    final tabs = tester.widget<NativeControl>(
      find.byWidgetPredicate(
        (w) => w is NativeControl && w.configuration['kind'] == 'tabs',
      ),
    );
    final items = tabs.configuration['items'] as List;
    final item = items.cast<Map>().singleWhere(
      (item) => item['label'] == label,
    );
    tabs.onSelect(item['id'] as String);
  } else {
    await tester.tap(find.byTooltip(label));
  }
  await tester.pumpAndSettle();
}

Future<void> chooseMenu(WidgetTester tester, String menu, String label) async {
  final menuFinder = find.byWidgetPredicate(
    (w) => w is ActionMenu && w.label == menu,
  );
  await tester.ensureVisible(menuFinder);
  await tester.pumpAndSettle();
  if (NativeControl.available) {
    final control = tester.widget<ActionMenu>(
      find.byWidgetPredicate((w) => w is ActionMenu && w.label == menu),
    );
    control.choices.singleWhere((choice) => choice.label == label).onSelected();
  } else {
    await tester.tap(menuFinder);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(label).last);
    await tester.tap(find.text(label).last);
  }
  await tester.pumpAndSettle();
}
