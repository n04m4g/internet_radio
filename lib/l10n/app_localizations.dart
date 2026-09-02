import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Internet Radio'**
  String get appTitle;

  /// No description provided for @tabIsrael.
  ///
  /// In en, this message translates to:
  /// **'Israel'**
  String get tabIsrael;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @tabWorld.
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get tabWorld;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @dismissTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissTooltip;

  /// No description provided for @emptyIsraelStations.
  ///
  /// In en, this message translates to:
  /// **'No Israel stations configured.'**
  String get emptyIsraelStations;

  /// No description provided for @emptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a station to save it here.'**
  String get emptyFavorites;

  /// No description provided for @emptyWorldStations.
  ///
  /// In en, this message translates to:
  /// **'No world stations configured.'**
  String get emptyWorldStations;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked, so the player will not show up on the lock screen or in the notification area.'**
  String get notificationsBlocked;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @autoPlayLastStation.
  ///
  /// In en, this message translates to:
  /// **'Auto-play last station'**
  String get autoPlayLastStation;

  /// No description provided for @autoPlayLastStationHint.
  ///
  /// In en, this message translates to:
  /// **'When enabled, start the station you played last time the app opened.'**
  String get autoPlayLastStationHint;

  /// No description provided for @autoPlayWillStartWith.
  ///
  /// In en, this message translates to:
  /// **'Will start with {station} next launch.'**
  String autoPlayWillStartWith(String station);

  /// No description provided for @streamBuffer.
  ///
  /// In en, this message translates to:
  /// **'Stream buffer'**
  String get streamBuffer;

  /// No description provided for @bufferLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get bufferLow;

  /// No description provided for @bufferNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bufferNormal;

  /// No description provided for @bufferHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get bufferHigh;

  /// No description provided for @bufferLowDescription.
  ///
  /// In en, this message translates to:
  /// **'Faster start, may stutter on weak networks.'**
  String get bufferLowDescription;

  /// No description provided for @bufferNormalDescription.
  ///
  /// In en, this message translates to:
  /// **'Balanced startup time and stability.'**
  String get bufferNormalDescription;

  /// No description provided for @bufferHighDescription.
  ///
  /// In en, this message translates to:
  /// **'More stable on mobile data, slower to start.'**
  String get bufferHighDescription;

  /// No description provided for @refreshStreamCache.
  ///
  /// In en, this message translates to:
  /// **'Refresh stream cache'**
  String get refreshStreamCache;

  /// No description provided for @streamCacheEmpty.
  ///
  /// In en, this message translates to:
  /// **'No streams cached yet. A stream URL is kept after first play and looked up again only if it fails to start.'**
  String get streamCacheEmpty;

  /// No description provided for @streamCacheCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stream cached. Clear it to look everything up again.} other{{count} streams cached. Clear them to look everything up again.}}'**
  String streamCacheCount(int count);

  /// No description provided for @streamCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Stream cache cleared. Streams reload on next play.'**
  String get streamCacheCleared;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'An internet radio app.\nVersion {version}\nDeveloped by Noam Ran'**
  String aboutBody(String version);

  /// No description provided for @nowPlayingTitle.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlayingTitle;

  /// No description provided for @nothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing is playing right now.'**
  String get nothingPlaying;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add favorite'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get removeFavorite;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @refreshStream.
  ///
  /// In en, this message translates to:
  /// **'Refresh stream'**
  String get refreshStream;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @homepage.
  ///
  /// In en, this message translates to:
  /// **'Homepage'**
  String get homepage;

  /// No description provided for @onAir.
  ///
  /// In en, this message translates to:
  /// **'On air'**
  String get onAir;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String copied(String label);

  /// No description provided for @stateStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stateStopped;

  /// No description provided for @stateConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get stateConnecting;

  /// No description provided for @stateBuffering.
  ///
  /// In en, this message translates to:
  /// **'Buffering'**
  String get stateBuffering;

  /// No description provided for @statePlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get statePlaying;

  /// No description provided for @statePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statePaused;

  /// No description provided for @stateEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get stateEnded;

  /// No description provided for @stateError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get stateError;

  /// No description provided for @connectingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectingEllipsis;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @playbackStoppedUnexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Playback stopped unexpectedly.'**
  String get playbackStoppedUnexpectedly;

  /// No description provided for @playbackOfStationStopped.
  ///
  /// In en, this message translates to:
  /// **'Playback of {station} stopped unexpectedly.'**
  String playbackOfStationStopped(String station);

  /// No description provided for @noStreamFound.
  ///
  /// In en, this message translates to:
  /// **'No stream found for {station}. Check your connection and try again.'**
  String noStreamFound(String station);

  /// No description provided for @streamFailedRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Stream failed. Refreshing from Radio Browser…'**
  String get streamFailedRefreshing;

  /// No description provided for @updatedStreamSaved.
  ///
  /// In en, this message translates to:
  /// **'Updated stream saved.'**
  String get updatedStreamSaved;

  /// No description provided for @couldNotPlayStation.
  ///
  /// In en, this message translates to:
  /// **'Could not play {station}. The stream may be offline.'**
  String couldNotPlayStation(String station);

  /// No description provided for @refreshingStream.
  ///
  /// In en, this message translates to:
  /// **'Refreshing stream from Radio Browser…'**
  String get refreshingStream;

  /// No description provided for @streamRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Stream refreshed.'**
  String get streamRefreshed;

  /// No description provided for @couldNotPlayRefreshedStream.
  ///
  /// In en, this message translates to:
  /// **'Could not play the refreshed stream.'**
  String get couldNotPlayRefreshedStream;

  /// No description provided for @couldNotRefreshStation.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the stream for {station}.'**
  String couldNotRefreshStation(String station);

  /// No description provided for @couldNotResumePlayback.
  ///
  /// In en, this message translates to:
  /// **'Could not resume playback.'**
  String get couldNotResumePlayback;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
