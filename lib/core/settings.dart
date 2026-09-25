enum Appearance { system, light, dark }

enum SmartPauses { off, normal, strong }

class ReaderSettings {
  ReaderSettings({
    int wpm = 300,
    this.pauses = SmartPauses.normal,
    this.highlight = true,
    this.appearance = Appearance.system,
    this.reduceTransparency = false,
    this.shareUsage = false,
    int imageSeconds = 5,
    double fontSize = 42,
  }) : wpm = wpm.clamp(100, 1500),
       imageSeconds = imageSeconds.clamp(1, 60),
       fontSize = fontSize.clamp(24, 72);
  final int wpm;
  final SmartPauses pauses;
  final bool highlight;
  final Appearance appearance;
  final bool reduceTransparency;
  final bool shareUsage;
  final int imageSeconds;
  final double fontSize;
  ReaderSettings copyWith({
    int? wpm,
    SmartPauses? pauses,
    bool? highlight,
    Appearance? appearance,
    bool? reduceTransparency,
    bool? shareUsage,
    int? imageSeconds,
    double? fontSize,
  }) => ReaderSettings(
    wpm: wpm ?? this.wpm,
    pauses: pauses ?? this.pauses,
    highlight: highlight ?? this.highlight,
    appearance: appearance ?? this.appearance,
    reduceTransparency: reduceTransparency ?? this.reduceTransparency,
    shareUsage: shareUsage ?? this.shareUsage,
    imageSeconds: imageSeconds ?? this.imageSeconds,
    fontSize: fontSize ?? this.fontSize,
  );
  Map<String, Object> toJson() => {
    'wpm': wpm,
    'pauses': pauses.name,
    'highlight': highlight,
    'appearance': appearance.name,
    'reduceTransparency': reduceTransparency,
    'shareUsage': shareUsage,
    'imageSeconds': imageSeconds,
    'fontSize': fontSize,
  };
  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
    appearance: Appearance.values.firstWhere(
      (v) => v.name == json['appearance'],
      orElse: () => Appearance.system,
    ),
    reduceTransparency: json['reduceTransparency'] == true,
    shareUsage: json['shareUsage'] == true,
    imageSeconds: json['imageSeconds'] is int ? json['imageSeconds'] as int : 5,
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
