import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phralio/core/document.dart';
import 'package:phralio/core/playback.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/premium/capabilities.dart';

void main() {
  test(
    'tokens preserve Unicode, source offsets, punctuation and paragraphs',
    () {
      const source = '  “Hello,”\tе́то 👩‍💻.\n\nNext!\nline';
      final tokens = tokenize(source);
      expect(tokens.map((t) => t.text), [
        '“Hello,”',
        'е́то',
        '👩‍💻.',
        'Next!',
        'line',
      ]);
      for (final token in tokens) {
        expect(
          source.substring(token.offset, token.offset + token.text.length),
          token.text,
        );
      }
      expect(tokens[2].paragraphEnd, isTrue);
      expect(tokens[3].paragraphEnd, isFalse);
      expect(tokens[3].sentenceEnd, isTrue);
      expect(const ReaderToken('“Hello,”', 0, false).focalIndex, 2);
      expect(const ReaderToken('е́то', 0, false).focalIndex, 1);
      expect(tokenize(' \n\t'), isEmpty);
    },
  );
  test(
    'import rejects malformed/large text; normalizes without losing content',
    () {
      for (final text in ['', ' \n ', 'a\u0000b', 'x' * 200001]) {
        expect(() => TextImport.validate('', text), throwsFormatException);
      }
      final input = TextImport.validate('  title  ', ' a\r\nb\rc ');
      expect(input.title, 'title');
      expect(input.text, 'a\nb\nc');
      expect(TextImport.validate('', 'a').title, 'Untitled reading');
    },
  );
  test('timing adds punctuation, paragraph, length and numeric dwell', () {
    const policy = TimingPolicy();
    final settings = ReaderSettings(wpm: 300);
    int dwell(String word, [bool paragraph = false]) => policy
        .duration(ReaderToken(word, 0, paragraph), settings)
        .inMicroseconds;
    expect(dwell('word'), 200000);
    expect(dwell('word,'), 270000);
    expect(dwell('word;'), 270000);
    expect(dwell('word:'), 270000);
    expect(dwell('word.”'), 340000);
    expect(dwell('word.', true), 400000);
    expect(dwell('123'), 240000);
    expect(dwell('abcdefghij'), 216000);
    expect(
      policy
          .duration(
            const ReaderToken('word.', 0, true),
            settings.copyWith(pauses: SmartPauses.strong),
          )
          .inMicroseconds,
      500000,
    );
    expect(
      policy
          .duration(
            const ReaderToken('longword123.', 0, true),
            settings.copyWith(pauses: SmartPauses.off),
          )
          .inMicroseconds,
      200000,
    );
  });
  for (final wpm in [250, 400, 700, 1000, 1500]) {
    test('10,000 words at $wpm WPM have no accumulated timer drift', () {
      fakeAsync((clock) {
        final engine = Playback(
          List.generate(10000, (_) => const ReaderToken('word', 0, false)),
          settings: ReaderSettings(wpm: wpm, pauses: SmartPauses.off),
          now: () => clock.elapsed,
        );
        final dwell = (60000000 / wpm).round();
        expect(engine.remainingTime.inMicroseconds, dwell * 10000);
        engine.play();
        clock.elapse(Duration(microseconds: dwell * 10000 - 1));
        expect(engine.position, 9999);
        expect(engine.playing, isTrue);
        clock.elapse(const Duration(microseconds: 1));
        expect(engine.completed, isTrue);
        expect(engine.progress, 1);
        expect(engine.remainingTime, Duration.zero);
        expect(engine.playing, isFalse);
        engine.play();
        expect(engine.position, 0);
        engine.dispose();
        expect(clock.nonPeriodicTimerCount, 0);
      });
    });
  }
  test('pause/resume and live speed preserve fraction of current dwell', () {
    fakeAsync((clock) {
      final engine = Playback(
        tokenize('one two three'),
        settings: ReaderSettings(wpm: 300, pauses: SmartPauses.off),
        now: () => clock.elapsed,
      );
      engine.play();
      clock.elapse(const Duration(milliseconds: 50));
      engine.pause();
      clock.elapse(const Duration(seconds: 5));
      expect(engine.position, 0);
      expect(engine.remainingTime.inMilliseconds, 550);
      engine.configure(ReaderSettings(wpm: 600, pauses: SmartPauses.off));
      engine.play();
      clock.elapse(const Duration(milliseconds: 74));
      expect(engine.position, 0);
      clock.elapse(const Duration(milliseconds: 1));
      expect(engine.position, 1);
      engine.seek(2);
      expect(engine.playing, isFalse);
      expect(engine.remainingTime.inMilliseconds, 100);
      engine.dispose();
    });
  });
  test('event-loop stall pauses without silently skipping words', () {
    fakeAsync((clock) {
      var offset = Duration.zero;
      final engine = Playback(
        tokenize('one two three'),
        settings: ReaderSettings(wpm: 1500),
        now: () => clock.elapsed + offset,
      );
      engine.play();
      offset = const Duration(seconds: 3);
      clock.elapse(const Duration(milliseconds: 40));
      expect(engine.position, 0);
      expect(engine.playing, isFalse);
      engine.dispose();
    });
  });
  test('sentence navigation and restored position start paused', () {
    final engine = Playback(
      tokenize('One two. Three four! Five six.'),
      settings: ReaderSettings(),
      position: 3,
    );
    expect(engine.playing, isFalse);
    engine.sentence(-1);
    expect(engine.position, 2);
    engine.sentence(-1);
    expect(engine.position, 0);
    engine.sentence(1);
    expect(engine.position, 2);
    engine.seek(99);
    expect(engine.completed, isTrue);
    engine.dispose();
  });
  test(
    'free capabilities deny PDF; unsupported service fails explicitly',
    () async {
      expect(const ReaderCapabilities().canImportPdf, isFalse);
      expect(const ReaderCapabilities(pdf: _TestPdf()).canImportPdf, isFalse);
      expect(
        const ReaderCapabilities(
          pdf: _TestPdf(),
          entitlements: _AllEntitlements(),
        ).canImportPdf,
        isTrue,
      );
      expect(
        const FreeEntitlementService().allows(PremiumFeature.imageReader),
        isFalse,
      );
      expect(
        const ReaderCapabilities(entitlements: _AllEntitlements()).canImportPdf,
        isFalse,
      );
      await expectLater(
        const UnsupportedPdfReflowService().import([]),
        throwsUnsupportedError,
      );
    },
  );
}

class _AllEntitlements implements EntitlementService {
  const _AllEntitlements();
  @override
  bool allows(PremiumFeature feature) => true;
}

class _TestPdf implements PdfReflowService {
  const _TestPdf();
  @override
  Future<ReaderDocument> import(List<int> bytes) async =>
      ReaderDocument(id: 0, title: 'Synthetic', text: 'Test');
}
