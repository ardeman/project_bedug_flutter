import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/hijri_utils.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});
  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late HijriCalendar _today;
  late int _viewYear;
  late int _viewMonth;

  @override
  void initState() {
    super.initState();
    _today     = HijriCalendar.now();
    _viewYear  = _today.hYear;
    _viewMonth = _today.hMonth;
  }

  void _prev() => setState(() {
    _viewMonth--;
    if (_viewMonth < 1) { _viewMonth = 12; _viewYear--; }
  });

  void _next() => setState(() {
    _viewMonth++;
    if (_viewMonth > 12) { _viewMonth = 1; _viewYear++; }
  });

  DateTime _toGreg(int hY, int hM, int hD) =>
      HijriCalendar().hijriToGregorian(hY, hM, hD);

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final days         = buildHijriMonth(_viewYear, _viewMonth);
    final firstGreg    = _toGreg(_viewYear, _viewMonth, 1);
    final startWeekday = firstGreg.weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hijriCalendar),
        centerTitle: true,
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          color: AppColors.emerald.withOpacity(.12),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '${l10n.today}: ${hijriFullDate(_today)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prev),
          Text(
            '${hijriMonthName(_viewMonth)} $_viewYear H',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _next),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat]
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: TextStyle(
                          color: d == l10n.fri ? AppColors.emerald : null,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        )),
                      ),
                    ))
                .toList(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + days.length,
            itemBuilder: (ctx, i) {
              if (i < startWeekday) return const SizedBox();
              final day  = days[i - startWeekday];
              final greg = _toGreg(day.hYear, day.hMonth, day.hDay);
              final isToday = day.hDay   == _today.hDay &&
                              day.hMonth == _today.hMonth &&
                              day.hYear  == _today.hYear;

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.emerald : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${day.hDay}', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isToday ? Colors.white : null,
                    )),
                    Text('${greg.day}', style: TextStyle(
                      fontSize: 9,
                      color: isToday ? Colors.white70 : Colors.grey,
                    )),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
