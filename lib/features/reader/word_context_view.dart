import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/design.dart';
import '../../core/document.dart';
import '../../core/settings.dart';
import '../../l10n/l10n.dart';
import 'focal_word.dart';

/// Paused reading: surrounding prose stays visible while each scroll step
/// selects a single word. The playback surface remains a separate focal view.
class WordContextView extends StatefulWidget {
  const WordContextView({
    super.key,
    required this.document,
    required this.position,
    required this.fontSize,
    required this.readingFont,
    required this.highlight,
    required this.height,
    this.image,
    required this.onTap,
    required this.onStep,
    required this.onScrollStart,
    required this.onScrollEnd,
  });

  final ReaderDocument document;
  final int position;
  final double fontSize;
  final ReadingFont readingFont;
  final bool highlight;
  final double height;
  final Widget? image;
  final VoidCallback onTap;
  final ValueChanged<int> onStep;
  final VoidCallback onScrollStart;
  final VoidCallback onScrollEnd;

  @override
  State<WordContextView> createState() => _WordContextViewState();
}

class _WordContextViewState extends State<WordContextView> {
  static const _dragStep = 36.0;
  static const _wheelStep = 48.0;
  double _dragRemainder = 0;
  double _wheelRemainder = 0;

  void _drag(double upwardPixels) {
    _dragRemainder += upwardPixels;
    final steps = (_dragRemainder / _dragStep).truncate();
    if (steps == 0) return;
    _dragRemainder -= steps * _dragStep;
    widget.onStep(steps);
  }

  void _endDrag() {
    if (_dragRemainder.abs() >= _dragStep / 2) {
      widget.onStep(_dragRemainder.sign.toInt());
    }
    _dragRemainder = 0;
    widget.onScrollEnd();
  }

  void _wheel(double downPixels) {
    if (downPixels.abs() >= _wheelStep) {
      _wheelRemainder = 0;
      widget.onStep(downPixels.sign.toInt());
      return;
    }
    _wheelRemainder += downPixels;
    if (_wheelRemainder.abs() >= _wheelStep) {
      widget.onStep(_wheelRemainder.sign.toInt());
      _wheelRemainder = 0;
    }
  }

  String _excerpt(List<ReaderToken> tokens, int start, int end, String image) {
    final result = StringBuffer();
    for (var i = start; i < end; i++) {
      if (i > start) result.write(tokens[i - 1].paragraphEnd ? '\n\n' : ' ');
      result.write(tokens[i].isImage ? image : tokens[i].text);
    }
    return result.toString();
  }

  bool _fits(
    String text,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
    double width,
    int lines,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: lines,
    )..layout(maxWidth: width);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }

  String _before(
    List<ReaderToken> tokens,
    int position,
    String image,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
    double width,
    int lines,
  ) {
    var first = math.max(0, position - 32);
    var last = position;
    var best = position;
    while (first <= last) {
      final middle = (first + last) ~/ 2;
      final text = _excerpt(tokens, middle, position, image);
      if (_fits(text, style, scaler, direction, width, lines)) {
        best = middle;
        last = middle - 1;
      } else {
        first = middle + 1;
      }
    }
    return _excerpt(tokens, math.min(best, position - 1), position, image);
  }

  String _after(
    List<ReaderToken> tokens,
    int position,
    String image,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
    double width,
    int lines,
  ) {
    var first = position + 1;
    var last = math.min(tokens.length, position + 33);
    var best = first;
    while (first <= last) {
      final middle = (first + last) ~/ 2;
      final text = _excerpt(tokens, position + 1, middle, image);
      if (_fits(text, style, scaler, direction, width, lines)) {
        best = middle;
        first = middle + 1;
      } else {
        last = middle - 1;
      }
    }
    return _excerpt(
      tokens,
      position + 1,
      math.max(best, position + 2).clamp(0, tokens.length),
      image,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.document.tokens;
    if (tokens.isEmpty) return const SizedBox.shrink();
    final position = widget.position.clamp(0, tokens.length - 1);
    final active = tokens[position];
    final colors = ReaderColors.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final contextSize = scaler.scale(16);
    final contextStyle =
        ReaderTypography.body(color: colors.secondary, size: 16).copyWith(
          fontFamily: widget.readingFont.family,
          fontFamilyFallback: ReaderTypography.readingFallbacks(
            Localizations.localeOf(context).languageCode,
          ),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        // The reader owns the viewport; word gestures must never resize or
        // scroll its chrome. Unbounded tutorial canvases retain their height.
        final panelHeight = constraints.constrainHeight(widget.height);
        final compact = panelHeight < 260;
        final gap = compact ? 8.0 : 14.0;
        final desiredActiveHeight = math.max(
          compact ? 72.0 : 100.0,
          scaler.scale(widget.fontSize) * 1.6,
        );
        final lineHeight = contextSize * 1.4;
        final contextLines =
            ((panelHeight - desiredActiveHeight - gap * 2) / (lineHeight * 2))
                .floor()
                .clamp(0, compact ? 1 : 3);
        final activeHeight = contextLines == 0
            ? math.min(panelHeight, desiredActiveHeight)
            : math.min(
                desiredActiveHeight,
                panelHeight - lineHeight * contextLines * 2 - gap * 2,
              );
        final direction = Directionality.of(context);
        final before = contextLines > 0 && position > 0
            ? _before(
                tokens,
                position,
                context.l10n.image,
                contextStyle,
                scaler,
                direction,
                constraints.maxWidth,
                contextLines,
              )
            : '';
        final after = contextLines > 0 && position < tokens.length - 1
            ? _after(
                tokens,
                position,
                context.l10n.image,
                contextStyle,
                scaler,
                direction,
                constraints.maxWidth,
                contextLines,
              )
            : '';
        return Semantics(
          key: const ValueKey('word-context-semantics'),
          container: true,
          label: context.l10n.positionOfWords(position + 1, tokens.length),
          value: active.isImage ? context.l10n.image : active.text,
          increasedValue: position < tokens.length - 1
              ? (tokens[position + 1].isImage
                    ? context.l10n.image
                    : tokens[position + 1].text)
              : null,
          decreasedValue: position > 0
              ? (tokens[position - 1].isImage
                    ? context.l10n.image
                    : tokens[position - 1].text)
              : null,
          onIncrease: position < tokens.length - 1
              ? () => widget.onStep(1)
              : null,
          onDecrease: position > 0 ? () => widget.onStep(-1) : null,
          onScrollUp: position < tokens.length - 1
              ? () => widget.onStep(1)
              : null,
          onScrollDown: position > 0 ? () => widget.onStep(-1) : null,
          onTap: widget.onTap,
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                GestureBinding.instance.pointerSignalResolver.register(
                  event,
                  (resolved) =>
                      _wheel((resolved as PointerScrollEvent).scrollDelta.dy),
                );
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: widget.onTap,
              onVerticalDragStart: (_) {
                _dragRemainder = 0;
                widget.onScrollStart();
              },
              onVerticalDragUpdate: (details) => _drag(-details.delta.dy),
              onVerticalDragEnd: (_) => _endDrag(),
              onVerticalDragCancel: _endDrag,
              child: SizedBox(
                height: panelHeight,
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          before,
                          maxLines: math.max(1, contextLines),
                          overflow: TextOverflow.ellipsis,
                          style: contextStyle,
                        ),
                      ),
                    ),
                    SizedBox(height: contextLines > 0 ? gap : 0),
                    SizedBox(
                      height: activeHeight,
                      width: double.infinity,
                      child: active.isImage
                          ? widget.image ??
                                Center(child: Text(context.l10n.image))
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: desiredActiveHeight,
                                child: FocalWord(
                                  token: active,
                                  fontSize: widget.fontSize,
                                  readingFont: widget.readingFont,
                                  highlight: widget.highlight,
                                  minimumHeight: desiredActiveHeight,
                                ),
                              ),
                            ),
                    ),
                    SizedBox(height: contextLines > 0 ? gap : 0),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          after,
                          maxLines: math.max(1, contextLines),
                          overflow: TextOverflow.ellipsis,
                          style: contextStyle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
