enum SmartPauses { off, normal, strong }

class ReaderSettings {
  ReaderSettings({
    int wpm = 300,
    this.pauses = SmartPauses.normal,
    this.highlight = true,
    double fontSize = 42,
  }) : wpm = wpm.clamp(100, 1500),
       fontSize = fontSize.clamp(24, 72);
  final int wpm;
  final SmartPauses pauses;
  final bool highlight;
  final double fontSize;
  ReaderSettings copyWith({
    int? wpm,
    SmartPauses? pauses,
    bool? highlight,
    double? fontSize,
  }) => ReaderSettings(
    wpm: wpm ?? this.wpm,
    pauses: pauses ?? this.pauses,
    highlight: highlight ?? this.highlight,
    fontSize: fontSize ?? this.fontSize,
  );
  Map<String, Object> toJson() => {
    'wpm': wpm,
    'pauses': pauses.name,
    'highlight': highlight,
    'fontSize': fontSize,
  };
  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
    wpm: json['wpm'] is int ? json['wpm'] as int : 300,
    pauses: SmartPauses.values.firstWhere(
      (p) => p.name == json['pauses'],
      orElse: () => SmartPauses.normal,
    ),
    highlight: json['highlight'] is bool ? json['highlight'] as bool : true,
    fontSize: json['fontSize'] is num && (json['fontSize'] as num).isFinite
        ? (json['fontSize'] as num).toDouble()
        : 42,
  );
}
