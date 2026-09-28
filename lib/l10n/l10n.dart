import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';
import '../core/settings.dart';

const appLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension AccentLabels on AppLocalizations {
  String accentName(AccentColor value) => switch (value) {
    AccentColor.vermilion => accentVermilion,
    AccentColor.terracotta => accentTerracotta,
    AccentColor.rose => accentRose,
    AccentColor.plum => accentPlum,
    AccentColor.indigo => accentIndigo,
    AccentColor.blue => accentBlue,
    AccentColor.teal => accentTeal,
    AccentColor.forest => accentForest,
    AccentColor.olive => accentOlive,
    AccentColor.ochre => accentOchre,
  };
}
