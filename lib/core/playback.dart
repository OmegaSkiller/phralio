import 'dart:async';
import 'dart:math' as math;

import 'package:characters/characters.dart';

import 'document.dart';
import 'settings.dart';

class TimingPolicy {
  const TimingPolicy();
  Duration duration(ReaderToken token, ReaderSettings settings) {
    if (token.isImage) return Duration(seconds: settings.imageSeconds);
    var weight = 1.0;
    if (settings.pauses != SmartPauses.off) {
      final strength = settings.pauses == SmartPauses.strong ? 1.5 : 1.0;
      var extra = token.paragraphEnd
          ? 1.0
          : token.sentenceEnd
          ? 0.7
          : RegExp(r'''[,;:，；：][”’"')\]]*$''').hasMatch(token.text)
          ? 0.35
          : 0.0;
      extra +=
          math.max(0, token.text.characters.length - 8).clamp(0, 16) * 0.04;
      if (RegExp(r'\d').hasMatch(token.text)) extra += 0.2;
      weight += extra * strength;
    }
    return Duration(microseconds: (60000000 / settings.wpm * weight).round());
  }
}

/// Pure Dart. One monotonic deadline and one cancellable timer; no widget clock.
/// Small dispatch delays are compensated. Long stalls pause rather than skip
/// unread words or burst through a backlog of deadlines.
class Playback {
  Playback(
    this.tokens, {
    required this._settings,
    int position = 0,
    Duration Function()? now,
    this.policy = const TimingPolicy(),
  }) : _position = position.clamp(0, tokens.length) {
    final stopwatch = Stopwatch()..start();
    _now = now ?? (() => stopwatch.elapsed);
    _remaining = _fullDuration;
    _rebuildEstimates();
  }
  final List<ReaderToken> tokens;
  final TimingPolicy policy;
  late final Duration Function() _now;
  final _changes = StreamController<void>.broadcast(sync: true);
  Stream<void> get changes => _changes.stream;
  ReaderSettings _settings;
  ReaderSettings get settings => _settings;
  int _position;
  int get position => _position;
  bool _playing = false;
  bool get playing => _playing;
  bool get completed => _position == tokens.length;
  ReaderToken? get current => completed ? null : tokens[_position];
  double get progress => tokens.isEmpty ? 0 : _position / tokens.length;
  Timer? _timer;
  Duration _deadline = Duration.zero;
  Duration _remaining = Duration.zero;
  Duration get _fullDuration =>
      current == null ? Duration.zero : policy.duration(current!, _settings);
  Duration get remainingTime {
    var total = _playing ? _deadline - _now() : _remaining;
    if (total.isNegative) total = Duration.zero;
    if (_position + 1 < _suffix.length) total += _suffix[_position + 1];
    return total;
  }

  late List<Duration> _suffix;
  void _rebuildEstimates() {
    _suffix = List.filled(tokens.length + 1, Duration.zero);
    for (var i = tokens.length - 1; i >= 0; i--) {
      _suffix[i] = _suffix[i + 1] + policy.duration(tokens[i], _settings);
    }
  }

  void play() {
    if (_playing || tokens.isEmpty) return;
    if (completed) {
      _position = 0;
      _remaining = _fullDuration;
    }
    _playing = true;
    _deadline = _now() + _remaining;
    _schedule();
    _emit();
  }

  void pause() {
    if (!_playing) return;
    _remaining = _deadline - _now();
    if (_remaining.isNegative) _remaining = Duration.zero;
    _playing = false;
    _timer?.cancel();
    _emit();
  }

  void seek(int target) {
    _timer?.cancel();
    _playing = false;
    _position = target.clamp(0, tokens.length);
    _remaining = _fullDuration;
    _emit();
  }

  void sentence(int direction) {
    if (tokens.isEmpty) return;
    var i = math.min(_position, tokens.length - 1);
    if (direction < 0) {
      if (i > 0) i--;
      while (i > 0 &&
          !tokens[i - 1].sentenceEnd &&
          !tokens[i - 1].paragraphEnd) {
        i--;
      }
    } else {
      while (i < tokens.length &&
          !tokens[i].sentenceEnd &&
          !tokens[i].paragraphEnd) {
        i++;
      }
      if (i < tokens.length) i++;
    }
    seek(i);
  }

  void configure(ReaderSettings value) {
    final oldDuration = _fullDuration.inMicroseconds;
    final left = (_playing ? _deadline - _now() : _remaining).inMicroseconds;
    _settings = value;
    _rebuildEstimates();
    final fraction = oldDuration == 0
        ? 1.0
        : (left / oldDuration).clamp(0.0, 1.0);
    _remaining = Duration(
      microseconds: (_fullDuration.inMicroseconds * fraction).round(),
    );
    if (_playing) {
      _deadline = _now() + _remaining;
      _schedule();
    }
    _emit();
  }

  void _schedule() {
    _timer?.cancel();
    final delay = _deadline - _now();
    _timer = Timer(delay.isNegative ? Duration.zero : delay, _tick);
  }

  void _tick() {
    if (!_playing) return;
    final lateBy = _now() - _deadline;
    if (lateBy.inMicroseconds >
        math.max(250000, _fullDuration.inMicroseconds * 2)) {
      _playing = false;
      _remaining = _fullDuration;
      _emit();
      return;
    }
    _position++;
    _remaining = _fullDuration;
    if (completed) {
      _playing = false;
    } else {
      _deadline += _remaining;
      _schedule();
    }
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void dispose() {
    _timer?.cancel();
    _playing = false;
    _changes.close();
  }
}
