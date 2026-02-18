import 'package:hijri/hijri_calendar.dart';

// getDaysInMonth adalah instance method di hijri v3
List<HijriCalendar> buildHijriMonth(int hYear, int hMonth) {
  final temp = HijriCalendar();
  final daysInMonth = temp.getDaysInMonth(hYear, hMonth);
  return List.generate(daysInMonth, (i) {
    final h = HijriCalendar();
    h.hYear = hYear;
    h.hMonth = hMonth;
    h.hDay = i + 1;
    return h;
  });
}

// hijriToGregorian adalah instance method: hijriToGregorian(year, month, day)
DateTime hijriToGregorian(HijriCalendar h) {
  final temp = HijriCalendar();
  return temp.hijriToGregorian(h.hYear, h.hMonth, h.hDay);
}
