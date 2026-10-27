// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get refresh => 'تحديث';

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
  String get hijriAfterMaghrib => 'بعد المغرب';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get upNext => 'التالية';

  @override
  String get recommended => 'موصى به';

  @override
  String get prayerCategoryObligatory => 'صلاة مفروضة';

  @override
  String get prayerCategorySunnah => 'صلاة نافلة';

  @override
  String get prayerCategoryOther => 'وقت آخر';

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
  String get jumuah => 'الجمعة';

  @override
  String get jumuahDescription => 'وقت الظهر. من لا يصلي الجمعة يصلي الظهر.';

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
  String get hijriAdjustment => 'التاريخ الهجري';

  @override
  String get hijriAdjustmentSubtitle => 'حرّكه ليوافق الإعلان المحلي';

  @override
  String get hijriAdjustmentNone => 'كما هو محسوب';

  @override
  String hijriAdjustmentLater(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيام',
      two: 'يوم',
      one: 'يوم',
    );
    return '+$count $_temp0';
  }

  @override
  String hijriAdjustmentEarlier(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيام',
      two: 'يوم',
      one: 'يوم',
    );
    return '−$count $_temp0';
  }

  @override
  String get hijriSource => 'التقويم الهجري';

  @override
  String get hijriSourceUmmAlQura => 'أم القرى';

  @override
  String get hijriSourceMabims => 'MABIMS';

  @override
  String get hijriSourceUmmAlQuraSubtitle =>
      'التقويم الرسمي للمملكة العربية السعودية';

  @override
  String get hijriSourceMabimsSubtitle =>
      'محسوب وفق معايير MABIMS المعتمدة في إندونيسيا وماليزيا وبروناي وسنغافورة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get allNotifications => 'كل الإشعارات';

  @override
  String get notificationTimes => 'الأوقات';

  @override
  String get notificationSystemSection => 'النظام';

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
  String get notificationChannelDescription => 'تنبيهات أوقات الصلاة';

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
  String get notifJumuah => 'حان وقت صلاة الجمعة';

  @override
  String get notifAshar => 'حان وقت صلاة العصر';

  @override
  String get notifMaghrib => 'حان وقت صلاة المغرب';

  @override
  String get notifIsya => 'حان وقت صلاة العشاء';

  @override
  String get notifLastThirdOfNight => 'حلّ الثلث الأخير من الليل، وقت التهجد';

  @override
  String notifImsak(int minutes) {
    return 'الإمساك: الفجر بعد $minutes دقائق';
  }

  @override
  String get notifSunrise => 'أشرقت الشمس وانتهى وقت الفجر';

  @override
  String get notifDhuha => 'حان وقت صلاة الضحى';

  @override
  String get worship => 'العبادة';

  @override
  String get qibla => 'القبلة';

  @override
  String qiblaBearingEast(String degrees) {
    return '$degrees° من الشمال باتجاه الشرق';
  }

  @override
  String qiblaBearingWest(String bearing, String degrees) {
    return '$bearing° ($degrees° من الشمال باتجاه الغرب)';
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
  String get qiblaRotateHint =>
      'أدِر الجهاز حتى تصبح أيقونة الكعبة في الأعلى مباشرة.';

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
  String get notificationPreferences => 'التذكير';

  @override
  String get notificationsOff => 'الإشعارات متوقفة';

  @override
  String get beforePrayerReminder => 'تذكير مسبق';

  @override
  String get reminderOff => 'متوقف';

  @override
  String minutesBeforePrayer(int minutes) {
    return 'قبل $minutes دقيقة';
  }

  @override
  String get notificationSound => 'الصوت';

  @override
  String get systemNotificationSound => 'صوت النظام';

  @override
  String get silentNotificationSound => 'صامت';

  @override
  String get bedugNotificationSound => 'طبل البدوغ';

  @override
  String get sirenNotificationSound => 'صفارة';

  @override
  String get phoneNotificationSound => 'نغمة الهاتف…';

  @override
  String soundPrayerChannel(String sound) {
    return 'أوقات الصلاة ($sound)';
  }

  @override
  String prayerReminderBody(String prayer, int minutes) {
    return 'صلاة $prayer بعد $minutes دقيقة';
  }

  @override
  String get silentPrayerChannel => 'أوقات الصلاة (صامت)';

  @override
  String get notificationDeliveryInfo =>
      'تُجدول التنبيهات حتى ستة أيام مقدمًا وتُحدث عند فتح التطبيق. يخضع إرسالها وصوتها لأذونات النظام وإعداداته. يوقف الوضع الصامت الاهتزاز أيضًا.';

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

  @override
  String get widgetRefresh => 'افتح Bedug لتحديث أوقات الصلاة';

  @override
  String get widgetAnalogCountdown => 'العد التنازلي التناظري';

  @override
  String get widgetAnalogDescription =>
      'عرض مؤقت دائري بجانب العد التنازلي الرقمي.';

  @override
  String get widgetSchedule => 'أوقات الصلوات القادمة';

  @override
  String get widgetScheduleDescription =>
      'اعرض الصلوات الأربع التي تلي الصلاة التالية البارزة على أدوات iPhone المتوسطة والكبيرة وأدوات Android العريضة.';

  @override
  String get widgetAppearanceHelp =>
      'ينطبق على أدوات الشاشة الرئيسية في iPhone وAndroid. اختر الأداة أو غيّر حجمها من الشاشة الرئيسية.';

  @override
  String get widgetPreview => 'معاينة';

  @override
  String get widgetPreviewHelp =>
      'أوقات توضيحية لعرض التخطيط. قد يختلف مظهر الأدوات الأصلية قليلًا. تُحفظ التغييرات تلقائيًا.';

  @override
  String get widgetSmall => 'صغيرة';

  @override
  String get widgetMedium => 'متوسطة / عريضة';

  @override
  String get widgetLarge => 'كبيرة';

  @override
  String get widgetAnalogAndDigital => 'تناظري ورقمي';

  @override
  String get widgetDigitalOnly => 'رقمي فقط';

  @override
  String get widgetPreviewCountdown => '٠١:٣٠:٠٠';

  @override
  String get infaq => 'إنفاق';

  @override
  String get infaqSubtitle => 'ادعم تطوير بدوق';

  @override
  String get infaqThanksSubtitle => 'شكرًا على إنفاقك';

  @override
  String get infaqIntro =>
      'بدوق مجاني. إنفاقك يدعم تطوير بدوق ويوقف الإعلانات، ولا يذهب إلى جمعية خيرية أو أي جهة أخرى.';

  @override
  String get infaqIntroNoAds =>
      'بدوق مجاني. إنفاقك يدعم تطوير بدوق، ولا يذهب إلى جمعية خيرية أو أي جهة أخرى.';

  @override
  String get infaqSmall => 'إنفاق صغير';

  @override
  String get infaqMedium => 'إنفاق متوسط';

  @override
  String get infaqLarge => 'إنفاق كبير';

  @override
  String get infaqRestoreNote =>
      'يعود إنفاقك بعد إعادة التثبيت أو على جهاز جديد: اضغط «استعادة المشتريات».';

  @override
  String get infaqRestore => 'استعادة المشتريات';

  @override
  String get infaqThanks => 'شكرًا على إنفاقك. جزاك الله خيرًا!';

  @override
  String get infaqAdsOff => 'الإعلانات متوقفة على هذا الجهاز.';

  @override
  String get infaqPending => 'بانتظار اكتمال الدفع…';

  @override
  String get infaqUnavailable =>
      'تعذّر الوصول إلى المتجر. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get infaqFailed => 'لم يكتمل الإنفاق. حاول مرة أخرى.';

  @override
  String get infaqRetry => 'حاول مرة أخرى';

  @override
  String get infaqTrakteer => 'Trakteer';

  @override
  String get infaqTrakteerMethods =>
      'QRIS والمحافظ الإلكترونية والتحويل البنكي';

  @override
  String get infaqKofi => 'Ko-fi';

  @override
  String get infaqKofiMethods => 'PayPal والبطاقات';

  @override
  String get widgetShowCurrent => 'عرض الصلاة الحالية';

  @override
  String get widgetShowCurrentDescription =>
      'اعرض الصلاة الحالية على iPhone وiPad؛ يظل العد التنازلي للصلاة التالية. يمكن لإعدادات كل أداة تجاوز هذا الاختيار.';

  @override
  String get widgetNow => 'الآن';

  @override
  String get dzikir => 'الأذكار';

  @override
  String get dzikirMorning => 'الصباح';

  @override
  String get dzikirEvening => 'المساء';

  @override
  String get dzikirLoadError => 'تعذّر تحميل الأذكار.';

  @override
  String dzikirSource(String source) {
    return 'المصدر: $source';
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
      'انقر على البطاقة للعدّ، واضغط مطوّلًا لإعادة الضبط.';

  @override
  String get dzikirCountAction => 'عدّ';

  @override
  String get dzikirResetAction => 'إعادة ضبط العدد';

  @override
  String get dzikirCollection => 'كتاب الأذكار';

  @override
  String get afterPrayerDzikir => 'الأذكار بعد الصلاة';

  @override
  String get afterPrayerDzikirSubtitle =>
      'الاستغفار والتسبيح وآية الكرسي وغيرها';

  @override
  String get duas => 'الأدعية اليومية';

  @override
  String get duasSubtitle => 'الاستيقاظ والطعام والسفر وغيرها';

  @override
  String get duasLoadError => 'تعذّر تحميل الأدعية.';

  @override
  String get asmaulHusna => 'الأسماء الحسنى';

  @override
  String get asmaulHusnaSubtitle => 'أسماء الله التسعة والتسعون';

  @override
  String get asmaulHusnaLoadError => 'تعذّر تحميل الأسماء الحسنى.';

  @override
  String get dzikirMorningReminder => 'أذكار الصباح';

  @override
  String get dzikirEveningReminder => 'أذكار المساء';

  @override
  String dzikirReminderAfter(int minutes, String prayer) {
    return 'بعد $prayer بـ$minutes دقيقة';
  }

  @override
  String get notifDzikirMorning => 'حان وقت أذكار الصباح';

  @override
  String get notifDzikirEvening => 'حان وقت أذكار المساء';

  @override
  String get quran => 'القرآن';

  @override
  String get quranSurahs => 'السور';

  @override
  String get quranJuz => 'الأجزاء';

  @override
  String get quranBookmarks => 'العلامات';

  @override
  String get quranLoadError => 'تعذّر تحميل القرآن.';

  @override
  String get quranMeccan => 'مكية';

  @override
  String get quranMedinan => 'مدنية';

  @override
  String quranAyahCount(int count) {
    return '$count آية';
  }

  @override
  String quranAyah(int number) {
    return 'الآية $number';
  }

  @override
  String quranJuzNumber(int number) {
    return 'الجزء $number';
  }

  @override
  String get quranContinueReading => 'متابعة القراءة';

  @override
  String get quranNoBookmarks =>
      'لا توجد علامات بعد. اضغط على أيقونة العلامة في آية لحفظها.';

  @override
  String get quranAddBookmark => 'إضافة علامة';

  @override
  String get quranRemoveBookmark => 'إزالة العلامة';

  @override
  String get quranTextSmaller => 'تصغير النص';

  @override
  String get quranTextLarger => 'تكبير النص';

  @override
  String quranNextSurah(String name) {
    return 'السورة التالية: $name';
  }

  @override
  String get dailyAyah => 'آية اليوم';

  @override
  String get dailyAyahOpen => 'افتح في قارئ القرآن';

  @override
  String get dailyAyahWidgetRefresh => 'افتح Bedug لتحميل آية اليوم';

  @override
  String quranReference(String surah, int number, int ayah) {
    return '[$surah: $ayah]';
  }

  @override
  String get khatamPlanner => 'خطة الختمة';

  @override
  String get khatamSetupHint => 'اختر عدد الأيام التي تختم فيها القرآن كاملًا.';

  @override
  String khatamDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String khatamFinishBy(String date) {
    return 'الختم بحلول $date';
  }

  @override
  String get khatamStart => 'ابدأ';

  @override
  String get khatamChange => 'تغيير';

  @override
  String get khatamEnd => 'إنهاء الخطة';

  @override
  String get cancel => 'إلغاء';

  @override
  String khatamTodayTarget(String surah, int ayah) {
    return 'اليوم: اقرأ حتى $surah، الآية $ayah';
  }

  @override
  String get khatamTodayDone => 'اكتملت قراءة اليوم';

  @override
  String khatamPercentRead(int percent) {
    return 'قُرئ $percent٪';
  }

  @override
  String khatamDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقي $count يوم',
      many: 'بقي $count يومًا',
      few: 'بقيت $count أيام',
      two: 'بقي يومان',
      one: 'بقي يوم واحد',
      zero: 'انقضى الموعد المحدد',
    );
    return '$_temp0';
  }

  @override
  String get khatamComplete => 'تمّت الختمة، الحمد لله.';

  @override
  String get khatamNewPlan => 'خطة جديدة';

  @override
  String get khatamMarkRead => 'تحديد كمقروء حتى هنا';

  @override
  String get hijriEvents => 'المناسبات الإسلامية';

  @override
  String get hijriEventsSubtitle =>
      'الأعياد والمناسبات والأيام البيض للعام القادم';

  @override
  String get hijriEventsLoadError => 'تعذّر تحميل المناسبات الإسلامية.';

  @override
  String hijriEventsWhen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count يومًا',
      few: 'بعد $count أيام',
      two: 'بعد يومين',
      one: 'غدًا',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String hijriEventsNote(Object calendar) {
    return 'التواريخ وفق تقويم $calendar المحسوب، مع تعديل التاريخ الهجري من الإعدادات، وقد تختلف بيوم عن الإعلان المحلي.';
  }

  @override
  String get hijriEventReminder => 'تذكير بالمناسبات';

  @override
  String get hijriEventReminderSubtitle =>
      'عند المغرب، مساء اليوم الذي يسبق المناسبات والأيام البيض';

  @override
  String get notifHijriEventTomorrow => 'غدًا. يبدأ يومه الهجري هذا المساء.';
}
