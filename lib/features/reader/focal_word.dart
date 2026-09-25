import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design.dart';
import '../../core/document.dart';
import '../../core/settings.dart';

/// Uses the shaped glyph selection box, preserving kerning and grapheme offsets.
class FocalLayout {
  FocalLayout(
    ReaderToken token,
    TextStyle style,
    Color focal,
    bool highlight,
    double width,
    TextScaler scaler,
  ) {
    final glyphs = token.text.characters.toList();
    final index = token.focalIndex;
    final prefix = glyphs.take(index).join();
    final character = glyphs[index];
    painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: character,
            style: highlight
                ? TextStyle(
                    color: focal,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: focal,
                    decorationThickness: 1.5,
                  )
                : null,
          ),
          TextSpan(text: glyphs.skip(index + 1).join()),
        ],
      ),
    )..layout();
    final boxes = painter.getBoxesForSelection(
      TextSelection(
        baseOffset: prefix.length,
        extentOffset: prefix.length + character.length,
      ),
    );
    focalCenter = boxes.isEmpty
        ? painter.width / 2
        : (boxes.first.left + boxes.first.right) / 2;
    final anchor = width * Measures.anchor;
    scale = math
        .min(
          1.0,
          math.min(
            (anchor - 16) / math.max(1, focalCenter),
            (width - anchor - 16) / math.max(1, painter.width - focalCenter),
          ),
        )
        .clamp(0.01, 1.0);
    left = anchor - focalCenter * scale;
  }
  late final TextPainter painter;
  late final double focalCenter, scale, left;
  void dispose() => painter.dispose();
}

class FocalWord extends StatelessWidget {
  const FocalWord({
    super.key,
    required this.token,
    required this.fontSize,
    required this.readingFont,
    required this.highlight,
  });
  final ReaderToken token;
  final double fontSize;
  final ReadingFont readingFont;
  final bool highlight;
  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    return Semantics(
      label: token.text,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WordPainter(
            token,
            DefaultTextStyle.of(context).style.copyWith(
              fontSize: fontSize,
              fontFamily: readingFont.family,
              fontFamilyFallback: ReaderTypography.readingFallbacks(
                Localizations.localeOf(context).languageCode,
              ),
              fontWeight: FontWeight.w500,
              color: colors.text,
              height: 1.3,
            ),
            colors.focal,
            highlight,
            MediaQuery.textScalerOf(context),
          ),
          size: Size(
            double.infinity,
            math.max(
              180,
              MediaQuery.textScalerOf(context).scale(fontSize) * 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _WordPainter extends CustomPainter {
  _WordPainter(this.token, this.style, this.color, this.highlight, this.scaler);
  final ReaderToken token;
  final TextStyle style;
  final Color color;
  final bool highlight;
  final TextScaler scaler;
  @override
  void paint(Canvas canvas, Size size) {
    final layout = FocalLayout(
      token,
      style,
      color,
      highlight,
      size.width,
      scaler,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(
      layout.left,
      (size.height - layout.painter.height * layout.scale) / 2,
    );
    canvas.scale(layout.scale);
    layout.painter.paint(canvas, Offset.zero);
    canvas.restore();
    layout.dispose();
  }

  @override
  bool shouldRepaint(_WordPainter old) =>
      old.token != token ||
      old.style != style ||
      old.color != color ||
      old.highlight != highlight ||
      old.scaler != scaler;
}
