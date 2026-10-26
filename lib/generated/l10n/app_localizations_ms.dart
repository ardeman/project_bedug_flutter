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
  String get hijriAfterMaghrib => 'Selepas Maghrib';

  @override
  String get nextPrayer => 'Solat Seterusnya';

  @override
  String get upNext => 'Seterusnya';

  @override
  String get recommended => 'Disyorkan';

  @override
  String get prayerCategoryObligatory => 'Solat wajib';

  @override
  String get prayerCategorySunnah => 'Solat sunat';

  @override
  String get prayerCategoryOther => 'Waktu lain';

  @override
  String get fajr => 'Subuh';

  @override
  String get sunrise => 'Syuruk';

  @override
  String get imsak => 'Imsak';

  @override
  String get dhuha => 'Duha';

  @override
  String get lastThirdOfNight => 'Sepertiga malam terakhir';

  @override
  String get imsakDescription =>
      'Peringatan 10 minit sebelum Subuh. Puasa bermula pada Subuh.';

  @override
  String get sunriseDescription => 'Akhir waktu Subuh.';

  @override
  String get dhuhaDescription => 'Anggaran mula: 20 minit selepas syuruk.';

  @override
  String get lastThirdOfNightDescription =>
      'Untuk tahajud sebelum Subuh hari ini, dikira dari Maghrib sebelumnya.';

  @override
  String get dhuhr => 'Zohor';

  @override
  String get jumuah => 'Jumaat';

  @override
  String get jumuahDescription =>
      'Waktu Zohor. Yang tidak solat Jumaat tetap solat Zohor.';

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
  String get notifications => 'Pemberitahuan';

  @override
  String get allNotifications => 'Semua pemberitahuan';

  @override
  String get notificationTimes => 'Waktu';

  @override
  String get notificationSystemSection => 'Sistem';

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
  String get locationGuideApple =>
      'System Settings → Privacy & Security → Location Services → bedug → Allow';

  @override
  String get locationGuideAndroid =>
      'Tetapan → Aplikasi → bedug → Kebenaran → Lokasi → Benarkan';

  @override
  String get locationModeAuto => 'Kesan lokasi automatik';

  @override
  String get locationModeAutoDescOn => 'Menggunakan GPS peranti';

  @override
  String get locationModeAutoDescOff => 'Gunakan bandar manual';

  @override
  String get city => 'Bandar';

  @override
  String get selectCity => 'Pilih bandar';

  @override
  String get locationServiceDisabled =>
      'Perkhidmatan lokasi tidak aktif. Sila aktifkan di System Settings.';

  @override
  String get locationServiceDisabledApple =>
      'Perkhidmatan lokasi tidak aktif. Sila aktifkan di System Settings.';

  @override
  String get locationServiceDisabledAndroid =>
      'Perkhidmatan lokasi tidak aktif. Sila aktifkan Lokasi (GPS) di Tetapan Android.';

  @override
  String get locationPermissionDenied => 'Kebenaran lokasi ditolak.';

  @override
  String get locationPermissionDeniedForever =>
      'Kebenaran lokasi ditolak secara kekal.\nBuka System Settings → Privacy & Security → Location Services → bedug → Allow, kemudian cuba lagi.';

  @override
  String get locationPermissionDeniedForeverApple =>
      'Kebenaran lokasi ditolak secara kekal.\nBuka System Settings → Privacy & Security → Location Services → bedug → Allow, kemudian cuba lagi.';

  @override
  String get locationPermissionDeniedForeverAndroid =>
      'Kebenaran lokasi ditolak secara kekal.\nBuka Tetapan → Aplikasi → bedug → Kebenaran → Lokasi → Benarkan, kemudian cuba lagi.';

  @override
  String get notificationChannelName => 'Waktu Solat';

  @override
  String get notificationChannelDescription => 'Peringatan waktu solat';

  @override
  String get openAction => 'Buka';

  @override
  String get retry => 'Cuba Semula';

  @override
  String get loading => 'Memuatkan...';

  @override
  String get today => 'Hari Ini';

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan seterusnya';

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
  String get notifJumuah => 'Tiba waktu solat Jumaat';

  @override
  String get notifAshar => 'Tiba waktu solat Asar';

  @override
  String get notifMaghrib => 'Tiba waktu solat Maghrib';

  @override
  String get notifIsya => 'Tiba waktu solat Isyak';

  @override
  String get notifLastThirdOfNight =>
      'Sepertiga malam terakhir telah tiba, waktu untuk tahajud';

  @override
  String notifImsak(int minutes) {
    return 'Imsak: Subuh dalam $minutes minit';
  }

  @override
  String get notifSunrise =>
      'Matahari telah terbit. Waktu Subuh telah berakhir';

  @override
  String get notifDhuha => 'Tiba waktu solat Duha';

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
    return '$km km ke Kaabah';
  }

  @override
  String get qiblaFaceNorthHint =>
      'Halakan bahagian atas skrin ke utara, kemudian ikut anak panah.';

  @override
  String get qiblaFindNorthHint =>
      'Cari arah utara dengan kompas telefon, aplikasi peta atau kedudukan matahari.';

  @override
  String get qiblaRotateHint =>
      'Pusingkan peranti sehingga ikon Kaabah tepat di atas.';

  @override
  String get qiblaFacing => 'Anda menghadap kiblat';

  @override
  String get qiblaCalibrate =>
      'Ketepatan kompas rendah. Gerakkan peranti membentuk angka 8.';

  @override
  String qiblaSunLeft(String degrees) {
    return 'Kiblat $degrees° di sebelah kiri matahari.';
  }

  @override
  String qiblaSunRight(String degrees) {
    return 'Kiblat $degrees° di sebelah kanan matahari.';
  }

  @override
  String get qiblaSunAhead => 'Kiblat sehala dengan matahari.';

  @override
  String get qiblaSunBehind => 'Kiblat betul-betul membelakangi matahari.';

  @override
  String get qiblaNoLocation =>
      'Lokasi belum tersedia. Tetapkan lokasi dalam Tetapan.';

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
  String get whatsNew => 'Apa yang Baharu';

  @override
  String get whatsNewSubtitle => 'Perubahan dalam setiap versi';

  @override
  String get changelogUnreleased => 'Belum dikeluarkan';

  @override
  String get changelogNew => 'Baharu';

  @override
  String get changelogImproved => 'Ditambah baik';

  @override
  String get changelogFixed => 'Dibaiki';

  @override
  String get changelogLoadError => 'Log perubahan tidak dapat dimuatkan.';

  @override
  String get countryIndonesia => 'Indonesia';

  @override
  String get countryMalaysia => 'Malaysia';

  @override
  String get countrySingapore => 'Singapura';

  @override
  String get countryBrunei => 'Brunei';

  @override
  String get countryThailand => 'Thailand';

  @override
  String get countryPhilippines => 'Filipina';

  @override
  String get countrySaudiArabia => 'Arab Saudi';

  @override
  String get countryUnitedArabEmirates => 'Emiriah Arab Bersatu';

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
  String get countryPalestine => 'Palestin';

  @override
  String get countryEgypt => 'Mesir';

  @override
  String get countryMorocco => 'Maghribi';

  @override
  String get countryTurkey => 'Turkiye';

  @override
  String get countryPakistan => 'Pakistan';

  @override
  String get countryIndia => 'India';

  @override
  String get countryBangladesh => 'Bangladesh';

  @override
  String get countryUnitedKingdom => 'United Kingdom';

  @override
  String get countryFrance => 'Perancis';

  @override
  String get countryGermany => 'Jerman';

  @override
  String get countryNetherlands => 'Belanda';

  @override
  String get countryUnitedStates => 'Amerika Syarikat';

  @override
  String get countryCanada => 'Kanada';

  @override
  String get countryAustralia => 'Australia';

  @override
  String get countryJapan => 'Jepun';

  @override
  String get countrySouthKorea => 'Korea Selatan';

  @override
  String get countryNigeria => 'Nigeria';

  @override
  String get countrySouthAfrica => 'Afrika Selatan';

  @override
  String get searchCity => 'Cari bandar atau negara';

  @override
  String get noCityFound => 'Tiada bandar yang sepadan';

  @override
  String get cityAutoDetectHint =>
      'Matikan pengesanan automatik untuk memilih bandar';

  @override
  String get sheetHandle => 'Pemegang panel';

  @override
  String get sheetExpand => 'Kembangkan panel';

  @override
  String get sheetCollapse => 'Kecilkan panel';

  @override
  String get sheetDismiss => 'Tutup panel';

  @override
  String get sheetPreview => 'Pratonton';

  @override
  String get sheetCollapsed => 'Dikecilkan';

  @override
  String get sheetExpanded => 'Dikembangkan';

  @override
  String get sheetFullScreen => 'Skrin penuh';

  @override
  String get notificationPreferences => 'Peringatan';

  @override
  String get notificationsOff => 'Pemberitahuan dimatikan';

  @override
  String get beforePrayerReminder => 'Peringatan awal';

  @override
  String get reminderOff => 'Dimatikan';

  @override
  String minutesBeforePrayer(int minutes) {
    return '$minutes minit sebelumnya';
  }

  @override
  String get notificationSound => 'Bunyi';

  @override
  String get systemNotificationSound => 'Bunyi sistem';

  @override
  String get silentNotificationSound => 'Senyap';

  @override
  String get bedugNotificationSound => 'Bedug';

  @override
  String get sirenNotificationSound => 'Siren';

  @override
  String get phoneNotificationSound => 'Bunyi telefon…';

  @override
  String soundPrayerChannel(String sound) {
    return 'Waktu Solat ($sound)';
  }

  @override
  String prayerReminderBody(String prayer, int minutes) {
    return '$prayer dalam $minutes minit';
  }

  @override
  String get silentPrayerChannel => 'Waktu Solat (senyap)';

  @override
  String get notificationDeliveryInfo =>
      'Peringatan dijadualkan sehingga enam hari akan datang dan dikemas kini apabila aplikasi dibuka. Penghantaran dan bunyi mengikut kebenaran serta tetapan sistem. Mod senyap turut mematikan getaran.';

  @override
  String get notificationPlatformUnavailable =>
      'Pemberitahuan berjadual tersedia pada Android, iOS dan macOS. Pilihan anda tetap disimpan pada peranti ini.';

  @override
  String get notificationSchedulingError =>
      'Peringatan tidak dapat dijadualkan. Semak tetapan pemberitahuan sistem, kemudian cuba ubah tetapan peringatan sekali lagi.';

  @override
  String get notificationSystemSettings => 'Tetapan pemberitahuan sistem';

  @override
  String get precisePrayerAlerts => 'Benarkan peringatan tepat pada waktu';

  @override
  String get precisePrayerAlertsDescription =>
      'Android mungkin melambatkan peringatan tanpa kebenaran penggera tepat.';

  @override
  String get widgetRefresh => 'Buka Bedug untuk mengemas kini waktu solat';

  @override
  String get widgetAnalogCountdown => 'Kira detik analog';

  @override
  String get widgetAnalogDescription =>
      'Paparkan pemasa bulatan di samping kira detik digital.';

  @override
  String get widgetSchedule => 'Waktu solat seterusnya';

  @override
  String get widgetScheduleDescription =>
      'Paparkan empat solat selepas solat seterusnya yang ditonjolkan pada widget iPhone sederhana dan besar serta widget Android lebar.';

  @override
  String get widgetAppearanceHelp =>
      'Digunakan untuk widget skrin utama iPhone dan Android. Pilih atau ubah saiz widget pada skrin utama.';

  @override
  String get widgetPreview => 'Pratonton';

  @override
  String get widgetPreviewHelp =>
      'Waktu contoh menunjukkan susun atur. Paparan widget sebenar mungkin sedikit berbeza. Perubahan disimpan secara automatik.';

  @override
  String get widgetSmall => 'Kecil';

  @override
  String get widgetMedium => 'Sederhana / lebar';

  @override
  String get widgetLarge => 'Besar';

  @override
  String get widgetAnalogAndDigital => 'Analog + digital';

  @override
  String get widgetDigitalOnly => 'Digital sahaja';

  @override
  String get widgetPreviewCountdown => '01:30:00';

  @override
  String get infaq => 'Infak';

  @override
  String get infaqSubtitle => 'Sokong pembangunan Bedug';

  @override
  String get infaqThanksSubtitle => 'Terima kasih atas infak anda';

  @override
  String get infaqIntro =>
      'Bedug percuma. Infak anda menyokong pembangunan Bedug dan mematikan iklan. Infak tidak disalurkan kepada badan amal atau pihak lain.';

  @override
  String get infaqIntroNoAds =>
      'Bedug percuma. Infak anda menyokong pembangunan Bedug. Infak tidak disalurkan kepada badan amal atau pihak lain.';

  @override
  String get infaqSmall => 'Infak kecil';

  @override
  String get infaqMedium => 'Infak sederhana';

  @override
  String get infaqLarge => 'Infak besar';

  @override
  String get infaqRestoreNote =>
      'Infak anda kembali selepas pasang semula atau pada peranti baharu: ketik Pulihkan pembelian.';

  @override
  String get infaqRestore => 'Pulihkan pembelian';

  @override
  String get infaqThanks =>
      'Terima kasih atas infak anda. Jazakallahu khairan!';

  @override
  String get infaqAdsOff => 'Iklan telah dimatikan pada peranti ini.';

  @override
  String get infaqPending => 'Menunggu pembayaran selesai…';

  @override
  String get infaqUnavailable =>
      'Kedai tidak dapat dicapai. Semak sambungan dan cuba lagi.';

  @override
  String get infaqFailed => 'Infak tidak berjaya. Sila cuba lagi.';

  @override
  String get infaqRetry => 'Cuba lagi';

  @override
  String get infaqTrakteer => 'Trakteer';

  @override
  String get infaqTrakteerMethods => 'QRIS, e-dompet dan pindahan bank';

  @override
  String get infaqKofi => 'Ko-fi';

  @override
  String get infaqKofiMethods => 'PayPal dan kad';

  @override
  String get widgetShowCurrent => 'Tunjukkan solat semasa';

  @override
  String get widgetShowCurrentDescription =>
      'Utamakan solat semasa pada iPhone dan iPad; kira detik tetap menuju solat seterusnya. Tetapan setiap widget boleh menggantikan pilihan ini.';

  @override
  String get widgetNow => 'Sekarang';
}
