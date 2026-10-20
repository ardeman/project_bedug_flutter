// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'بيدوغ';

  @override
  String get appTagline => 'تذكير الصلاة، من تراث نوسانتارا.';

  @override
  String get prayerTimes => 'أوقات الصلاة';

  @override
  String get hijriCalendar => 'التقويم الهجري';

  @override
  String get settings => 'الإعدادات';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get upNext => 'التالية';

  @override
  String get recommended => 'موصى به';

  @override
  String get fajr => 'الفجر';

  @override
  String get sunrise => 'الشروق';

  @override
  String get imsak => 'الإمساك';

  @override
  String get dhuha => 'الضحى';

  @override
  String get lastThirdOfNight => 'الثلث الأخير من الليل';

  @override
  String get imsakDescription =>
      'تذكير قبل الفجر بعشر دقائق. يبدأ الصيام عند الفجر.';

  @override
  String get sunriseDescription => 'نهاية وقت صلاة الفجر.';

  @override
  String get dhuhaDescription => 'بداية تقديرية: بعد الشروق بعشرين دقيقة.';

  @override
  String get lastThirdOfNightDescription =>
      'للتهجد قبل فجر هذا اليوم، ويُحسب من غروب اليوم السابق.';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get calculationMethod => 'طريقة الحساب';

  @override
  String get calculationMethodDesc => 'اختر طريقة حساب أوقات الصلاة';

  @override
  String get methodKemenag => 'وزارة الشؤون الدينية (إندونيسيا)';

  @override
  String get methodMWL => 'رابطة العالم الإسلامي';

  @override
  String get methodISNA => 'جمعية إسلامية أمريكا الشمالية';

  @override
  String get methodEgyptian => 'هيئة الشؤون الإسلامية المصرية';

  @override
  String get methodUmmAlQura => 'أم القرى (المملكة العربية السعودية)';

  @override
  String get methodKarachi => 'جامعة العلوم الإسلامية كراتشي';

  @override
  String get methodKuwait => 'الكويت';

  @override
  String get methodQatar => 'قطر';

  @override
  String get methodSingapore => 'سنغافورة';

  @override
  String get methodTurkey => 'تركيا';

  @override
  String get madhab => 'المذهب';

  @override
  String get madhabShafi => 'الشافعي';

  @override
  String get madhabHanafi => 'الحنفي';

  @override
  String get azanNotifications => 'إشعارات الأذان';

  @override
  String get allPrayers => 'جميع الصلوات';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'افتراضي النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get widgetStyle => 'نمط الأداة';

  @override
  String get widgetCompact => 'مضغوط';

  @override
  String get about => 'حول التطبيق';

  @override
  String version(Object version) {
    return 'الإصدار $version';
  }

  @override
  String get locationError => 'فشل في الحصول على الموقع. يرجى تفعيل GPS.';

  @override
  String get locationGuide =>
      'إعدادات النظام ← الخصوصية والأمان ← خدمات الموقع ← bedug ← سماح';

  @override
  String get locationGuideApple =>
      'إعدادات النظام ← الخصوصية والأمان ← خدمات الموقع ← bedug ← سماح';

  @override
  String get locationGuideAndroid =>
      'الإعدادات ← التطبيقات ← bedug ← الأذونات ← الموقع ← سماح';

  @override
  String get locationModeAuto => 'اكتشاف الموقع تلقائيًا';

  @override
  String get locationModeAutoDescOn => 'استخدام GPS الجهاز';

  @override
  String get locationModeAutoDescOff => 'استخدام مدينة يدوية';

  @override
  String get city => 'المدينة';

  @override
  String get selectCity => 'اختر المدينة';

  @override
  String get locationServiceDisabled =>
      'خدمة الموقع غير مفعلة. يرجى تفعيلها من إعدادات النظام.';

  @override
  String get locationServiceDisabledApple =>
      'خدمة الموقع غير مفعلة. يرجى تفعيلها من إعدادات النظام.';

  @override
  String get locationServiceDisabledAndroid =>
      'خدمة الموقع غير مفعلة. يرجى تفعيل الموقع (GPS) من إعدادات أندرويد.';

  @override
  String get locationPermissionDenied => 'تم رفض إذن الموقع.';

  @override
  String get locationPermissionDeniedForever =>
      'تم رفض إذن الموقع بشكل دائم.\nافتح إعدادات النظام ← الخصوصية والأمان ← خدمات الموقع ← bedug ← سماح، ثم حاول مرة أخرى.';

  @override
  String get locationPermissionDeniedForeverApple =>
      'تم رفض إذن الموقع بشكل دائم.\nافتح إعدادات النظام ← الخصوصية والأمان ← خدمات الموقع ← bedug ← سماح، ثم حاول مرة أخرى.';

  @override
  String get locationPermissionDeniedForeverAndroid =>
      'تم رفض إذن الموقع بشكل دائم.\nافتح الإعدادات ← التطبيقات ← bedug ← الأذونات ← الموقع ← سماح، ثم حاول مرة أخرى.';

  @override
  String get notificationChannelName => 'أوقات الصلاة';

  @override
  String get notificationChannelDescription => 'تذكيرات الأذان للصلوات اليومية';

  @override
  String get openAction => 'فتح';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get today => 'اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get hijriToday => 'التاريخ الهجري اليوم';

  @override
  String get gregorianDate => 'التاريخ الميلادي';

  @override
  String get sun => 'أحد';

  @override
  String get mon => 'اثن';

  @override
  String get tue => 'ثلا';

  @override
  String get wed => 'أرب';

  @override
  String get thu => 'خمي';

  @override
  String get fri => 'جمع';

  @override
  String get sat => 'سبت';

  @override
  String get muharram => 'محرم';

  @override
  String get safar => 'صفر';

  @override
  String get rabiAlAwwal => 'ربيع الأول';

  @override
  String get rabiAlThani => 'ربيع الثاني';

  @override
  String get jumadaAlUla => 'جمادى الأولى';

  @override
  String get jumadaAlAkhirah => 'جمادى الآخرة';

  @override
  String get rajab => 'رجب';

  @override
  String get shaban => 'شعبان';

  @override
  String get ramadan => 'رمضان';

  @override
  String get shawwal => 'شوال';

  @override
  String get dhuAlQidah => 'ذو القعدة';

  @override
  String get dhuAlHijjah => 'ذو الحجة';

  @override
  String get notifSubuh => 'حان وقت صلاة الفجر';

  @override
  String get notifDzuhur => 'حان وقت صلاة الظهر';

  @override
  String get notifAshar => 'حان وقت صلاة العصر';

  @override
  String get notifMaghrib => 'حان وقت صلاة المغرب';

  @override
  String get notifIsya => 'حان وقت صلاة العشاء';

  @override
  String get worship => 'العبادة';

  @override
  String get qibla => 'القبلة';

  @override
  String qiblaBearing(String degrees, String direction) {
    return '$degrees° من الشمال ($direction)';
  }

  @override
  String qiblaDistance(String km) {
    return '$km كم إلى الكعبة';
  }

  @override
  String get qiblaFaceNorthHint =>
      'وجّه أعلى الشاشة نحو الشمال، ثم اتبع السهم.';

  @override
  String get qiblaFindNorthHint =>
      'حدّد الشمال ببوصلة الهاتف أو تطبيق خرائط أو موقع الشمس.';

  @override
  String get qiblaRotateHint => 'أدِر الجهاز حتى يشير السهم إلى الأعلى مباشرة.';

  @override
  String get qiblaFacing => 'أنت تتجه نحو القبلة';

  @override
  String get qiblaCalibrate =>
      'دقة البوصلة منخفضة. حرّك الجهاز على شكل الرقم 8.';

  @override
  String qiblaSunLeft(String degrees) {
    return 'القبلة على بعد $degrees° إلى يسار الشمس.';
  }

  @override
  String qiblaSunRight(String degrees) {
    return 'القبلة على بعد $degrees° إلى يمين الشمس.';
  }

  @override
  String get qiblaSunAhead => 'القبلة باتجاه الشمس.';

  @override
  String get qiblaSunBehind => 'القبلة في الاتجاه المعاكس للشمس تمامًا.';

  @override
  String get qiblaNoLocation => 'الموقع غير متاح بعد. حدّده في الإعدادات.';

  @override
  String get dirN => 'الشمال';

  @override
  String get dirNE => 'الشمال الشرقي';

  @override
  String get dirE => 'الشرق';

  @override
  String get dirSE => 'الجنوب الشرقي';

  @override
  String get dirS => 'الجنوب';

  @override
  String get dirSW => 'الجنوب الغربي';

  @override
  String get dirW => 'الغرب';

  @override
  String get dirNW => 'الشمال الغربي';

  @override
  String get whatsNew => 'ما الجديد';

  @override
  String get whatsNewSubtitle => 'التغييرات في كل إصدار';

  @override
  String get changelogUnreleased => 'لم يصدر بعد';

  @override
  String get changelogNew => 'جديد';

  @override
  String get changelogImproved => 'تحسين';

  @override
  String get changelogFixed => 'إصلاح';

  @override
  String get changelogLoadError => 'تعذّر تحميل سجل التغييرات.';

  @override
  String get countryIndonesia => 'إندونيسيا';

  @override
  String get countryMalaysia => 'ماليزيا';

  @override
  String get countrySingapore => 'سنغافورة';

  @override
  String get countryBrunei => 'بروناي';

  @override
  String get countryThailand => 'تايلاند';

  @override
  String get countryPhilippines => 'الفلبين';

  @override
  String get countrySaudiArabia => 'السعودية';

  @override
  String get countryUnitedArabEmirates => 'الإمارات';

  @override
  String get countryQatar => 'قطر';

  @override
  String get countryKuwait => 'الكويت';

  @override
  String get countryBahrain => 'البحرين';

  @override
  String get countryOman => 'عُمان';

  @override
  String get countryJordan => 'الأردن';

  @override
  String get countryPalestine => 'فلسطين';

  @override
  String get countryEgypt => 'مصر';

  @override
  String get countryMorocco => 'المغرب';

  @override
  String get countryTurkey => 'تركيا';

  @override
  String get countryPakistan => 'باكستان';

  @override
  String get countryIndia => 'الهند';

  @override
  String get countryBangladesh => 'بنغلاديش';

  @override
  String get countryUnitedKingdom => 'المملكة المتحدة';

  @override
  String get countryFrance => 'فرنسا';

  @override
  String get countryGermany => 'ألمانيا';

  @override
  String get countryNetherlands => 'هولندا';

  @override
  String get countryUnitedStates => 'الولايات المتحدة';

  @override
  String get countryCanada => 'كندا';

  @override
  String get countryAustralia => 'أستراليا';

  @override
  String get countryJapan => 'اليابان';

  @override
  String get countrySouthKorea => 'كوريا الجنوبية';

  @override
  String get countryNigeria => 'نيجيريا';

  @override
  String get countrySouthAfrica => 'جنوب أفريقيا';

  @override
  String get searchCity => 'ابحث عن مدينة أو دولة';

  @override
  String get noCityFound => 'لا توجد مدينة مطابقة';

  @override
  String get cityAutoDetectHint => 'أوقف التحديد التلقائي لاختيار مدينة';

  @override
  String get sheetHandle => 'مقبض اللوحة';

  @override
  String get sheetExpand => 'توسيع اللوحة';

  @override
  String get sheetCollapse => 'طي اللوحة';

  @override
  String get sheetDismiss => 'إغلاق اللوحة';

  @override
  String get sheetPreview => 'معاينة';

  @override
  String get sheetCollapsed => 'مطوية';

  @override
  String get sheetExpanded => 'موسعة';

  @override
  String get sheetFullScreen => 'ملء الشاشة';

  @override
  String get notificationPreferences => 'التذكيرات والصوت';

  @override
  String get notificationsOff => 'الإشعارات متوقفة';

  @override
  String get beforePrayerReminder => 'تذكير قبل الصلاة';

  @override
  String get reminderOff => 'متوقف';

  @override
  String minutesBeforePrayer(int minutes) {
    return 'قبل $minutes دقيقة';
  }

  @override
  String get notificationSound => 'صوت الإشعار';

  @override
  String get systemNotificationSound => 'صوت النظام';

  @override
  String get silentNotificationSound => 'صامت';

  @override
  String prayerReminderBody(String prayer, int minutes) {
    return 'صلاة $prayer بعد $minutes دقيقة';
  }

  @override
  String get silentPrayerChannel => 'أوقات الصلاة (صامت)';

  @override
  String get notificationDeliveryInfo =>
      'تُجدول التنبيهات للأيام الستة القادمة وتُحدث عند فتح التطبيق. يخضع إرسالها وصوتها لأذونات النظام وإعداداته. يوقف الوضع الصامت الاهتزاز أيضًا.';

  @override
  String get notificationPlatformUnavailable =>
      'الإشعارات المجدولة متاحة على Android وiOS وmacOS. تبقى تفضيلاتك محفوظة على هذا الجهاز.';

  @override
  String get notificationSchedulingError =>
      'تعذرت جدولة التنبيهات. تحقق من إعدادات إشعارات النظام، ثم حاول تغيير إعدادات التذكير مجددًا.';

  @override
  String get notificationSystemSettings => 'إعدادات إشعارات النظام';

  @override
  String get precisePrayerAlerts => 'السماح بالتنبيهات الدقيقة';

  @override
  String get precisePrayerAlertsDescription =>
      'قد يؤخر Android التنبيهات دون إذن المنبهات الدقيقة.';
}
