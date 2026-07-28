import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Resolves [AppLocalizations] for the current (or given) locale, falling back
/// to English when the device language is not one we ship.
AppLocalizations appL10n([Locale? locale]) {
  final preferred = locale ?? PlatformDispatcher.instance.locale;
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == preferred.languageCode) {
      return lookupAppLocalizations(supported);
    }
  }
  return lookupAppLocalizations(const Locale('en'));
}
