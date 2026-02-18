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
      'Pengingat sholat, seperti bedug di kampung halamanmu.';

  @override
  String get prayerTimes => 'Waktu Sholat';

  @override
  String get hijriCalendar => 'Kalender Hijriyah';

  @override
  String get settings => 'Pengaturan';

  @override
  String get nextPrayer => 'Sholat Berikutnya';

  @override
  String get upNext => 'Selanjutnya';

  @override
  String get recommended => 'Rekomendasi';

  @override
  String get fajr => 'Subuh';

  @override
  String get sunrise => 'Terbit';

  @override
  String get dhuhr => 'Dzuhur';

  @override
  String get asr => 'Ashar';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isya';

  @override
  String get calculationMethod => 'Metode Hisab';

  @override
  String get calculationMethodDesc => 'Pilih metode perhitungan waktu sholat';

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
  String get allPrayers => 'Semua Sholat';

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
  String get locationModeAuto => 'Deteksi lokasi otomatis';

  @override
  String get locationModeAutoDescOn => 'Menggunakan GPS perangkat';

  @override
  String get locationModeAutoDescOff => 'Gunakan kota manual';

  @override
  String get city => 'Kota';

  @override
  String get cityRequiredHint =>
      'Wajib dipilih jika deteksi otomatis dimatikan';

  @override
  String get selectCity => 'Pilih kota';

  @override
  String get cityRequiredError => 'Pilih kota terlebih dahulu di Pengaturan.';

  @override
  String get locationServiceDisabled =>
      'Layanan lokasi tidak aktif. Aktifkan di System Settings.';

  @override
  String get locationPermissionDenied => 'Izin lokasi ditolak.';

  @override
  String get locationPermissionDeniedForever =>
      'Izin lokasi ditolak permanen.\nBuka System Settings → Privacy & Security → Location Services → bedug → Allow, lalu coba lagi.';

  @override
  String get notificationChannelName => 'Waktu Sholat';

  @override
  String get notificationChannelDescription =>
      'Pengingat azan untuk sholat harian';

  @override
  String get openAction => 'Buka';

  @override
  String get retry => 'Coba Lagi';

  @override
  String get loading => 'Memuat...';

  @override
  String get today => 'Hari Ini';

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
  String get notifDzuhur => 'Waktu Dzuhur telah tiba';

  @override
  String get notifAshar => 'Waktu Ashar telah tiba';

  @override
  String get notifMaghrib => 'Waktu Maghrib telah tiba';

  @override
  String get notifIsya => 'Waktu Isya telah tiba';
}
