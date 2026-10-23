// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Bedug';

  @override
  String get appTagline =>
      'Pengingat salat, seperti bedug di kampung halamanmu.';

  @override
  String get prayerTimes => 'Waktu Salat';

  @override
  String get hijriCalendar => 'Kalender Hijriyah';

  @override
  String get settings => 'Pengaturan';

  @override
  String get hijriAfterMaghrib => 'Setelah Magrib';

  @override
  String get nextPrayer => 'Salat Berikutnya';

  @override
  String get upNext => 'Selanjutnya';

  @override
  String get recommended => 'Rekomendasi';

  @override
  String get fajr => 'Subuh';

  @override
  String get sunrise => 'Terbit';

  @override
  String get imsak => 'Imsak';

  @override
  String get dhuha => 'Duha';

  @override
  String get lastThirdOfNight => 'Sepertiga malam terakhir';

  @override
  String get imsakDescription =>
      'Pengingat 10 menit sebelum Subuh. Puasa dimulai saat Subuh.';

  @override
  String get sunriseDescription => 'Akhir waktu Subuh.';

  @override
  String get dhuhaDescription => 'Perkiraan awal: 20 menit setelah terbit.';

  @override
  String get lastThirdOfNightDescription =>
      'Untuk tahajud sebelum Subuh hari ini, dihitung dari Magrib sebelumnya.';

  @override
  String get dhuhr => 'Zuhur';

  @override
  String get asr => 'Asar';

  @override
  String get maghrib => 'Magrib';

  @override
  String get isha => 'Isya';

  @override
  String get calculationMethod => 'Metode Hisab';

  @override
  String get calculationMethodDesc => 'Pilih metode perhitungan waktu salat';

  @override
  String get methodKemenag => 'Kementerian Agama RI';

  @override
  String get methodMWL => 'Muslim World League';

  @override
  String get methodISNA => 'ISNA (Amerika Utara)';

  @override
  String get methodEgyptian => 'Otoritas Mesir';

  @override
  String get methodUmmAlQura => 'Umm Al-Qura (Arab Saudi)';

  @override
  String get methodKarachi => 'Universitas Karachi';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodSingapore => 'Singapura';

  @override
  String get methodTurkey => 'Turki';

  @override
  String get madhab => 'Mazhab';

  @override
  String get madhabShafi => 'Syafi\'i';

  @override
  String get madhabHanafi => 'Hanafi';

  @override
  String get azanNotifications => 'Notifikasi Azan';

  @override
  String get allPrayers => 'Semua Salat';

  @override
  String get theme => 'Tampilan';

  @override
  String get themeSystem => 'Ikuti Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get language => 'Bahasa';

  @override
  String get widgetStyle => 'Gaya Widget';

  @override
  String get widgetCompact => 'Ringkas';

  @override
  String get about => 'Tentang Aplikasi';

  @override
  String version(Object version) {
    return 'Versi $version';
  }

  @override
  String get locationError => 'Gagal mendapatkan lokasi. Pastikan GPS aktif.';

  @override
  String get locationGuide =>
      'System Settings → Privacy & Security → Location Services → bedug → Allow';

  @override
  String get locationGuideApple =>
      'System Settings → Privacy & Security → Location Services → bedug → Allow';

  @override
  String get locationGuideAndroid =>
      'Setelan → Aplikasi → bedug → Izin → Lokasi → Izinkan';

  @override
  String get locationModeAuto => 'Deteksi lokasi otomatis';

  @override
  String get locationModeAutoDescOn => 'Menggunakan GPS perangkat';

  @override
  String get locationModeAutoDescOff => 'Gunakan kota manual';

  @override
  String get city => 'Kota';

  @override
  String get selectCity => 'Pilih kota';

  @override
  String get locationServiceDisabled =>
      'Layanan lokasi tidak aktif. Aktifkan di System Settings.';

  @override
  String get locationServiceDisabledApple =>
      'Layanan lokasi tidak aktif. Aktifkan di System Settings.';

  @override
  String get locationServiceDisabledAndroid =>
      'Layanan lokasi tidak aktif. Aktifkan Lokasi (GPS) di Setelan Android.';

  @override
  String get locationPermissionDenied => 'Izin lokasi ditolak.';

  @override
  String get locationPermissionDeniedForever =>
      'Izin lokasi ditolak permanen.\nBuka System Settings → Privacy & Security → Location Services → bedug → Allow, lalu coba lagi.';

  @override
  String get locationPermissionDeniedForeverApple =>
      'Izin lokasi ditolak permanen.\nBuka System Settings → Privacy & Security → Location Services → bedug → Allow, lalu coba lagi.';

  @override
  String get locationPermissionDeniedForeverAndroid =>
      'Izin lokasi ditolak permanen.\nBuka Setelan → Aplikasi → bedug → Izin → Lokasi → Izinkan, lalu coba lagi.';

  @override
  String get notificationChannelName => 'Waktu Salat';

  @override
  String get notificationChannelDescription =>
      'Pengingat azan untuk salat harian';

  @override
  String get openAction => 'Buka';

  @override
  String get retry => 'Coba Lagi';

  @override
  String get loading => 'Memuat...';

  @override
  String get today => 'Hari Ini';

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan berikutnya';

  @override
  String get hijriToday => 'Tanggal Hijriyah Hari Ini';

  @override
  String get gregorianDate => 'Tanggal Masehi';

  @override
  String get sun => 'Min';

  @override
  String get mon => 'Sen';

  @override
  String get tue => 'Sel';

  @override
  String get wed => 'Rab';

  @override
  String get thu => 'Kam';

  @override
  String get fri => 'Jum';

  @override
  String get sat => 'Sab';

  @override
  String get muharram => 'Muharram';

  @override
  String get safar => 'Safar';

  @override
  String get rabiAlAwwal => 'Rabi\'ul Awal';

  @override
  String get rabiAlThani => 'Rabi\'ul Akhir';

  @override
  String get jumadaAlUla => 'Jumadil Awal';

  @override
  String get jumadaAlAkhirah => 'Jumadil Akhir';

  @override
  String get rajab => 'Rajab';

  @override
  String get shaban => 'Sya\'ban';

  @override
  String get ramadan => 'Ramadan';

  @override
  String get shawwal => 'Syawal';

  @override
  String get dhuAlQidah => 'Dzulqa\'dah';

  @override
  String get dhuAlHijjah => 'Dzulhijjah';

  @override
  String get notifSubuh => 'Waktu Subuh telah tiba';

  @override
  String get notifDzuhur => 'Waktu Zuhur telah tiba';

  @override
  String get notifAshar => 'Waktu Asar telah tiba';

  @override
  String get notifMaghrib => 'Waktu Magrib telah tiba';

  @override
  String get notifIsya => 'Waktu Isya telah tiba';

  @override
  String get worship => 'Ibadah';

  @override
  String get qibla => 'Kiblat';

  @override
  String qiblaBearing(String degrees, String direction) {
    return '$degrees° dari utara ($direction)';
  }

  @override
  String qiblaDistance(String km) {
    return '$km km ke Ka\'bah';
  }

  @override
  String get qiblaFaceNorthHint =>
      'Hadapkan bagian atas layar ke utara, lalu ikuti panah.';

  @override
  String get qiblaFindNorthHint =>
      'Cari arah utara dengan kompas di ponsel, aplikasi peta, atau posisi matahari.';

  @override
  String get qiblaRotateHint =>
      'Putar perangkat sampai panah menunjuk lurus ke atas.';

  @override
  String get qiblaFacing => 'Anda menghadap kiblat';

  @override
  String get qiblaCalibrate =>
      'Kompas kurang akurat. Gerakkan perangkat membentuk angka 8.';

  @override
  String qiblaSunLeft(String degrees) {
    return 'Kiblat $degrees° di sebelah kiri matahari.';
  }

  @override
  String qiblaSunRight(String degrees) {
    return 'Kiblat $degrees° di sebelah kanan matahari.';
  }

  @override
  String get qiblaSunAhead => 'Kiblat searah dengan matahari.';

  @override
  String get qiblaSunBehind => 'Kiblat tepat membelakangi matahari.';

  @override
  String get qiblaNoLocation =>
      'Lokasi belum tersedia. Atur lokasi di Pengaturan.';

  @override
  String get dirN => 'utara';

  @override
  String get dirNE => 'timur laut';

  @override
  String get dirE => 'timur';

  @override
  String get dirSE => 'tenggara';

  @override
  String get dirS => 'selatan';

  @override
  String get dirSW => 'barat daya';

  @override
  String get dirW => 'barat';

  @override
  String get dirNW => 'barat laut';

  @override
  String get whatsNew => 'Yang Baru';

  @override
  String get whatsNewSubtitle => 'Perubahan di setiap versi';

  @override
  String get changelogUnreleased => 'Belum dirilis';

  @override
  String get changelogNew => 'Baru';

  @override
  String get changelogImproved => 'Ditingkatkan';

  @override
  String get changelogFixed => 'Diperbaiki';

  @override
  String get changelogLoadError => 'Daftar perubahan tidak dapat dimuat.';

  @override
  String get countryIndonesia => 'Indonesia';

  @override
  String get countryMalaysia => 'Malaysia';

  @override
  String get countrySingapore => 'Singapura';

  @override
  String get countryBrunei => 'Brunei Darussalam';

  @override
  String get countryThailand => 'Thailand';

  @override
  String get countryPhilippines => 'Filipina';

  @override
  String get countrySaudiArabia => 'Arab Saudi';

  @override
  String get countryUnitedArabEmirates => 'Uni Emirat Arab';

  @override
  String get countryQatar => 'Qatar';

  @override
  String get countryKuwait => 'Kuwait';

  @override
  String get countryBahrain => 'Bahrain';

  @override
  String get countryOman => 'Oman';

  @override
  String get countryJordan => 'Yordania';

  @override
  String get countryPalestine => 'Palestina';

  @override
  String get countryEgypt => 'Mesir';

  @override
  String get countryMorocco => 'Maroko';

  @override
  String get countryTurkey => 'Turki';

  @override
  String get countryPakistan => 'Pakistan';

  @override
  String get countryIndia => 'India';

  @override
  String get countryBangladesh => 'Bangladesh';

  @override
  String get countryUnitedKingdom => 'Britania Raya';

  @override
  String get countryFrance => 'Prancis';

  @override
  String get countryGermany => 'Jerman';

  @override
  String get countryNetherlands => 'Belanda';

  @override
  String get countryUnitedStates => 'Amerika Serikat';

  @override
  String get countryCanada => 'Kanada';

  @override
  String get countryAustralia => 'Australia';

  @override
  String get countryJapan => 'Jepang';

  @override
  String get countrySouthKorea => 'Korea Selatan';

  @override
  String get countryNigeria => 'Nigeria';

  @override
  String get countrySouthAfrica => 'Afrika Selatan';

  @override
  String get searchCity => 'Cari kota atau negara';

  @override
  String get noCityFound => 'Kota tidak ditemukan';

  @override
  String get cityAutoDetectHint =>
      'Matikan deteksi otomatis untuk memilih kota';

  @override
  String get sheetHandle => 'Pegangan panel';

  @override
  String get sheetExpand => 'Perluas panel';

  @override
  String get sheetCollapse => 'Ciutkan panel';

  @override
  String get sheetDismiss => 'Tutup panel';

  @override
  String get sheetPreview => 'Pratinjau';

  @override
  String get sheetCollapsed => 'Diciutkan';

  @override
  String get sheetExpanded => 'Diperluas';

  @override
  String get sheetFullScreen => 'Layar penuh';

  @override
  String get notificationPreferences => 'Pengaturan pengingat dan suara';

  @override
  String get notificationsOff => 'Notifikasi nonaktif';

  @override
  String get beforePrayerReminder => 'Pengingat sebelum azan';

  @override
  String get reminderOff => 'Nonaktif';

  @override
  String minutesBeforePrayer(int minutes) {
    return '$minutes menit sebelumnya';
  }

  @override
  String get notificationSound => 'Suara notifikasi';

  @override
  String get systemNotificationSound => 'Suara sistem';

  @override
  String get silentNotificationSound => 'Senyap';

  @override
  String prayerReminderBody(String prayer, int minutes) {
    return '$prayer dalam $minutes menit';
  }

  @override
  String get silentPrayerChannel => 'Waktu Salat (senyap)';

  @override
  String get notificationDeliveryInfo =>
      'Pengingat dijadwalkan untuk enam hari ke depan dan diperbarui saat aplikasi dibuka. Pengiriman dan suara mengikuti izin serta pengaturan sistem. Mode senyap juga menonaktifkan getaran.';

  @override
  String get notificationPlatformUnavailable =>
      'Notifikasi terjadwal tersedia di Android, iOS, dan macOS. Preferensi Anda tetap tersimpan di perangkat ini.';

  @override
  String get notificationSchedulingError =>
      'Pengingat belum dapat dijadwalkan. Periksa pengaturan notifikasi sistem, lalu coba ubah pengaturan pengingat lagi.';

  @override
  String get notificationSystemSettings => 'Pengaturan notifikasi sistem';

  @override
  String get precisePrayerAlerts => 'Izinkan pengingat tepat waktu';

  @override
  String get precisePrayerAlertsDescription =>
      'Tanpa izin alarm tepat waktu, Android dapat menunda pengingat.';

  @override
  String get widgetRefresh => 'Buka Bedug untuk memperbarui jadwal salat';

  @override
  String get widgetAnalogCountdown => 'Hitung mundur analog';

  @override
  String get widgetAnalogDescription =>
      'Tampilkan penghitung waktu melingkar di samping hitung mundur digital.';

  @override
  String get widgetSchedule => 'Waktu salat berikutnya';

  @override
  String get widgetScheduleDescription =>
      'Tampilkan lima salat berikutnya pada widget iPhone sedang dan besar serta widget Android lebar.';

  @override
  String get widgetAppearanceHelp =>
      'Berlaku untuk widget layar utama iPhone dan Android. Pilih atau ubah ukuran widget di layar utama.';

  @override
  String get widgetPreview => 'Pratinjau';

  @override
  String get widgetPreviewHelp =>
      'Waktu contoh menunjukkan tata letak. Tampilan widget asli mungkin sedikit berbeda. Perubahan disimpan otomatis.';

  @override
  String get widgetSmall => 'Kecil';

  @override
  String get widgetMedium => 'Sedang / lebar';

  @override
  String get widgetLarge => 'Besar';

  @override
  String get widgetAnalogAndDigital => 'Analog + digital';

  @override
  String get widgetDigitalOnly => 'Digital saja';

  @override
  String get widgetPreviewCountdown => '01:30:00';
}
