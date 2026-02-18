import 'package:hijri/hijri_calendar.dart';

const List<String> hijriMonthNames = [
  '', 'Muharram', 'Safar', "Rabi'ul Awal", "Rabi'ul Akhir",
  'Jumadil Awal', 'Jumadil Akhir', 'Rajab', "Sya'ban",
  'Ramadan', 'Syawal', "Dzulqa'dah", 'Dzulhijjah',
];

String hijriMonthName(int month) => hijriMonthNames[month];

String hijriFullDate(HijriCalendar h) =>
    '${h.hDay} ${hijriMonthName(h.hMonth)} ${h.hYear} H';

// getDaysInMonth adalah instance method di hijri v3
List<HijriCalendar> buildHijriMonth(int hYear, int hMonth) {
  final temp = HijriCalendar();
  final daysInMonth = temp.getDaysInMonth(hYear, hMonth);
  return List.generate(daysInMonth, (i) {
    final h = HijriCalendar();
    h.hYear  = hYear;
    h.hMonth = hMonth;
    h.hDay   = i + 1;
    return h;
  });
}

// hijriToGregorian adalah instance method: hijriToGregorian(year, month, day)
DateTime hijriToGregorian(HijriCalendar h) {
  final temp = HijriCalendar();
  return temp.hijriToGregorian(h.hYear, h.hMonth, h.hDay);
}