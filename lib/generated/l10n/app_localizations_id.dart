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
  String get hijriCalendar => 'Kalender Hijriah';

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
  String get prayerCategoryObligatory => 'Salat wajib';

  @override
  String get prayerCategorySunnah => 'Salat sunnah';

  @override
  String get prayerCategoryOther => 'Waktu lainnya';

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
  String get jumuah => 'Jumat';

  @override
  String get jumuahDescription =>
      'Waktu Zuhur. Yang tidak salat Jumat tetap salat Zuhur.';

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
  String get hijriAdjustment => 'Tanggal Hijriah';

  @override
  String get hijriAdjustmentSubtitle =>
      'Geser agar sesuai pengumuman setempat, seperti sidang isbat';

  @override
  String get hijriAdjustmentNone => 'Sesuai perhitungan';

  @override
  String hijriAdjustmentLater(num count) {
    return '+$count hari';
  }

  @override
  String hijriAdjustmentEarlier(num count) {
    return '−$count hari';
  }

  @override
  String get hijriSource => 'Kalender Hijriah';

  @override
  String get hijriSourceUmmAlQura => 'Ummul Qura';

  @override
  String get hijriSourceMabims => 'MABIMS';

  @override
  String get hijriSourceUmmAlQuraSubtitle => 'Kalender resmi Arab Saudi';

  @override
  String get hijriSourceMabimsSubtitle =>
      'Dihitung dengan kriteria MABIMS Kementerian Agama RI, juga dipakai di Malaysia, Brunei, dan Singapura';

  @override
  String get notifications => 'Notifikasi';

  @override
  String get allNotifications => 'Semua notifikasi';

  @override
  String get notificationTimes => 'Waktu';

  @override
  String get notificationSystemSection => 'Sistem';

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
  String get notificationChannelDescription => 'Pengingat waktu salat';

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
  String get hijriToday => 'Tanggal Hijriah Hari Ini';

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
  String get muharram => 'Muharam';

  @override
  String get safar => 'Safar';

  @override
  String get rabiAlAwwal => 'Rabiulawal';

  @override
  String get rabiAlThani => 'Rabiulakhir';

  @override
  String get jumadaAlUla => 'Jumadilawal';

  @override
  String get jumadaAlAkhirah => 'Jumadilakhir';

  @override
  String get rajab => 'Rajab';

  @override
  String get shaban => 'Syakban';

  @override
  String get ramadan => 'Ramadan';

  @override
  String get shawwal => 'Syawal';

  @override
  String get dhuAlQidah => 'Zulkaidah';

  @override
  String get dhuAlHijjah => 'Zulhijah';

  @override
  String get notifSubuh => 'Waktu Subuh telah tiba';

  @override
  String get notifDzuhur => 'Waktu Zuhur telah tiba';

  @override
  String get notifJumuah => 'Waktu salat Jumat telah tiba';

  @override
  String get notifAshar => 'Waktu Asar telah tiba';

  @override
  String get notifMaghrib => 'Waktu Magrib telah tiba';

  @override
  String get notifIsya => 'Waktu Isya telah tiba';

  @override
  String get notifLastThirdOfNight =>
      'Sepertiga malam terakhir telah tiba, waktu untuk tahajud';

  @override
  String notifImsak(int minutes) {
    return 'Imsak: Subuh $minutes menit lagi';
  }

  @override
  String get notifSunrise =>
      'Matahari telah terbit. Waktu Subuh telah berakhir';

  @override
  String get notifDhuha => 'Waktu salat Duha telah tiba';

  @override
  String get worship => 'Ibadah';

  @override
  String get qibla => 'Kiblat';

  @override
  String qiblaBearingEast(String degrees) {
    return '$degrees° dari utara ke timur';
  }

  @override
  String qiblaBearingWest(String bearing, String degrees) {
    return '$bearing° ($degrees° dari utara ke barat)';
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
      'Putar perangkat sampai ikon Ka\'bah tepat di atas.';

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
  String get notificationPreferences => 'Pengingat';

  @override
  String get notificationsOff => 'Notifikasi nonaktif';

  @override
  String get beforePrayerReminder => 'Pengingat lebih awal';

  @override
  String get reminderOff => 'Nonaktif';

  @override
  String minutesBeforePrayer(int minutes) {
    return '$minutes menit sebelumnya';
  }

  @override
  String get notificationSound => 'Suara';

  @override
  String get systemNotificationSound => 'Suara sistem';

  @override
  String get silentNotificationSound => 'Senyap';

  @override
  String get bedugNotificationSound => 'Bedug';

  @override
  String get sirenNotificationSound => 'Sirene';

  @override
  String get phoneNotificationSound => 'Suara ponsel…';

  @override
  String soundPrayerChannel(String sound) {
    return 'Waktu Salat ($sound)';
  }

  @override
  String prayerReminderBody(String prayer, int minutes) {
    return '$prayer dalam $minutes menit';
  }

  @override
  String get silentPrayerChannel => 'Waktu Salat (senyap)';

  @override
  String get notificationDeliveryInfo =>
      'Pengingat dijadwalkan hingga enam hari ke depan dan diperbarui saat aplikasi dibuka. Pengiriman dan suara mengikuti izin serta pengaturan sistem. Mode senyap juga menonaktifkan getaran.';

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
      'Tampilkan empat salat setelah salat berikutnya yang ditonjolkan pada widget iPhone sedang dan besar serta widget Android lebar.';

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

  @override
  String get infaq => 'Infak';

  @override
  String get infaqSubtitle => 'Dukung pengembangan Bedug';

  @override
  String get infaqThanksSubtitle => 'Terima kasih atas infak Anda';

  @override
  String get infaqIntro =>
      'Bedug gratis. Infak Anda mendukung pengembangan Bedug dan mematikan iklan. Infak tidak disalurkan ke lembaga amal atau pihak lain.';

  @override
  String get infaqIntroNoAds =>
      'Bedug gratis. Infak Anda mendukung pengembangan Bedug. Infak tidak disalurkan ke lembaga amal atau pihak lain.';

  @override
  String get infaqSmall => 'Infak kecil';

  @override
  String get infaqMedium => 'Infak sedang';

  @override
  String get infaqLarge => 'Infak besar';

  @override
  String get infaqRestoreNote =>
      'Infak Anda kembali setelah instal ulang atau di perangkat baru: ketuk Pulihkan pembelian.';

  @override
  String get infaqRestore => 'Pulihkan pembelian';

  @override
  String get infaqThanks =>
      'Terima kasih atas infak Anda. Jazakallahu khairan!';

  @override
  String get infaqAdsOff => 'Iklan sudah dimatikan di perangkat ini.';

  @override
  String get infaqPending => 'Menunggu pembayaran selesai…';

  @override
  String get infaqUnavailable =>
      'Toko tidak dapat dijangkau. Periksa koneksi lalu coba lagi.';

  @override
  String get infaqFailed => 'Infak tidak berhasil. Silakan coba lagi.';

  @override
  String get infaqRetry => 'Coba lagi';

  @override
  String get infaqTrakteer => 'Trakteer';

  @override
  String get infaqTrakteerMethods => 'QRIS, dompet digital, dan transfer bank';

  @override
  String get infaqKofi => 'Ko-fi';

  @override
  String get infaqKofiMethods => 'PayPal dan kartu';

  @override
  String get widgetShowCurrent => 'Tampilkan salat saat ini';

  @override
  String get widgetShowCurrentDescription =>
      'Utamakan salat saat ini di iPhone dan iPad; hitung mundur tetap menuju salat berikutnya. Pengaturan masing-masing widget dapat menggantikan pilihan ini.';

  @override
  String get widgetNow => 'Sekarang';

  @override
  String get dzikir => 'Zikir';

  @override
  String get dzikirMorning => 'Pagi';

  @override
  String get dzikirEvening => 'Petang';

  @override
  String get dzikirLoadError => 'Zikir gagal dimuat.';

  @override
  String dzikirSource(String source) {
    return 'Sumber: $source';
  }

  @override
  String dzikirRepeat(int count) {
    return '$count×';
  }

  @override
  String dzikirProgress(int count, int total) {
    return '$count/$total';
  }

  @override
  String get dzikirCounterHint =>
      'Ketuk kartu untuk menghitung, tekan lama untuk mengatur ulang.';

  @override
  String get dzikirCountAction => 'Hitung';

  @override
  String get dzikirResetAction => 'Atur ulang hitungan';

  @override
  String get dzikirCollection => 'Kitab zikir';

  @override
  String get afterPrayerDzikir => 'Zikir setelah salat';

  @override
  String get afterPrayerDzikirSubtitle =>
      'Istigfar, tasbih, Ayat Kursi, dan lainnya';

  @override
  String get duas => 'Doa harian';

  @override
  String get duasSubtitle => 'Bangun tidur, makan, bepergian, dan lainnya';

  @override
  String get duasLoadError => 'Doa gagal dimuat.';

  @override
  String get asmaulHusna => 'Asmaul Husna';

  @override
  String get asmaulHusnaSubtitle => '99 nama Allah';

  @override
  String get asmaulHusnaLoadError => 'Asmaul Husna gagal dimuat.';

  @override
  String get dzikirMorningReminder => 'Zikir pagi';

  @override
  String get dzikirEveningReminder => 'Zikir petang';

  @override
  String dzikirReminderAfter(int minutes, String prayer) {
    return '$minutes menit setelah $prayer';
  }

  @override
  String get notifDzikirMorning => 'Saatnya membaca zikir pagi';

  @override
  String get notifDzikirEvening => 'Saatnya membaca zikir petang';

  @override
  String get quran => 'Al-Qur\'an';

  @override
  String get quranSurahs => 'Surah';

  @override
  String get quranJuz => 'Juz';

  @override
  String get quranBookmarks => 'Penanda';

  @override
  String get quranLoadError => 'Al-Qur\'an gagal dimuat.';

  @override
  String get quranMeccan => 'Makkiyah';

  @override
  String get quranMedinan => 'Madaniyah';

  @override
  String quranAyahCount(int count) {
    return '$count ayat';
  }

  @override
  String quranAyah(int number) {
    return 'Ayat $number';
  }

  @override
  String quranJuzNumber(int number) {
    return 'Juz $number';
  }

  @override
  String get quranContinueReading => 'Lanjutkan membaca';

  @override
  String get quranNoBookmarks =>
      'Belum ada penanda. Ketuk ikon penanda pada ayat untuk menyimpannya.';

  @override
  String get quranAddBookmark => 'Tandai ayat';

  @override
  String get quranRemoveBookmark => 'Hapus penanda';

  @override
  String get quranTextSmaller => 'Perkecil teks';

  @override
  String get quranTextLarger => 'Perbesar teks';

  @override
  String quranNextSurah(String name) {
    return 'Surah berikutnya: $name';
  }

  @override
  String get dailyAyah => 'Ayat hari ini';

  @override
  String get dailyAyahOpen => 'Buka di pembaca Al-Qur\'an';

  @override
  String get dailyAyahWidgetRefresh => 'Buka Bedug untuk memuat ayat hari ini';

  @override
  String quranReference(String surah, int number, int ayah) {
    return 'QS. $surah [$number]: $ayah';
  }

  @override
  String get khatamPlanner => 'Target khatam';

  @override
  String get khatamSetupHint =>
      'Pilih dalam berapa hari Anda ingin mengkhatamkan Al-Qur\'an.';

  @override
  String khatamDays(int count) {
    return '$count hari';
  }

  @override
  String khatamFinishBy(String date) {
    return 'Khatam pada $date';
  }

  @override
  String get khatamStart => 'Mulai';

  @override
  String get khatamChange => 'Ubah';

  @override
  String get khatamEnd => 'Akhiri target';

  @override
  String get cancel => 'Batal';

  @override
  String khatamTodayTarget(String surah, int ayah) {
    return 'Hari ini: baca sampai $surah ayat $ayah';
  }

  @override
  String get khatamTodayDone => 'Bacaan hari ini selesai';

  @override
  String khatamPercentRead(int percent) {
    return '$percent% terbaca';
  }

  @override
  String khatamDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sisa $count hari',
      zero: 'Tanggal target sudah lewat',
    );
    return '$_temp0';
  }

  @override
  String get khatamComplete => 'Khatam! Alhamdulillah.';

  @override
  String get khatamNewPlan => 'Target baru';

  @override
  String get khatamMarkRead => 'Tandai terbaca sampai sini';

  @override
  String get hijriEvents => 'Hari besar Islam';

  @override
  String get hijriEventsSubtitle =>
      'Hari raya, hari besar dan ayyamul bidh setahun ke depan';

  @override
  String get hijriEventsLoadError => 'Hari besar Islam gagal dimuat.';

  @override
  String hijriEventsWhen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari lagi',
      one: 'Besok',
      zero: 'Hari ini',
    );
    return '$_temp0';
  }

  @override
  String hijriEventsNote(Object calendar) {
    return 'Tanggal mengikuti perhitungan kalender $calendar, digeser oleh pengaturan tanggal Hijriah, dan bisa berbeda sehari dari pengumuman setempat, seperti sidang isbat.';
  }

  @override
  String get hijriEventReminder => 'Pengingat hari besar';

  @override
  String get hijriEventReminderSubtitle =>
      'Saat Magrib, malam sebelum hari besar dan ayyamul bidh';

  @override
  String get notifHijriEventTomorrow =>
      'Besok. Dalam kalender Hijriah, harinya dimulai malam ini.';
}
