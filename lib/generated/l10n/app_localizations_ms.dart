// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appName => 'Bedug';

  @override
  String get appTagline => 'Peringatan solat dari tradisi Nusantara.';

  @override
  String get prayerTimes => 'Waktu Solat';

  @override
  String get hijriCalendar => 'Kalendar Hijrah';

  @override
  String get settings => 'Tetapan';

  @override
  String get nextPrayer => 'Solat Seterusnya';

  @override
  String get upNext => 'Seterusnya';

  @override
  String get recommended => 'Disyorkan';

  @override
  String get fajr => 'Subuh';

  @override
  String get sunrise => 'Syuruk';

  @override
  String get dhuhr => 'Zohor';

  @override
  String get asr => 'Asar';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isyak';

  @override
  String get calculationMethod => 'Kaedah Pengiraan';

  @override
  String get calculationMethodDesc => 'Pilih kaedah pengiraan waktu solat';

  @override
  String get methodKemenag => 'Kementerian Agama Indonesia';

  @override
  String get methodMWL => 'Persatuan Islam Sedunia';

  @override
  String get methodISNA => 'ISNA (Amerika Utara)';

  @override
  String get methodEgyptian => 'Pihak Berkuasa Am Mesir';

  @override
  String get methodUmmAlQura => 'Umm Al-Qura (Arab Saudi)';

  @override
  String get methodKarachi => 'Universiti Karachi';

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
  String get azanNotifications => 'Pemberitahuan Azan';

  @override
  String get allPrayers => 'Semua Solat';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Ikut Sistem';

  @override
  String get themeLight => 'Cerah';

  @override
  String get themeDark => 'Gelap';

  @override
  String get language => 'Bahasa';

  @override
  String get widgetStyle => 'Gaya Widget';

  @override
  String get widgetCompact => 'Padat';

  @override
  String get about => 'Tentang';

  @override
  String version(Object version) {
    return 'Versi $version';
  }

  @override
  String get locationError => 'Gagal mendapatkan lokasi. Sila aktifkan GPS.';

  @override
  String get locationGuide =>
      'System Settings → Privacy & Security → Location Services → bedug → Allow';

  @override
  String get locationModeAuto => 'Kesan lokasi automatik';

  @override
  String get locationModeAutoDescOn => 'Menggunakan GPS peranti';

  @override
  String get locationModeAutoDescOff => 'Gunakan bandar manual';

  @override
  String get city => 'Bandar';

  @override
  String get cityRequiredHint => 'Wajib dipilih jika kesan automatik dimatikan';

  @override
  String get selectCity => 'Pilih bandar';

  @override
  String get cityRequiredError => 'Sila pilih bandar dahulu di Tetapan.';

  @override
  String get locationServiceDisabled =>
      'Perkhidmatan lokasi tidak aktif. Sila aktifkan di System Settings.';

  @override
  String get locationPermissionDenied => 'Kebenaran lokasi ditolak.';

  @override
  String get locationPermissionDeniedForever =>
      'Kebenaran lokasi ditolak secara kekal.\nBuka System Settings → Privacy & Security → Location Services → bedug → Allow, kemudian cuba lagi.';

  @override
  String get notificationChannelName => 'Waktu Solat';

  @override
  String get notificationChannelDescription =>
      'Peringatan azan untuk solat harian';

  @override
  String get openAction => 'Buka';

  @override
  String get retry => 'Cuba Semula';

  @override
  String get loading => 'Memuatkan...';

  @override
  String get today => 'Hari Ini';

  @override
  String get hijriToday => 'Tarikh Hijrah Hari Ini';

  @override
  String get gregorianDate => 'Tarikh Masihi';

  @override
  String get sun => 'Ahd';

  @override
  String get mon => 'Isn';

  @override
  String get tue => 'Sel';

  @override
  String get wed => 'Rab';

  @override
  String get thu => 'Kha';

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
  String get jumadaAlUla => 'Jamadil Awal';

  @override
  String get jumadaAlAkhirah => 'Jamadil Akhir';

  @override
  String get rajab => 'Rejab';

  @override
  String get shaban => 'Syaaban';

  @override
  String get ramadan => 'Ramadan';

  @override
  String get shawwal => 'Syawal';

  @override
  String get dhuAlQidah => 'Zulkaedah';

  @override
  String get dhuAlHijjah => 'Zulhijjah';

  @override
  String get notifSubuh => 'Tiba waktu solat Subuh';

  @override
  String get notifDzuhur => 'Tiba waktu solat Zohor';

  @override
  String get notifAshar => 'Tiba waktu solat Asar';

  @override
  String get notifMaghrib => 'Tiba waktu solat Maghrib';

  @override
  String get notifIsya => 'Tiba waktu solat Isyak';
}
