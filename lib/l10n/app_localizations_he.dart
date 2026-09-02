// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'רדיו אינטרנט';

  @override
  String get tabIsrael => 'ישראל';

  @override
  String get tabFavorites => 'מועדפים';

  @override
  String get tabWorld => 'עולם';

  @override
  String get settingsTooltip => 'הגדרות';

  @override
  String get dismissTooltip => 'סגור';

  @override
  String get emptyIsraelStations => 'לא הוגדרו תחנות ישראליות.';

  @override
  String get emptyFavorites => 'לחצו על הלב ליד תחנה כדי לשמור אותה כאן.';

  @override
  String get emptyWorldStations => 'לא הוגדרו תחנות מהעולם.';

  @override
  String get notificationsBlocked =>
      'ההתראות חסומות, ולכן הנגן לא יופיע במסך הנעילה או באזור ההתראות.';

  @override
  String get notNow => 'לא עכשיו';

  @override
  String get openSettings => 'פתחו הגדרות';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get autoPlayLastStation => 'ניגון אוטומטי של התחנה האחרונה';

  @override
  String get autoPlayLastStationHint =>
      'כשמופעל, באפליקציה תתחיל התחנה שנוגנה בפעם הקודמת.';

  @override
  String autoPlayWillStartWith(String station) {
    return 'בפתיחה הבאה תתחיל עם $station.';
  }

  @override
  String get streamBuffer => 'גודל מאגר';

  @override
  String get bufferLow => 'נמוך';

  @override
  String get bufferNormal => 'רגיל';

  @override
  String get bufferHigh => 'גבוה';

  @override
  String get bufferLowDescription =>
      'התחלה מהירה יותר, עלולים להיות תקיעות ברשת חלשה.';

  @override
  String get bufferNormalDescription => 'איזון בין זמן התחלה ליציבות.';

  @override
  String get bufferHighDescription =>
      'יציב יותר בנתונים סלולריים, מתחיל לאט יותר.';

  @override
  String get refreshStreamCache => 'רענון מטמון השידורים';

  @override
  String get streamCacheEmpty =>
      'עדיין אין שידורים במטמון. כתובת השידור נשמרת אחרי הניגון הראשון ומחפשים מחדש רק אם היא לא מצליחה להתחיל.';

  @override
  String streamCacheCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שידורים במטמון. נקו אותם כדי לחפש הכול מחדש.',
      one: 'שידור אחד במטמון. נקו אותו כדי לחפש הכול מחדש.',
    );
    return '$_temp0';
  }

  @override
  String get streamCacheCleared =>
      'מטמון השידורים נוקה. השידורים ייטענו מחדש בניגון הבא.';

  @override
  String get aboutTitle => 'אודות';

  @override
  String aboutBody(String version) {
    return 'אפליקציית רדיו אינטרנט.\nגרסה $version\nפותח על ידי Noam Ran';
  }

  @override
  String get nowPlayingTitle => 'מתנגן כעת';

  @override
  String get nothingPlaying => 'כרגע לא מתנגן כלום.';

  @override
  String get addFavorite => 'הוספה למועדפים';

  @override
  String get removeFavorite => 'הסרה מהמועדפים';

  @override
  String get play => 'נגן';

  @override
  String get pause => 'השהה';

  @override
  String get stop => 'עצור';

  @override
  String get refreshStream => 'רענון שידור';

  @override
  String get quality => 'איכות';

  @override
  String get homepage => 'אתר הבית';

  @override
  String get onAir => 'בשידור';

  @override
  String copied(String label) {
    return '$label הועתק';
  }

  @override
  String get stateStopped => 'עצור';

  @override
  String get stateConnecting => 'מתחבר';

  @override
  String get stateBuffering => 'טוען';

  @override
  String get statePlaying => 'מתנגן';

  @override
  String get statePaused => 'מושהה';

  @override
  String get stateEnded => 'הסתיים';

  @override
  String get stateError => 'שגיאה';

  @override
  String get connectingEllipsis => 'מתחבר…';

  @override
  String get live => 'חי';

  @override
  String get playbackStoppedUnexpectedly => 'הניגון נעצר באופן בלתי צפוי.';

  @override
  String playbackOfStationStopped(String station) {
    return 'הניגון של $station נעצר באופן בלתי צפוי.';
  }

  @override
  String noStreamFound(String station) {
    return 'לא נמצא שידור עבור $station. בדקו את החיבור ונסו שוב.';
  }

  @override
  String get streamFailedRefreshing => 'השידור נכשל. מרענן מ־Radio Browser…';

  @override
  String get updatedStreamSaved => 'שידור מעודכן נשמר.';

  @override
  String couldNotPlayStation(String station) {
    return 'לא ניתן לנגן את $station. ייתכן שהשידור אינו זמין.';
  }

  @override
  String get refreshingStream => 'מרענן שידור מ־Radio Browser…';

  @override
  String get streamRefreshed => 'השידור רוענן.';

  @override
  String get couldNotPlayRefreshedStream => 'לא ניתן לנגן את השידור המעודכן.';

  @override
  String couldNotRefreshStation(String station) {
    return 'לא ניתן לרענן את השידור של $station.';
  }

  @override
  String get couldNotResumePlayback => 'לא ניתן להמשיך בניגון.';
}
