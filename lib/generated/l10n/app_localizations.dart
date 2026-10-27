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
    Locale('ms'),
  ];

  /// Application name
  ///
  /// In id, this message translates to:
  /// **'Bedug'**
  String get appName;

  /// App tagline shown on splash/about screen
  ///
  /// In id, this message translates to:
  /// **'Pengingat salat, seperti bedug di kampung halamanmu.'**
  String get appTagline;

  /// Prayer times screen title
  ///
  /// In id, this message translates to:
  /// **'Waktu Salat'**
  String get prayerTimes;

  /// Hijri calendar screen title
  ///
  /// In id, this message translates to:
  /// **'Kalender Hijriah'**
  String get hijriCalendar;

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @hijriAfterMaghrib.
  ///
  /// In id, this message translates to:
  /// **'Setelah Magrib'**
  String get hijriAfterMaghrib;

  /// No description provided for @nextPrayer.
  ///
  /// In id, this message translates to:
  /// **'Salat Berikutnya'**
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

  /// No description provided for @prayerCategoryObligatory.
  ///
  /// In id, this message translates to:
  /// **'Salat wajib'**
  String get prayerCategoryObligatory;

  /// No description provided for @prayerCategorySunnah.
  ///
  /// In id, this message translates to:
  /// **'Salat sunnah'**
  String get prayerCategorySunnah;

  /// No description provided for @prayerCategoryOther.
  ///
  /// In id, this message translates to:
  /// **'Waktu lainnya'**
  String get prayerCategoryOther;

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

  /// No description provided for @imsak.
  ///
  /// In id, this message translates to:
  /// **'Imsak'**
  String get imsak;

  /// No description provided for @dhuha.
  ///
  /// In id, this message translates to:
  /// **'Duha'**
  String get dhuha;

  /// No description provided for @lastThirdOfNight.
  ///
  /// In id, this message translates to:
  /// **'Sepertiga malam terakhir'**
  String get lastThirdOfNight;

  /// No description provided for @imsakDescription.
  ///
  /// In id, this message translates to:
  /// **'Pengingat 10 menit sebelum Subuh. Puasa dimulai saat Subuh.'**
  String get imsakDescription;

  /// No description provided for @sunriseDescription.
  ///
  /// In id, this message translates to:
  /// **'Akhir waktu Subuh.'**
  String get sunriseDescription;

  /// No description provided for @dhuhaDescription.
  ///
  /// In id, this message translates to:
  /// **'Perkiraan awal: 20 menit setelah terbit.'**
  String get dhuhaDescription;

  /// No description provided for @lastThirdOfNightDescription.
  ///
  /// In id, this message translates to:
  /// **'Untuk tahajud sebelum Subuh hari ini, dihitung dari Magrib sebelumnya.'**
  String get lastThirdOfNightDescription;

  /// No description provided for @dhuhr.
  ///
  /// In id, this message translates to:
  /// **'Zuhur'**
  String get dhuhr;

  /// No description provided for @jumuah.
  ///
  /// In id, this message translates to:
  /// **'Jumat'**
  String get jumuah;

  /// No description provided for @jumuahDescription.
  ///
  /// In id, this message translates to:
  /// **'Waktu Zuhur. Yang tidak salat Jumat tetap salat Zuhur.'**
  String get jumuahDescription;

  /// No description provided for @asr.
  ///
  /// In id, this message translates to:
  /// **'Asar'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In id, this message translates to:
  /// **'Magrib'**
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
  /// **'Pilih metode perhitungan waktu salat'**
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

  /// No description provided for @notifications.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get notifications;

  /// No description provided for @allNotifications.
  ///
  /// In id, this message translates to:
  /// **'Semua notifikasi'**
  String get allNotifications;

  /// No description provided for @notificationTimes.
  ///
  /// In id, this message translates to:
  /// **'Waktu'**
  String get notificationTimes;

  /// No description provided for @notificationSystemSection.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get notificationSystemSection;

  /// No description provided for @allPrayers.
  ///
  /// In id, this message translates to:
  /// **'Semua Salat'**
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

  /// No description provided for @locationGuideApple.
  ///
  /// In id, this message translates to:
  /// **'System Settings → Privacy & Security → Location Services → bedug → Allow'**
  String get locationGuideApple;

  /// No description provided for @locationGuideAndroid.
  ///
  /// In id, this message translates to:
  /// **'Setelan → Aplikasi → bedug → Izin → Lokasi → Izinkan'**
  String get locationGuideAndroid;

  /// No description provided for @locationModeAuto.
  ///
  /// In id, this message translates to:
  /// **'Deteksi lokasi otomatis'**
  String get locationModeAuto;

  /// No description provided for @locationModeAutoDescOn.
  ///
  /// In id, this message translates to:
  /// **'Menggunakan GPS perangkat'**
  String get locationModeAutoDescOn;

  /// No description provided for @locationModeAutoDescOff.
  ///
  /// In id, this message translates to:
  /// **'Gunakan kota manual'**
  String get locationModeAutoDescOff;

  /// No description provided for @city.
  ///
  /// In id, this message translates to:
  /// **'Kota'**
  String get city;

  /// No description provided for @selectCity.
  ///
  /// In id, this message translates to:
  /// **'Pilih kota'**
  String get selectCity;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In id, this message translates to:
  /// **'Layanan lokasi tidak aktif. Aktifkan di System Settings.'**
  String get locationServiceDisabled;

  /// No description provided for @locationServiceDisabledApple.
  ///
  /// In id, this message translates to:
  /// **'Layanan lokasi tidak aktif. Aktifkan di System Settings.'**
  String get locationServiceDisabledApple;

  /// No description provided for @locationServiceDisabledAndroid.
  ///
  /// In id, this message translates to:
  /// **'Layanan lokasi tidak aktif. Aktifkan Lokasi (GPS) di Setelan Android.'**
  String get locationServiceDisabledAndroid;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin lokasi ditolak.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In id, this message translates to:
  /// **'Izin lokasi ditolak permanen.\nBuka System Settings → Privacy & Security → Location Services → bedug → Allow, lalu coba lagi.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationPermissionDeniedForeverApple.
  ///
  /// In id, this message translates to:
  /// **'Izin lokasi ditolak permanen.\nBuka System Settings → Privacy & Security → Location Services → bedug → Allow, lalu coba lagi.'**
  String get locationPermissionDeniedForeverApple;

  /// No description provided for @locationPermissionDeniedForeverAndroid.
  ///
  /// In id, this message translates to:
  /// **'Izin lokasi ditolak permanen.\nBuka Setelan → Aplikasi → bedug → Izin → Lokasi → Izinkan, lalu coba lagi.'**
  String get locationPermissionDeniedForeverAndroid;

  /// No description provided for @notificationChannelName.
  ///
  /// In id, this message translates to:
  /// **'Waktu Salat'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In id, this message translates to:
  /// **'Pengingat waktu salat'**
  String get notificationChannelDescription;

  /// No description provided for @openAction.
  ///
  /// In id, this message translates to:
  /// **'Buka'**
  String get openAction;

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

  /// No description provided for @previousMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan sebelumnya'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan berikutnya'**
  String get nextMonth;

  /// No description provided for @hijriToday.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Hijriah Hari Ini'**
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
  /// **'Muharam'**
  String get muharram;

  /// No description provided for @safar.
  ///
  /// In id, this message translates to:
  /// **'Safar'**
  String get safar;

  /// No description provided for @rabiAlAwwal.
  ///
  /// In id, this message translates to:
  /// **'Rabiulawal'**
  String get rabiAlAwwal;

  /// No description provided for @rabiAlThani.
  ///
  /// In id, this message translates to:
  /// **'Rabiulakhir'**
  String get rabiAlThani;

  /// No description provided for @jumadaAlUla.
  ///
  /// In id, this message translates to:
  /// **'Jumadilawal'**
  String get jumadaAlUla;

  /// No description provided for @jumadaAlAkhirah.
  ///
  /// In id, this message translates to:
  /// **'Jumadilakhir'**
  String get jumadaAlAkhirah;

  /// No description provided for @rajab.
  ///
  /// In id, this message translates to:
  /// **'Rajab'**
  String get rajab;

  /// No description provided for @shaban.
  ///
  /// In id, this message translates to:
  /// **'Syakban'**
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
  /// **'Zulkaidah'**
  String get dhuAlQidah;

  /// No description provided for @dhuAlHijjah.
  ///
  /// In id, this message translates to:
  /// **'Zulhijah'**
  String get dhuAlHijjah;

  /// No description provided for @notifSubuh.
  ///
  /// In id, this message translates to:
  /// **'Waktu Subuh telah tiba'**
  String get notifSubuh;

  /// No description provided for @notifDzuhur.
  ///
  /// In id, this message translates to:
  /// **'Waktu Zuhur telah tiba'**
  String get notifDzuhur;

  /// No description provided for @notifJumuah.
  ///
  /// In id, this message translates to:
  /// **'Waktu salat Jumat telah tiba'**
  String get notifJumuah;

  /// No description provided for @notifAshar.
  ///
  /// In id, this message translates to:
  /// **'Waktu Asar telah tiba'**
  String get notifAshar;

  /// No description provided for @notifMaghrib.
  ///
  /// In id, this message translates to:
  /// **'Waktu Magrib telah tiba'**
  String get notifMaghrib;

  /// No description provided for @notifIsya.
  ///
  /// In id, this message translates to:
  /// **'Waktu Isya telah tiba'**
  String get notifIsya;

  /// No description provided for @notifLastThirdOfNight.
  ///
  /// In id, this message translates to:
  /// **'Sepertiga malam terakhir telah tiba, waktu untuk tahajud'**
  String get notifLastThirdOfNight;

  /// No description provided for @notifImsak.
  ///
  /// In id, this message translates to:
  /// **'Imsak: Subuh {minutes} menit lagi'**
  String notifImsak(int minutes);

  /// No description provided for @notifSunrise.
  ///
  /// In id, this message translates to:
  /// **'Matahari telah terbit. Waktu Subuh telah berakhir'**
  String get notifSunrise;

  /// No description provided for @notifDhuha.
  ///
  /// In id, this message translates to:
  /// **'Waktu salat Duha telah tiba'**
  String get notifDhuha;

  /// No description provided for @worship.
  ///
  /// In id, this message translates to:
  /// **'Ibadah'**
  String get worship;

  /// No description provided for @qibla.
  ///
  /// In id, this message translates to:
  /// **'Kiblat'**
  String get qibla;

  /// No description provided for @qiblaBearing.
  ///
  /// In id, this message translates to:
  /// **'{degrees}° dari utara ({direction})'**
  String qiblaBearing(String degrees, String direction);

  /// No description provided for @qiblaDistance.
  ///
  /// In id, this message translates to:
  /// **'{km} km ke Ka\'bah'**
  String qiblaDistance(String km);

  /// No description provided for @qiblaFaceNorthHint.
  ///
  /// In id, this message translates to:
  /// **'Hadapkan bagian atas layar ke utara, lalu ikuti panah.'**
  String get qiblaFaceNorthHint;

  /// No description provided for @qiblaFindNorthHint.
  ///
  /// In id, this message translates to:
  /// **'Cari arah utara dengan kompas di ponsel, aplikasi peta, atau posisi matahari.'**
  String get qiblaFindNorthHint;

  /// No description provided for @qiblaRotateHint.
  ///
  /// In id, this message translates to:
  /// **'Putar perangkat sampai ikon Ka\'bah tepat di atas.'**
  String get qiblaRotateHint;

  /// No description provided for @qiblaFacing.
  ///
  /// In id, this message translates to:
  /// **'Anda menghadap kiblat'**
  String get qiblaFacing;

  /// No description provided for @qiblaCalibrate.
  ///
  /// In id, this message translates to:
  /// **'Kompas kurang akurat. Gerakkan perangkat membentuk angka 8.'**
  String get qiblaCalibrate;

  /// No description provided for @qiblaSunLeft.
  ///
  /// In id, this message translates to:
  /// **'Kiblat {degrees}° di sebelah kiri matahari.'**
  String qiblaSunLeft(String degrees);

  /// No description provided for @qiblaSunRight.
  ///
  /// In id, this message translates to:
  /// **'Kiblat {degrees}° di sebelah kanan matahari.'**
  String qiblaSunRight(String degrees);

  /// No description provided for @qiblaSunAhead.
  ///
  /// In id, this message translates to:
  /// **'Kiblat searah dengan matahari.'**
  String get qiblaSunAhead;

  /// No description provided for @qiblaSunBehind.
  ///
  /// In id, this message translates to:
  /// **'Kiblat tepat membelakangi matahari.'**
  String get qiblaSunBehind;

  /// No description provided for @qiblaNoLocation.
  ///
  /// In id, this message translates to:
  /// **'Lokasi belum tersedia. Atur lokasi di Pengaturan.'**
  String get qiblaNoLocation;

  /// No description provided for @dirN.
  ///
  /// In id, this message translates to:
  /// **'utara'**
  String get dirN;

  /// No description provided for @dirNE.
  ///
  /// In id, this message translates to:
  /// **'timur laut'**
  String get dirNE;

  /// No description provided for @dirE.
  ///
  /// In id, this message translates to:
  /// **'timur'**
  String get dirE;

  /// No description provided for @dirSE.
  ///
  /// In id, this message translates to:
  /// **'tenggara'**
  String get dirSE;

  /// No description provided for @dirS.
  ///
  /// In id, this message translates to:
  /// **'selatan'**
  String get dirS;

  /// No description provided for @dirSW.
  ///
  /// In id, this message translates to:
  /// **'barat daya'**
  String get dirSW;

  /// No description provided for @dirW.
  ///
  /// In id, this message translates to:
  /// **'barat'**
  String get dirW;

  /// No description provided for @dirNW.
  ///
  /// In id, this message translates to:
  /// **'barat laut'**
  String get dirNW;

  /// No description provided for @whatsNew.
  ///
  /// In id, this message translates to:
  /// **'Yang Baru'**
  String get whatsNew;

  /// No description provided for @whatsNewSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Perubahan di setiap versi'**
  String get whatsNewSubtitle;

  /// No description provided for @changelogUnreleased.
  ///
  /// In id, this message translates to:
  /// **'Belum dirilis'**
  String get changelogUnreleased;

  /// No description provided for @changelogNew.
  ///
  /// In id, this message translates to:
  /// **'Baru'**
  String get changelogNew;

  /// No description provided for @changelogImproved.
  ///
  /// In id, this message translates to:
  /// **'Ditingkatkan'**
  String get changelogImproved;

  /// No description provided for @changelogFixed.
  ///
  /// In id, this message translates to:
  /// **'Diperbaiki'**
  String get changelogFixed;

  /// No description provided for @changelogLoadError.
  ///
  /// In id, this message translates to:
  /// **'Daftar perubahan tidak dapat dimuat.'**
  String get changelogLoadError;

  /// No description provided for @countryIndonesia.
  ///
  /// In id, this message translates to:
  /// **'Indonesia'**
  String get countryIndonesia;

  /// No description provided for @countryMalaysia.
  ///
  /// In id, this message translates to:
  /// **'Malaysia'**
  String get countryMalaysia;

  /// No description provided for @countrySingapore.
  ///
  /// In id, this message translates to:
  /// **'Singapura'**
  String get countrySingapore;

  /// No description provided for @countryBrunei.
  ///
  /// In id, this message translates to:
  /// **'Brunei Darussalam'**
  String get countryBrunei;

  /// No description provided for @countryThailand.
  ///
  /// In id, this message translates to:
  /// **'Thailand'**
  String get countryThailand;

  /// No description provided for @countryPhilippines.
  ///
  /// In id, this message translates to:
  /// **'Filipina'**
  String get countryPhilippines;

  /// No description provided for @countrySaudiArabia.
  ///
  /// In id, this message translates to:
  /// **'Arab Saudi'**
  String get countrySaudiArabia;

  /// No description provided for @countryUnitedArabEmirates.
  ///
  /// In id, this message translates to:
  /// **'Uni Emirat Arab'**
  String get countryUnitedArabEmirates;

  /// No description provided for @countryQatar.
  ///
  /// In id, this message translates to:
  /// **'Qatar'**
  String get countryQatar;

  /// No description provided for @countryKuwait.
  ///
  /// In id, this message translates to:
  /// **'Kuwait'**
  String get countryKuwait;

  /// No description provided for @countryBahrain.
  ///
  /// In id, this message translates to:
  /// **'Bahrain'**
  String get countryBahrain;

  /// No description provided for @countryOman.
  ///
  /// In id, this message translates to:
  /// **'Oman'**
  String get countryOman;

  /// No description provided for @countryJordan.
  ///
  /// In id, this message translates to:
  /// **'Yordania'**
  String get countryJordan;

  /// No description provided for @countryPalestine.
  ///
  /// In id, this message translates to:
  /// **'Palestina'**
  String get countryPalestine;

  /// No description provided for @countryEgypt.
  ///
  /// In id, this message translates to:
  /// **'Mesir'**
  String get countryEgypt;

  /// No description provided for @countryMorocco.
  ///
  /// In id, this message translates to:
  /// **'Maroko'**
  String get countryMorocco;

  /// No description provided for @countryTurkey.
  ///
  /// In id, this message translates to:
  /// **'Turki'**
  String get countryTurkey;

  /// No description provided for @countryPakistan.
  ///
  /// In id, this message translates to:
  /// **'Pakistan'**
  String get countryPakistan;

  /// No description provided for @countryIndia.
  ///
  /// In id, this message translates to:
  /// **'India'**
  String get countryIndia;

  /// No description provided for @countryBangladesh.
  ///
  /// In id, this message translates to:
  /// **'Bangladesh'**
  String get countryBangladesh;

  /// No description provided for @countryUnitedKingdom.
  ///
  /// In id, this message translates to:
  /// **'Britania Raya'**
  String get countryUnitedKingdom;

  /// No description provided for @countryFrance.
  ///
  /// In id, this message translates to:
  /// **'Prancis'**
  String get countryFrance;

  /// No description provided for @countryGermany.
  ///
  /// In id, this message translates to:
  /// **'Jerman'**
  String get countryGermany;

  /// No description provided for @countryNetherlands.
  ///
  /// In id, this message translates to:
  /// **'Belanda'**
  String get countryNetherlands;

  /// No description provided for @countryUnitedStates.
  ///
  /// In id, this message translates to:
  /// **'Amerika Serikat'**
  String get countryUnitedStates;

  /// No description provided for @countryCanada.
  ///
  /// In id, this message translates to:
  /// **'Kanada'**
  String get countryCanada;

  /// No description provided for @countryAustralia.
  ///
  /// In id, this message translates to:
  /// **'Australia'**
  String get countryAustralia;

  /// No description provided for @countryJapan.
  ///
  /// In id, this message translates to:
  /// **'Jepang'**
  String get countryJapan;

  /// No description provided for @countrySouthKorea.
  ///
  /// In id, this message translates to:
  /// **'Korea Selatan'**
  String get countrySouthKorea;

  /// No description provided for @countryNigeria.
  ///
  /// In id, this message translates to:
  /// **'Nigeria'**
  String get countryNigeria;

  /// No description provided for @countrySouthAfrica.
  ///
  /// In id, this message translates to:
  /// **'Afrika Selatan'**
  String get countrySouthAfrica;

  /// No description provided for @searchCity.
  ///
  /// In id, this message translates to:
  /// **'Cari kota atau negara'**
  String get searchCity;

  /// No description provided for @noCityFound.
  ///
  /// In id, this message translates to:
  /// **'Kota tidak ditemukan'**
  String get noCityFound;

  /// No description provided for @cityAutoDetectHint.
  ///
  /// In id, this message translates to:
  /// **'Matikan deteksi otomatis untuk memilih kota'**
  String get cityAutoDetectHint;

  /// No description provided for @sheetHandle.
  ///
  /// In id, this message translates to:
  /// **'Pegangan panel'**
  String get sheetHandle;

  /// No description provided for @sheetExpand.
  ///
  /// In id, this message translates to:
  /// **'Perluas panel'**
  String get sheetExpand;

  /// No description provided for @sheetCollapse.
  ///
  /// In id, this message translates to:
  /// **'Ciutkan panel'**
  String get sheetCollapse;

  /// No description provided for @sheetDismiss.
  ///
  /// In id, this message translates to:
  /// **'Tutup panel'**
  String get sheetDismiss;

  /// No description provided for @sheetPreview.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau'**
  String get sheetPreview;

  /// No description provided for @sheetCollapsed.
  ///
  /// In id, this message translates to:
  /// **'Diciutkan'**
  String get sheetCollapsed;

  /// No description provided for @sheetExpanded.
  ///
  /// In id, this message translates to:
  /// **'Diperluas'**
  String get sheetExpanded;

  /// No description provided for @sheetFullScreen.
  ///
  /// In id, this message translates to:
  /// **'Layar penuh'**
  String get sheetFullScreen;

  /// No description provided for @notificationPreferences.
  ///
  /// In id, this message translates to:
  /// **'Pengingat'**
  String get notificationPreferences;

  /// No description provided for @notificationsOff.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi nonaktif'**
  String get notificationsOff;

  /// No description provided for @beforePrayerReminder.
  ///
  /// In id, this message translates to:
  /// **'Pengingat lebih awal'**
  String get beforePrayerReminder;

  /// No description provided for @reminderOff.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get reminderOff;

  /// No description provided for @minutesBeforePrayer.
  ///
  /// In id, this message translates to:
  /// **'{minutes} menit sebelumnya'**
  String minutesBeforePrayer(int minutes);

  /// No description provided for @notificationSound.
  ///
  /// In id, this message translates to:
  /// **'Suara'**
  String get notificationSound;

  /// No description provided for @systemNotificationSound.
  ///
  /// In id, this message translates to:
  /// **'Suara sistem'**
  String get systemNotificationSound;

  /// No description provided for @silentNotificationSound.
  ///
  /// In id, this message translates to:
  /// **'Senyap'**
  String get silentNotificationSound;

  /// No description provided for @bedugNotificationSound.
  ///
  /// In id, this message translates to:
  /// **'Bedug'**
  String get bedugNotificationSound;

  /// No description provided for @sirenNotificationSound.
  ///
  /// In id, this message translates to:
  /// **'Sirene'**
  String get sirenNotificationSound;

  /// No description provided for @phoneNotificationSound.
  ///
  /// In id, this message translates to:
  /// **'Suara ponsel…'**
  String get phoneNotificationSound;

  /// No description provided for @soundPrayerChannel.
  ///
  /// In id, this message translates to:
  /// **'Waktu Salat ({sound})'**
  String soundPrayerChannel(String sound);

  /// No description provided for @prayerReminderBody.
  ///
  /// In id, this message translates to:
  /// **'{prayer} dalam {minutes} menit'**
  String prayerReminderBody(String prayer, int minutes);

  /// No description provided for @silentPrayerChannel.
  ///
  /// In id, this message translates to:
  /// **'Waktu Salat (senyap)'**
  String get silentPrayerChannel;

  /// No description provided for @notificationDeliveryInfo.
  ///
  /// In id, this message translates to:
  /// **'Pengingat dijadwalkan hingga enam hari ke depan dan diperbarui saat aplikasi dibuka. Pengiriman dan suara mengikuti izin serta pengaturan sistem. Mode senyap juga menonaktifkan getaran.'**
  String get notificationDeliveryInfo;

  /// No description provided for @notificationPlatformUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi terjadwal tersedia di Android, iOS, dan macOS. Preferensi Anda tetap tersimpan di perangkat ini.'**
  String get notificationPlatformUnavailable;

  /// No description provided for @notificationSchedulingError.
  ///
  /// In id, this message translates to:
  /// **'Pengingat belum dapat dijadwalkan. Periksa pengaturan notifikasi sistem, lalu coba ubah pengaturan pengingat lagi.'**
  String get notificationSchedulingError;

  /// No description provided for @notificationSystemSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan notifikasi sistem'**
  String get notificationSystemSettings;

  /// No description provided for @precisePrayerAlerts.
  ///
  /// In id, this message translates to:
  /// **'Izinkan pengingat tepat waktu'**
  String get precisePrayerAlerts;

  /// No description provided for @precisePrayerAlertsDescription.
  ///
  /// In id, this message translates to:
  /// **'Tanpa izin alarm tepat waktu, Android dapat menunda pengingat.'**
  String get precisePrayerAlertsDescription;

  /// No description provided for @widgetRefresh.
  ///
  /// In id, this message translates to:
  /// **'Buka Bedug untuk memperbarui jadwal salat'**
  String get widgetRefresh;

  /// No description provided for @widgetAnalogCountdown.
  ///
  /// In id, this message translates to:
  /// **'Hitung mundur analog'**
  String get widgetAnalogCountdown;

  /// No description provided for @widgetAnalogDescription.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan penghitung waktu melingkar di samping hitung mundur digital.'**
  String get widgetAnalogDescription;

  /// No description provided for @widgetSchedule.
  ///
  /// In id, this message translates to:
  /// **'Waktu salat berikutnya'**
  String get widgetSchedule;

  /// No description provided for @widgetScheduleDescription.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan empat salat setelah salat berikutnya yang ditonjolkan pada widget iPhone sedang dan besar serta widget Android lebar.'**
  String get widgetScheduleDescription;

  /// No description provided for @widgetAppearanceHelp.
  ///
  /// In id, this message translates to:
  /// **'Berlaku untuk widget layar utama iPhone dan Android. Pilih atau ubah ukuran widget di layar utama.'**
  String get widgetAppearanceHelp;

  /// No description provided for @widgetPreview.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau'**
  String get widgetPreview;

  /// No description provided for @widgetPreviewHelp.
  ///
  /// In id, this message translates to:
  /// **'Waktu contoh menunjukkan tata letak. Tampilan widget asli mungkin sedikit berbeda. Perubahan disimpan otomatis.'**
  String get widgetPreviewHelp;

  /// No description provided for @widgetSmall.
  ///
  /// In id, this message translates to:
  /// **'Kecil'**
  String get widgetSmall;

  /// No description provided for @widgetMedium.
  ///
  /// In id, this message translates to:
  /// **'Sedang / lebar'**
  String get widgetMedium;

  /// No description provided for @widgetLarge.
  ///
  /// In id, this message translates to:
  /// **'Besar'**
  String get widgetLarge;

  /// No description provided for @widgetAnalogAndDigital.
  ///
  /// In id, this message translates to:
  /// **'Analog + digital'**
  String get widgetAnalogAndDigital;

  /// No description provided for @widgetDigitalOnly.
  ///
  /// In id, this message translates to:
  /// **'Digital saja'**
  String get widgetDigitalOnly;

  /// No description provided for @widgetPreviewCountdown.
  ///
  /// In id, this message translates to:
  /// **'01:30:00'**
  String get widgetPreviewCountdown;

  /// No description provided for @infaq.
  ///
  /// In id, this message translates to:
  /// **'Infak'**
  String get infaq;

  /// No description provided for @infaqSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Dukung pengembangan Bedug'**
  String get infaqSubtitle;

  /// No description provided for @infaqThanksSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Terima kasih atas infak Anda'**
  String get infaqThanksSubtitle;

  /// No description provided for @infaqIntro.
  ///
  /// In id, this message translates to:
  /// **'Bedug gratis. Infak Anda mendukung pengembangan Bedug dan mematikan iklan. Infak tidak disalurkan ke lembaga amal atau pihak lain.'**
  String get infaqIntro;

  /// No description provided for @infaqIntroNoAds.
  ///
  /// In id, this message translates to:
  /// **'Bedug gratis. Infak Anda mendukung pengembangan Bedug. Infak tidak disalurkan ke lembaga amal atau pihak lain.'**
  String get infaqIntroNoAds;

  /// No description provided for @infaqSmall.
  ///
  /// In id, this message translates to:
  /// **'Infak kecil'**
  String get infaqSmall;

  /// No description provided for @infaqMedium.
  ///
  /// In id, this message translates to:
  /// **'Infak sedang'**
  String get infaqMedium;

  /// No description provided for @infaqLarge.
  ///
  /// In id, this message translates to:
  /// **'Infak besar'**
  String get infaqLarge;

  /// No description provided for @infaqRestoreNote.
  ///
  /// In id, this message translates to:
  /// **'Infak Anda kembali setelah instal ulang atau di perangkat baru: ketuk Pulihkan pembelian.'**
  String get infaqRestoreNote;

  /// No description provided for @infaqRestore.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan pembelian'**
  String get infaqRestore;

  /// No description provided for @infaqThanks.
  ///
  /// In id, this message translates to:
  /// **'Terima kasih atas infak Anda. Jazakallahu khairan!'**
  String get infaqThanks;

  /// No description provided for @infaqAdsOff.
  ///
  /// In id, this message translates to:
  /// **'Iklan sudah dimatikan di perangkat ini.'**
  String get infaqAdsOff;

  /// No description provided for @infaqPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu pembayaran selesai…'**
  String get infaqPending;

  /// No description provided for @infaqUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Toko tidak dapat dijangkau. Periksa koneksi lalu coba lagi.'**
  String get infaqUnavailable;

  /// No description provided for @infaqFailed.
  ///
  /// In id, this message translates to:
  /// **'Infak tidak berhasil. Silakan coba lagi.'**
  String get infaqFailed;

  /// No description provided for @infaqRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get infaqRetry;

  /// No description provided for @infaqTrakteer.
  ///
  /// In id, this message translates to:
  /// **'Trakteer'**
  String get infaqTrakteer;

  /// No description provided for @infaqTrakteerMethods.
  ///
  /// In id, this message translates to:
  /// **'QRIS, dompet digital, dan transfer bank'**
  String get infaqTrakteerMethods;

  /// No description provided for @infaqKofi.
  ///
  /// In id, this message translates to:
  /// **'Ko-fi'**
  String get infaqKofi;

  /// No description provided for @infaqKofiMethods.
  ///
  /// In id, this message translates to:
  /// **'PayPal dan kartu'**
  String get infaqKofiMethods;

  /// No description provided for @widgetShowCurrent.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan salat saat ini'**
  String get widgetShowCurrent;

  /// No description provided for @widgetShowCurrentDescription.
  ///
  /// In id, this message translates to:
  /// **'Utamakan salat saat ini di iPhone dan iPad; hitung mundur tetap menuju salat berikutnya. Pengaturan masing-masing widget dapat menggantikan pilihan ini.'**
  String get widgetShowCurrentDescription;

  /// No description provided for @widgetNow.
  ///
  /// In id, this message translates to:
  /// **'Sekarang'**
  String get widgetNow;

  /// No description provided for @dzikir.
  ///
  /// In id, this message translates to:
  /// **'Zikir'**
  String get dzikir;

  /// No description provided for @dzikirMorning.
  ///
  /// In id, this message translates to:
  /// **'Pagi'**
  String get dzikirMorning;

  /// No description provided for @dzikirEvening.
  ///
  /// In id, this message translates to:
  /// **'Petang'**
  String get dzikirEvening;

  /// No description provided for @dzikirLoadError.
  ///
  /// In id, this message translates to:
  /// **'Zikir gagal dimuat.'**
  String get dzikirLoadError;

  /// No description provided for @dzikirSource.
  ///
  /// In id, this message translates to:
  /// **'Sumber: {source}'**
  String dzikirSource(String source);

  /// How many times to recite an item.
  ///
  /// In id, this message translates to:
  /// **'{count}×'**
  String dzikirRepeat(int count);

  /// No description provided for @dzikirProgress.
  ///
  /// In id, this message translates to:
  /// **'{count}/{total}'**
  String dzikirProgress(int count, int total);

  /// No description provided for @dzikirCounterHint.
  ///
  /// In id, this message translates to:
  /// **'Ketuk kartu untuk menghitung, tekan lama untuk mengatur ulang.'**
  String get dzikirCounterHint;

  /// No description provided for @dzikirCountAction.
  ///
  /// In id, this message translates to:
  /// **'Hitung'**
  String get dzikirCountAction;

  /// No description provided for @dzikirResetAction.
  ///
  /// In id, this message translates to:
  /// **'Atur ulang hitungan'**
  String get dzikirResetAction;

  /// No description provided for @dzikirCollection.
  ///
  /// In id, this message translates to:
  /// **'Kitab zikir'**
  String get dzikirCollection;

  /// No description provided for @afterPrayerDzikir.
  ///
  /// In id, this message translates to:
  /// **'Zikir setelah salat'**
  String get afterPrayerDzikir;

  /// No description provided for @afterPrayerDzikirSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Istigfar, tasbih, Ayat Kursi, dan lainnya'**
  String get afterPrayerDzikirSubtitle;

  /// No description provided for @duas.
  ///
  /// In id, this message translates to:
  /// **'Doa harian'**
  String get duas;

  /// No description provided for @duasSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Bangun tidur, makan, bepergian, dan lainnya'**
  String get duasSubtitle;

  /// No description provided for @duasLoadError.
  ///
  /// In id, this message translates to:
  /// **'Doa gagal dimuat.'**
  String get duasLoadError;

  /// No description provided for @asmaulHusna.
  ///
  /// In id, this message translates to:
  /// **'Asmaul Husna'**
  String get asmaulHusna;

  /// No description provided for @asmaulHusnaSubtitle.
  ///
  /// In id, this message translates to:
  /// **'99 nama Allah'**
  String get asmaulHusnaSubtitle;

  /// No description provided for @asmaulHusnaLoadError.
  ///
  /// In id, this message translates to:
  /// **'Asmaul Husna gagal dimuat.'**
  String get asmaulHusnaLoadError;

  /// No description provided for @dzikirMorningReminder.
  ///
  /// In id, this message translates to:
  /// **'Zikir pagi'**
  String get dzikirMorningReminder;

  /// No description provided for @dzikirEveningReminder.
  ///
  /// In id, this message translates to:
  /// **'Zikir petang'**
  String get dzikirEveningReminder;

  /// No description provided for @dzikirReminderAfter.
  ///
  /// In id, this message translates to:
  /// **'{minutes} menit setelah {prayer}'**
  String dzikirReminderAfter(int minutes, String prayer);

  /// No description provided for @notifDzikirMorning.
  ///
  /// In id, this message translates to:
  /// **'Saatnya membaca zikir pagi'**
  String get notifDzikirMorning;

  /// No description provided for @notifDzikirEvening.
  ///
  /// In id, this message translates to:
  /// **'Saatnya membaca zikir petang'**
  String get notifDzikirEvening;

  /// No description provided for @quran.
  ///
  /// In id, this message translates to:
  /// **'Al-Qur\'an'**
  String get quran;

  /// No description provided for @quranSurahs.
  ///
  /// In id, this message translates to:
  /// **'Surah'**
  String get quranSurahs;

  /// No description provided for @quranJuz.
  ///
  /// In id, this message translates to:
  /// **'Juz'**
  String get quranJuz;

  /// No description provided for @quranBookmarks.
  ///
  /// In id, this message translates to:
  /// **'Penanda'**
  String get quranBookmarks;

  /// No description provided for @quranLoadError.
  ///
  /// In id, this message translates to:
  /// **'Al-Qur\'an gagal dimuat.'**
  String get quranLoadError;

  /// No description provided for @quranMeccan.
  ///
  /// In id, this message translates to:
  /// **'Makkiyah'**
  String get quranMeccan;

  /// No description provided for @quranMedinan.
  ///
  /// In id, this message translates to:
  /// **'Madaniyah'**
  String get quranMedinan;

  /// No description provided for @quranAyahCount.
  ///
  /// In id, this message translates to:
  /// **'{count} ayat'**
  String quranAyahCount(int count);

  /// No description provided for @quranAyah.
  ///
  /// In id, this message translates to:
  /// **'Ayat {number}'**
  String quranAyah(int number);

  /// No description provided for @quranJuzNumber.
  ///
  /// In id, this message translates to:
  /// **'Juz {number}'**
  String quranJuzNumber(int number);

  /// No description provided for @quranContinueReading.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan membaca'**
  String get quranContinueReading;

  /// No description provided for @quranNoBookmarks.
  ///
  /// In id, this message translates to:
  /// **'Belum ada penanda. Ketuk ikon penanda pada ayat untuk menyimpannya.'**
  String get quranNoBookmarks;

  /// No description provided for @quranAddBookmark.
  ///
  /// In id, this message translates to:
  /// **'Tandai ayat'**
  String get quranAddBookmark;

  /// No description provided for @quranRemoveBookmark.
  ///
  /// In id, this message translates to:
  /// **'Hapus penanda'**
  String get quranRemoveBookmark;

  /// No description provided for @quranTextSmaller.
  ///
  /// In id, this message translates to:
  /// **'Perkecil teks'**
  String get quranTextSmaller;

  /// No description provided for @quranTextLarger.
  ///
  /// In id, this message translates to:
  /// **'Perbesar teks'**
  String get quranTextLarger;

  /// No description provided for @quranNextSurah.
  ///
  /// In id, this message translates to:
  /// **'Surah berikutnya: {name}'**
  String quranNextSurah(String name);

  /// No description provided for @dailyAyah.
  ///
  /// In id, this message translates to:
  /// **'Ayat hari ini'**
  String get dailyAyah;

  /// No description provided for @dailyAyahOpen.
  ///
  /// In id, this message translates to:
  /// **'Buka di pembaca Al-Qur\'an'**
  String get dailyAyahOpen;

  /// No description provided for @dailyAyahWidgetRefresh.
  ///
  /// In id, this message translates to:
  /// **'Buka Bedug untuk memuat ayat hari ini'**
  String get dailyAyahWidgetRefresh;

  /// No description provided for @quranReference.
  ///
  /// In id, this message translates to:
  /// **'QS. {surah} [{number}]: {ayah}'**
  String quranReference(String surah, int number, int ayah);

  /// No description provided for @khatamPlanner.
  ///
  /// In id, this message translates to:
  /// **'Target khatam'**
  String get khatamPlanner;

  /// No description provided for @khatamSetupHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih dalam berapa hari Anda ingin mengkhatamkan Al-Qur\'an.'**
  String get khatamSetupHint;

  /// No description provided for @khatamDays.
  ///
  /// In id, this message translates to:
  /// **'{count} hari'**
  String khatamDays(int count);

  /// No description provided for @khatamFinishBy.
  ///
  /// In id, this message translates to:
  /// **'Khatam pada {date}'**
  String khatamFinishBy(String date);

  /// No description provided for @khatamStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get khatamStart;

  /// No description provided for @khatamChange.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get khatamChange;

  /// No description provided for @khatamEnd.
  ///
  /// In id, this message translates to:
  /// **'Akhiri target'**
  String get khatamEnd;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @khatamTodayTarget.
  ///
  /// In id, this message translates to:
  /// **'Hari ini: baca sampai {surah} ayat {ayah}'**
  String khatamTodayTarget(String surah, int ayah);

  /// No description provided for @khatamTodayDone.
  ///
  /// In id, this message translates to:
  /// **'Bacaan hari ini selesai'**
  String get khatamTodayDone;

  /// No description provided for @khatamPercentRead.
  ///
  /// In id, this message translates to:
  /// **'{percent}% terbaca'**
  String khatamPercentRead(int percent);

  /// No description provided for @khatamDaysLeft.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =0{Tanggal target sudah lewat} other{Sisa {count} hari}}'**
  String khatamDaysLeft(int count);

  /// No description provided for @khatamComplete.
  ///
  /// In id, this message translates to:
  /// **'Khatam! Alhamdulillah.'**
  String get khatamComplete;

  /// No description provided for @khatamNewPlan.
  ///
  /// In id, this message translates to:
  /// **'Target baru'**
  String get khatamNewPlan;

  /// No description provided for @khatamMarkRead.
  ///
  /// In id, this message translates to:
  /// **'Tandai terbaca sampai sini'**
  String get khatamMarkRead;

  /// No description provided for @hijriEvents.
  ///
  /// In id, this message translates to:
  /// **'Hari besar Islam'**
  String get hijriEvents;

  /// No description provided for @hijriEventsSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Hari raya, hari besar dan ayyamul bidh setahun ke depan'**
  String get hijriEventsSubtitle;

  /// No description provided for @hijriEventsLoadError.
  ///
  /// In id, this message translates to:
  /// **'Hari besar Islam gagal dimuat.'**
  String get hijriEventsLoadError;

  /// No description provided for @hijriEventsWhen.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =0{Hari ini} =1{Besok} other{{count} hari lagi}}'**
  String hijriEventsWhen(int count);

  /// No description provided for @hijriEventsNote.
  ///
  /// In id, this message translates to:
  /// **'Tanggal mengikuti perhitungan kalender Ummul Qura dan bisa berbeda sehari dari pengumuman setempat, seperti sidang isbat.'**
  String get hijriEventsNote;

  /// No description provided for @hijriEventReminder.
  ///
  /// In id, this message translates to:
  /// **'Pengingat hari besar'**
  String get hijriEventReminder;

  /// No description provided for @hijriEventReminderSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Saat Magrib, malam sebelum hari besar dan ayyamul bidh'**
  String get hijriEventReminderSubtitle;

  /// No description provided for @notifHijriEventTomorrow.
  ///
  /// In id, this message translates to:
  /// **'Besok. Dalam kalender Hijriah, harinya dimulai malam ini.'**
  String get notifHijriEventTomorrow;
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
    'that was used.',
  );
}
