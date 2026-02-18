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
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get today => 'اليوم';

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
}
