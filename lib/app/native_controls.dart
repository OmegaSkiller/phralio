import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// UIKit owns the material, hit testing, accessibility and menu presentation.
/// The reading engine and navigation remain in Flutter.
class NativeControl extends StatefulWidget {
  const NativeControl({
    super.key,
    required this.configuration,
    required this.onSelect,
  });

  static bool get available => !kIsWeb && Platform.isIOS;
  final Map<String, Object?> configuration;
  final ValueChanged<String> onSelect;

  @override
  State<NativeControl> createState() => _NativeControlState();
}

class _NativeControlState extends State<NativeControl> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(NativeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _channel?.invokeMethod<void>('update', widget.configuration);
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UiKitView(
    viewType: 'phralio/native-control',
    layoutDirection: Directionality.of(context),
    creationParams: widget.configuration,
    creationParamsCodec: const StandardMessageCodec(),
    onPlatformViewCreated: (id) {
      if (!mounted) return;
      _channel = MethodChannel('phralio/native-control/$id')
        ..setMethodCallHandler((call) async {
          if (mounted && call.method == 'select') {
            widget.onSelect(call.arguments as String);
          }
        });
      _channel!.invokeMethod<void>('update', widget.configuration);
    },
  );
}
