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
  String get imsak => 'Imsak';

  @override
  String get dhuha => 'Dhuha';

  @override
  String get lastThirdOfNight => 'Last third of night';

  @override
  String get imsakDescription =>
      '10-minute reminder before Fajr. Fasting begins at Fajr.';

  @override
  String get sunriseDescription => 'End of Fajr time.';

  @override
  String get dhuhaDescription => 'Estimated start: 20 minutes after sunrise.';

  @override
  String get lastThirdOfNightDescription =>
      'For tahajud before this day’s Fajr, using the previous sunset.';

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
  String get locationGuideApple =>
      'System Settings → Privacy & Security → Location Services → bedug → Allow';

  @override
  String get locationGuideAndroid =>
      'Settings → Apps → bedug → Permissions → Location → Allow';

  @override
  String get locationModeAuto => 'Auto-detect location';

  @override
  String get locationModeAutoDescOn => 'Using device GPS';

  @override
  String get locationModeAutoDescOff => 'Use manual city';

  @override
  String get city => 'City';

  @override
  String get selectCity => 'Select city';

  @override
  String get locationServiceDisabled =>
      'Location service is disabled. Please enable it in System Settings.';

  @override
  String get locationServiceDisabledApple =>
      'Location service is disabled. Please enable it in System Settings.';

  @override
  String get locationServiceDisabledAndroid =>
      'Location service is disabled. Please enable Location (GPS) in Android Settings.';

  @override
  String get locationPermissionDenied => 'Location permission denied.';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission permanently denied.\nOpen System Settings → Privacy & Security → Location Services → bedug → Allow, then try again.';

  @override
  String get locationPermissionDeniedForeverApple =>
      'Location permission permanently denied.\nOpen System Settings → Privacy & Security → Location Services → bedug → Allow, then try again.';

  @override
  String get locationPermissionDeniedForeverAndroid =>
      'Location permission permanently denied.\nOpen Settings → Apps → bedug → Permissions → Location → Allow, then try again.';

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
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

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

  @override
  String get worship => 'Worship';

  @override
  String get qibla => 'Qibla';

  @override
  String qiblaBearing(String degrees, String direction) {
    return '$degrees° from north ($direction)';
  }

  @override
  String qiblaDistance(String km) {
    return '$km km to the Kaaba';
  }

  @override
  String get qiblaFaceNorthHint =>
      'Point the top of the screen north, then follow the arrow.';

  @override
  String get qiblaFindNorthHint =>
      'Find north with a phone compass, a map app, or the sun.';

  @override
  String get qiblaRotateHint =>
      'Turn the device until the arrow points straight up.';

  @override
  String get qiblaFacing => 'You are facing the Qibla';

  @override
  String get qiblaCalibrate =>
      'Compass accuracy is low. Move the device in a figure 8.';

  @override
  String qiblaSunLeft(String degrees) {
    return 'The Qibla is $degrees° to the left of the sun.';
  }

  @override
  String qiblaSunRight(String degrees) {
    return 'The Qibla is $degrees° to the right of the sun.';
  }

  @override
  String get qiblaSunAhead => 'The Qibla is toward the sun.';

  @override
  String get qiblaSunBehind => 'The Qibla is directly away from the sun.';

  @override
  String get qiblaNoLocation =>
      'Location isn\'t available yet. Set it in Settings.';

  @override
  String get dirN => 'north';

  @override
  String get dirNE => 'northeast';

  @override
  String get dirE => 'east';

  @override
  String get dirSE => 'southeast';

  @override
  String get dirS => 'south';

  @override
  String get dirSW => 'southwest';

  @override
  String get dirW => 'west';

  @override
  String get dirNW => 'northwest';

  @override
  String get whatsNew => 'What\'s New';

  @override
  String get whatsNewSubtitle => 'Changes in each version';

  @override
  String get changelogUnreleased => 'Not released yet';

  @override
  String get changelogNew => 'New';

  @override
  String get changelogImproved => 'Improved';

  @override
  String get changelogFixed => 'Fixed';

  @override
  String get changelogLoadError => 'The changelog couldn\'t be loaded.';

  @override
  String get countryIndonesia => 'Indonesia';

  @override
  String get countryMalaysia => 'Malaysia';

  @override
  String get countrySingapore => 'Singapore';

  @override
  String get countryBrunei => 'Brunei';

  @override
  String get countryThailand => 'Thailand';

  @override
  String get countryPhilippines => 'Philippines';

  @override
  String get countrySaudiArabia => 'Saudi Arabia';

  @override
  String get countryUnitedArabEmirates => 'United Arab Emirates';

  @override
  String get countryQatar => 'Qatar';

  @override
  String get countryKuwait => 'Kuwait';

  @override
  String get countryBahrain => 'Bahrain';

  @override
  String get countryOman => 'Oman';

  @override
  String get countryJordan => 'Jordan';

  @override
  String get countryPalestine => 'Palestine';

  @override
  String get countryEgypt => 'Egypt';

  @override
  String get countryMorocco => 'Morocco';

  @override
  String get countryTurkey => 'Türkiye';

  @override
  String get countryPakistan => 'Pakistan';

  @override
  String get countryIndia => 'India';

  @override
  String get countryBangladesh => 'Bangladesh';

  @override
  String get countryUnitedKingdom => 'United Kingdom';

  @override
  String get countryFrance => 'France';

  @override
  String get countryGermany => 'Germany';

  @override
  String get countryNetherlands => 'Netherlands';

  @override
  String get countryUnitedStates => 'United States';

  @override
  String get countryCanada => 'Canada';

  @override
  String get countryAustralia => 'Australia';

  @override
  String get countryJapan => 'Japan';

  @override
  String get countrySouthKorea => 'South Korea';

  @override
  String get countryNigeria => 'Nigeria';

  @override
  String get countrySouthAfrica => 'South Africa';

  @override
  String get searchCity => 'Search city or country';

  @override
  String get noCityFound => 'No matching city';

  @override
  String get cityAutoDetectHint => 'Turn off auto-detect to pick a city';

  @override
  String get sheetHandle => 'Sheet handle';

  @override
  String get sheetExpand => 'Expand sheet';

  @override
  String get sheetCollapse => 'Collapse sheet';

  @override
  String get sheetDismiss => 'Dismiss sheet';

  @override
  String get sheetPreview => 'Preview';

  @override
  String get sheetCollapsed => 'Collapsed';

  @override
  String get sheetExpanded => 'Expanded';

  @override
  String get sheetFullScreen => 'Full screen';

  @override
  String get notificationPreferences => 'Reminders and sound';

  @override
  String get notificationsOff => 'Notifications off';

  @override
  String get beforePrayerReminder => 'Reminder before prayer';

  @override
  String get reminderOff => 'Off';

  @override
  String minutesBeforePrayer(int minutes) {
    return '$minutes minutes before';
  }

  @override
  String get notificationSound => 'Notification sound';

  @override
  String get systemNotificationSound => 'System sound';

  @override
  String get silentNotificationSound => 'Silent';

  @override
  String prayerReminderBody(String prayer, int minutes) {
    return '$prayer in $minutes minutes';
  }

  @override
  String get silentPrayerChannel => 'Prayer Times (silent)';

  @override
  String get notificationDeliveryInfo =>
      'Alerts are scheduled for the next six days and refreshed when you open the app. Delivery and sound follow system permissions and settings. Silent mode also disables vibration.';

  @override
  String get notificationPlatformUnavailable =>
      'Scheduled notifications are available on Android, iOS and macOS. Your preferences are still saved on this device.';

  @override
  String get notificationSchedulingError =>
      'Alerts could not be scheduled. Check system notification settings, then try changing the reminder settings again.';

  @override
  String get notificationSystemSettings => 'System notification settings';

  @override
  String get precisePrayerAlerts => 'Allow precise alerts';

  @override
  String get precisePrayerAlertsDescription =>
      'Android may delay alerts without exact alarm permission.';
}
