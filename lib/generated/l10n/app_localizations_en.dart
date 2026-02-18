// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Bedug';

  @override
  String get appTagline =>
      'Your prayer reminder, rooted in Nusantara tradition.';

  @override
  String get prayerTimes => 'Prayer Times';

  @override
  String get hijriCalendar => 'Hijri Calendar';

  @override
  String get settings => 'Settings';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get upNext => 'Up next';

  @override
  String get recommended => 'Recommended';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get calculationMethod => 'Calculation Method';

  @override
  String get calculationMethodDesc => 'Choose prayer time calculation method';

  @override
  String get methodKemenag => 'Ministry of Religious Affairs (Indonesia)';

  @override
  String get methodMWL => 'Muslim World League';

  @override
  String get methodISNA => 'ISNA (North America)';

  @override
  String get methodEgyptian => 'Egyptian General Authority';

  @override
  String get methodUmmAlQura => 'Umm Al-Qura (Saudi Arabia)';

  @override
  String get methodKarachi => 'University of Karachi';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodSingapore => 'Singapore';

  @override
  String get methodTurkey => 'Turkey';

  @override
  String get madhab => 'Madhab';

  @override
  String get madhabShafi => 'Shafi\'i';

  @override
  String get madhabHanafi => 'Hanafi';

  @override
  String get azanNotifications => 'Azan Notifications';

  @override
  String get allPrayers => 'All Prayers';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get widgetStyle => 'Widget Style';

  @override
  String get widgetCompact => 'Compact';

  @override
  String get about => 'About';

  @override
  String version(Object version) {
    return 'Version $version';
  }

  @override
  String get locationError => 'Failed to get location. Please enable GPS.';

  @override
  String get locationGuide =>
      'System Settings → Privacy & Security → Location Services → bedug → Allow';

  @override
  String get locationModeAuto => 'Auto-detect location';

  @override
  String get locationModeAutoDescOn => 'Using device GPS';

  @override
  String get locationModeAutoDescOff => 'Use manual city';

  @override
  String get city => 'City';

  @override
  String get cityRequiredHint => 'Required when auto-detect is turned off';

  @override
  String get selectCity => 'Select city';

  @override
  String get cityRequiredError => 'Please select a city first in Settings.';

  @override
  String get locationServiceDisabled =>
      'Location service is disabled. Please enable it in System Settings.';

  @override
  String get locationPermissionDenied => 'Location permission denied.';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission permanently denied.\nOpen System Settings → Privacy & Security → Location Services → bedug → Allow, then try again.';

  @override
  String get notificationChannelName => 'Prayer Times';

  @override
  String get notificationChannelDescription =>
      'Azan reminders for daily prayers';

  @override
  String get openAction => 'Open';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get today => 'Today';

  @override
  String get hijriToday => 'Today\'s Hijri Date';

  @override
  String get gregorianDate => 'Gregorian Date';

  @override
  String get sun => 'Sun';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get muharram => 'Muharram';

  @override
  String get safar => 'Safar';

  @override
  String get rabiAlAwwal => 'Rabi\' al-Awwal';

  @override
  String get rabiAlThani => 'Rabi\' al-Thani';

  @override
  String get jumadaAlUla => 'Jumada al-Ula';

  @override
  String get jumadaAlAkhirah => 'Jumada al-Akhirah';

  @override
  String get rajab => 'Rajab';

  @override
  String get shaban => 'Sha\'ban';

  @override
  String get ramadan => 'Ramadan';

  @override
  String get shawwal => 'Shawwal';

  @override
  String get dhuAlQidah => 'Dhu al-Qi\'dah';

  @override
  String get dhuAlHijjah => 'Dhu al-Hijjah';

  @override
  String get notifSubuh => 'Fajr prayer time has arrived';

  @override
  String get notifDzuhur => 'Dhuhr prayer time has arrived';

  @override
  String get notifAshar => 'Asr prayer time has arrived';

  @override
  String get notifMaghrib => 'Maghrib prayer time has arrived';

  @override
  String get notifIsya => 'Isha prayer time has arrived';
}
