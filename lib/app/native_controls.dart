import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// UIKit/AppKit own material, hit testing, accessibility and menu presentation.
/// The reading engine and navigation remain in Flutter.
class NativeControl extends StatefulWidget {
  const NativeControl({
    super.key,
    required this.configuration,
    required this.onSelect,
  });

  static bool get available =>
      !kIsWeb &&
      ((Platform.isIOS && defaultTargetPlatform == TargetPlatform.iOS) ||
          (Platform.isMacOS && defaultTargetPlatform == TargetPlatform.macOS));
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
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) {
      return UiKitView(
        viewType: 'phralio/native-control',
        layoutDirection: Directionality.of(context),
        creationParams: widget.configuration,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onCreated,
      );
    }
    // AppKitView does not yet merge its native children into Flutter's
    // accessibility tree. Supply equivalent semantic actions in Flutter while
    // AppKit continues to own pointer input and material rendering.
    final config = widget.configuration;
    final enabled = config['enabled'] != false;
    final items = (config['items'] as List?)?.cast<Map>() ?? const <Map>[];
    final semantics = config['kind'] == 'tabs'
        ? Flex(
            direction: config['vertical'] == true
                ? Axis.vertical
                : Axis.horizontal,
            children: [
              for (final item in items)
                Expanded(
                  child: Semantics(
                    container: true,
                    button: true,
                    inMutuallyExclusiveGroup: true,
                    label: item['label'] as String,
                    selected: item['id'] == config['selected'],
                    onTap: () => widget.onSelect(item['id'] as String),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          )
        : Semantics(
            container: true,
            button: true,
            enabled: enabled,
            label: config['label'] as String?,
            selected: config['selected'] as bool?,
            onTap: !enabled
                ? null
                : () {
                    if (config['kind'] == 'menu') {
                      _channel?.invokeMethod<void>('activate');
                    } else {
                      widget.onSelect('tap');
                    }
                  },
            child: const SizedBox.expand(),
          );
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              config['kind'] == 'tabs' ? 26 : 0,
            ),
            child: AppKitView(
              viewType: 'phralio/native-control',
              layoutDirection: Directionality.of(context),
              creationParams: config,
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onCreated,
            ),
          ),
        ),
        // This layer adds semantic bounds without taking pointer events.
        semantics,
      ],
    );
  }

  void _onCreated(int id) {
    if (!mounted) return;
    _channel = MethodChannel('phralio/native-control/$id')
      ..setMethodCallHandler((call) async {
        if (mounted && call.method == 'select') {
          widget.onSelect(call.arguments as String);
        }
      });
    _channel!.invokeMethod<void>('update', widget.configuration);
  }
}
