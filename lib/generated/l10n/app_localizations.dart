import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ms.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('id'),
    Locale('ms')
  ];

  /// Application name
  ///
  /// In id, this message translates to:
  /// **'Bedug'**
  String get appName;

  /// App tagline shown on splash/about screen
  ///
  /// In id, this message translates to:
  /// **'Pengingat sholat, seperti bedug di kampung halamanmu.'**
  String get appTagline;

  /// Prayer times screen title
  ///
  /// In id, this message translates to:
  /// **'Waktu Sholat'**
  String get prayerTimes;

  /// Hijri calendar screen title
  ///
  /// In id, this message translates to:
  /// **'Kalender Hijriyah'**
  String get hijriCalendar;

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @nextPrayer.
  ///
  /// In id, this message translates to:
  /// **'Sholat Berikutnya'**
  String get nextPrayer;

  /// No description provided for @upNext.
  ///
  /// In id, this message translates to:
  /// **'Selanjutnya'**
  String get upNext;

  /// No description provided for @recommended.
  ///
  /// In id, this message translates to:
  /// **'Rekomendasi'**
  String get recommended;

  /// Fajr prayer name in Indonesian
  ///
  /// In id, this message translates to:
  /// **'Subuh'**
  String get fajr;

  /// No description provided for @sunrise.
  ///
  /// In id, this message translates to:
  /// **'Terbit'**
  String get sunrise;

  /// No description provided for @dhuhr.
  ///
  /// In id, this message translates to:
  /// **'Dzuhur'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In id, this message translates to:
  /// **'Ashar'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In id, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In id, this message translates to:
  /// **'Isya'**
  String get isha;

  /// No description provided for @calculationMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode Hisab'**
  String get calculationMethod;

  /// No description provided for @calculationMethodDesc.
  ///
  /// In id, this message translates to:
  /// **'Pilih metode perhitungan waktu sholat'**
  String get calculationMethodDesc;

  /// No description provided for @methodKemenag.
  ///
  /// In id, this message translates to:
  /// **'Kementerian Agama RI'**
  String get methodKemenag;

  /// No description provided for @methodMWL.
  ///
  /// In id, this message translates to:
  /// **'Muslim World League'**
  String get methodMWL;

  /// No description provided for @methodISNA.
  ///
  /// In id, this message translates to:
  /// **'ISNA (Amerika Utara)'**
  String get methodISNA;

  /// No description provided for @methodEgyptian.
  ///
  /// In id, this message translates to:
  /// **'Otoritas Mesir'**
  String get methodEgyptian;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In id, this message translates to:
  /// **'Umm Al-Qura (Arab Saudi)'**
  String get methodUmmAlQura;

  /// No description provided for @methodKarachi.
  ///
  /// In id, this message translates to:
  /// **'Universitas Karachi'**
  String get methodKarachi;

  /// No description provided for @methodKuwait.
  ///
  /// In id, this message translates to:
  /// **'Kuwait'**
  String get methodKuwait;

  /// No description provided for @methodQatar.
  ///
  /// In id, this message translates to:
  /// **'Qatar'**
  String get methodQatar;

  /// No description provided for @methodSingapore.
  ///
  /// In id, this message translates to:
  /// **'Singapura'**
  String get methodSingapore;

  /// No description provided for @methodTurkey.
  ///
  /// In id, this message translates to:
  /// **'Turki'**
  String get methodTurkey;

  /// No description provided for @madhab.
  ///
  /// In id, this message translates to:
  /// **'Mazhab'**
  String get madhab;

  /// No description provided for @madhabShafi.
  ///
  /// In id, this message translates to:
  /// **'Syafi\'i'**
  String get madhabShafi;

  /// No description provided for @madhabHanafi.
  ///
  /// In id, this message translates to:
  /// **'Hanafi'**
  String get madhabHanafi;

  /// No description provided for @azanNotifications.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi Azan'**
  String get azanNotifications;

  /// No description provided for @allPrayers.
  ///
  /// In id, this message translates to:
  /// **'Semua Sholat'**
  String get allPrayers;

  /// No description provided for @theme.
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti Sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get language;

  /// No description provided for @widgetStyle.
  ///
  /// In id, this message translates to:
  /// **'Gaya Widget'**
  String get widgetStyle;

  /// No description provided for @widgetCompact.
  ///
  /// In id, this message translates to:
  /// **'Ringkas'**
  String get widgetCompact;

  /// No description provided for @about.
  ///
  /// In id, this message translates to:
  /// **'Tentang Aplikasi'**
  String get about;

  /// No description provided for @version.
  ///
  /// In id, this message translates to:
  /// **'Versi {version}'**
  String version(Object version);

  /// No description provided for @locationError.
  ///
  /// In id, this message translates to:
  /// **'Gagal mendapatkan lokasi. Pastikan GPS aktif.'**
  String get locationError;

  /// No description provided for @locationGuide.
  ///
  /// In id, this message translates to:
  /// **'System Settings → Privacy & Security → Location Services → bedug → Allow'**
  String get locationGuide;

  /// No description provided for @retry.
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In id, this message translates to:
  /// **'Memuat...'**
  String get loading;

  /// No description provided for @today.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get today;

  /// No description provided for @hijriToday.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Hijriyah Hari Ini'**
  String get hijriToday;

  /// No description provided for @gregorianDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Masehi'**
  String get gregorianDate;

  /// No description provided for @sun.
  ///
  /// In id, this message translates to:
  /// **'Min'**
  String get sun;

  /// No description provided for @mon.
  ///
  /// In id, this message translates to:
  /// **'Sen'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In id, this message translates to:
  /// **'Sel'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In id, this message translates to:
  /// **'Rab'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In id, this message translates to:
  /// **'Kam'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In id, this message translates to:
  /// **'Jum'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In id, this message translates to:
  /// **'Sab'**
  String get sat;

  /// No description provided for @muharram.
  ///
  /// In id, this message translates to:
  /// **'Muharram'**
  String get muharram;

  /// No description provided for @safar.
  ///
  /// In id, this message translates to:
  /// **'Safar'**
  String get safar;

  /// No description provided for @rabiAlAwwal.
  ///
  /// In id, this message translates to:
  /// **'Rabi\'ul Awal'**
  String get rabiAlAwwal;

  /// No description provided for @rabiAlThani.
  ///
  /// In id, this message translates to:
  /// **'Rabi\'ul Akhir'**
  String get rabiAlThani;

  /// No description provided for @jumadaAlUla.
  ///
  /// In id, this message translates to:
  /// **'Jumadil Awal'**
  String get jumadaAlUla;

  /// No description provided for @jumadaAlAkhirah.
  ///
  /// In id, this message translates to:
  /// **'Jumadil Akhir'**
  String get jumadaAlAkhirah;

  /// No description provided for @rajab.
  ///
  /// In id, this message translates to:
  /// **'Rajab'**
  String get rajab;

  /// No description provided for @shaban.
  ///
  /// In id, this message translates to:
  /// **'Sya\'ban'**
  String get shaban;

  /// No description provided for @ramadan.
  ///
  /// In id, this message translates to:
  /// **'Ramadan'**
  String get ramadan;

  /// No description provided for @shawwal.
  ///
  /// In id, this message translates to:
  /// **'Syawal'**
  String get shawwal;

  /// No description provided for @dhuAlQidah.
  ///
  /// In id, this message translates to:
  /// **'Dzulqa\'dah'**
  String get dhuAlQidah;

  /// No description provided for @dhuAlHijjah.
  ///
  /// In id, this message translates to:
  /// **'Dzulhijjah'**
  String get dhuAlHijjah;

  /// No description provided for @notifSubuh.
  ///
  /// In id, this message translates to:
  /// **'Waktu Subuh telah tiba'**
  String get notifSubuh;

  /// No description provided for @notifDzuhur.
  ///
  /// In id, this message translates to:
  /// **'Waktu Dzuhur telah tiba'**
  String get notifDzuhur;

  /// No description provided for @notifAshar.
  ///
  /// In id, this message translates to:
  /// **'Waktu Ashar telah tiba'**
  String get notifAshar;

  /// No description provided for @notifMaghrib.
  ///
  /// In id, this message translates to:
  /// **'Waktu Maghrib telah tiba'**
  String get notifMaghrib;

  /// No description provided for @notifIsya.
  ///
  /// In id, this message translates to:
  /// **'Waktu Isya telah tiba'**
  String get notifIsya;
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
      <String>['ar', 'en', 'id', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
