enum Appearance { system, light, dark }

enum SmartPauses { off, normal, strong }

enum AppLanguage { system, en, ru, es, pt, zh, ja, pl, de, fr, it }

/// Stable stored IDs and bundled family names for the reading field only.
enum ReadingFont {
  ibmPlexSans('IBM Plex Sans', 'IBMPlexSans'),
  newsreader('Newsreader', 'Newsreader'),
  inter('Inter', 'Inter'),
  roboto('Roboto', 'Roboto'),
  openSans('Open Sans', 'OpenSans'),
  montserrat('Montserrat', 'Montserrat'),
  nunitoSans('Nunito Sans', 'NunitoSans'),
  merriweather('Merriweather', 'Merriweather'),
  sourceSans3('Source Sans 3', 'SourceSans3'),
  notoSans('Noto Sans', 'NotoSans');

  const ReadingFont(this.family, this.assetStem);
  final String family;
  final String assetStem;
}

class ReaderSettings {
  ReaderSettings({
    int wpm = 300,
    this.pauses = SmartPauses.normal,
    this.highlight = true,
    this.appearance = Appearance.system,
    this.language = AppLanguage.system,
    this.readingFont = ReadingFont.ibmPlexSans,
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
  final AppLanguage language;
  final ReadingFont readingFont;
  final bool reduceTransparency;
  final bool shareUsage;
  final int imageSeconds;
  final double fontSize;
  ReaderSettings copyWith({
    int? wpm,
    SmartPauses? pauses,
    bool? highlight,
    Appearance? appearance,
    AppLanguage? language,
    ReadingFont? readingFont,
    bool? reduceTransparency,
    bool? shareUsage,
    int? imageSeconds,
    double? fontSize,
  }) => ReaderSettings(
    wpm: wpm ?? this.wpm,
    pauses: pauses ?? this.pauses,
    highlight: highlight ?? this.highlight,
    appearance: appearance ?? this.appearance,
    language: language ?? this.language,
    readingFont: readingFont ?? this.readingFont,
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
    'language': language.name,
    'readingFont': readingFont.name,
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
    language: AppLanguage.values.firstWhere(
      (v) => v.name == json['language'],
      orElse: () => AppLanguage.system,
    ),
    readingFont: ReadingFont.values.firstWhere(
      (v) => v.name == json['readingFont'],
      orElse: () => ReadingFont.ibmPlexSans,
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
