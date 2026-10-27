import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/services/prayer_widget_service.dart';
import '../../generated/l10n/app_localizations.dart';
import 'daily_ayah.dart';
import 'quran.dart';
import 'quran_reader_screen.dart';

/// Days shared with the widget, like the prayer widget's cache.
const dailyAyahWidgetDays = 7;

/// The link a widget opens to read [ref]. The `homeWidget` parameter makes
/// `home_widget` hand it to Flutter.
Uri dailyAyahWidgetUri(AyahRef ref) =>
    Uri.parse('bedug://quran?ayah=$ref&homeWidget');

/// The ayah a widget link opens; null for other links.
AyahRef? ayahFromWidgetUri(Uri? uri) => uri?.host == 'quran'
    ? AyahRef.tryParse(uri!.queryParameters['ayah'])
    : null;

/// Each of the next [dailyAyahWidgetDays] days' ayah, keyed by local date, so
/// the native widget changes at midnight without running Flutter.
Map<String, Object> buildDailyAyahWidgetData({
  required DailyAyahs ayahs,
  required QuranIndex index,
  required AppLocalizations l10n,
  required DateTime now,
  required int themeMode,
}) {
  final language = l10n.localeName;
  return {
    'days': [
      for (var i = 0; i < dailyAyahWidgetDays; i++)
        if (DateTime(now.year, now.month, now.day + i) case final day)
          if (ayahs.pick(day) case final pick)
            {
              'date': _dateKey(day),
              'link': dailyAyahWidgetUri(pick.ayah.ref).toString(),
              'arabic': pick.ayah.arabic,
              'translation': pick.ayah.translationFor(language) ?? '',
              'reference': l10n.quranReference(
                index.surah(pick.ayah.ref.surah).nameFor(language),
                pick.ayah.ref.surah,
                pick.ayah.ref.ayah,
              ),
              'why': pick.group.whyFor(language),
            },
    ],
    'locale': language,
    'title': l10n.dailyAyah,
    'refresh': l10n.dailyAyahWidgetRefresh,
    'themeMode': themeMode,
    ...widgetPalette(),
  };
}

/// `yyyy-MM-dd`, which the native widgets compare with the device's date.
String _dateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

class DailyAyahWidgetService {
  Future<void> _pending = Future.value();

  /// Serialized like [PrayerWidgetService.update].
  Future<void> update(Map<String, Object> data) {
    _pending = _pending.then((_) async {
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await HomeWidget.setAppGroupId(PrayerWidgetService.appGroup);
        }
        await HomeWidget.saveWidgetData<String>(
          'ayah_widget',
          jsonEncode(data),
        );
        await HomeWidget.updateWidget(
          androidName: 'AyahWidgetProvider',
          iOSName: 'BedugAyahWidget',
        );
      } catch (error) {
        debugPrint('Ayah widget update failed: $error');
      }
    });
    return _pending;
  }
}

final dailyAyahWidgetServiceProvider = Provider(
  (ref) => DailyAyahWidgetService(),
);

bool get _hasHomeWidgets =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Shares the coming week's ayahs when they load, the language or theme
/// changes, or the app resumes, which moves the week along.
final dailyAyahWidgetSyncProvider = Provider<void>((ref) {
  if (!_hasHomeWidgets) return;
  final ayahs = ref.watch(dailyAyahsProvider).value;
  final index = ref.watch(quranIndexProvider).value;
  final locale = ref.watch(localeProvider);
  final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
  if (ayahs == null || index == null) return;
  void sync() => unawaited(
    ref
        .read(dailyAyahWidgetServiceProvider)
        .update(
          buildDailyAyahWidgetData(
            ayahs: ayahs,
            index: index,
            l10n: lookupAppLocalizations(locale),
            now: clock.now(),
            themeMode: themeMode,
          ),
        ),
  );
  final lifecycle = AppLifecycleListener(onResume: sync);
  ref.onDispose(lifecycle.dispose);
  sync();
});

/// Opens the reader at the ayah of a tapped widget, whether the tap launched
/// the app or reached it while running.
final dailyAyahWidgetTapProvider =
    Provider.family<void, GlobalKey<NavigatorState>>((ref, navigator) {
      if (!_hasHomeWidgets) return;
      void open(Uri? uri) {
        final ayah = ayahFromWidgetUri(uri);
        if (ayah == null) return;
        // A tap that launched the app may arrive before the first frame.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => navigator.currentState?.push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  QuranReaderScreen(surah: ayah.surah, initialAyah: ayah.ayah),
            ),
          ),
        );
      }

      unawaited(HomeWidget.initiallyLaunchedFromHomeWidget().then(open));
      final taps = HomeWidget.widgetClicked.listen(open);
      ref.onDispose(taps.cancel);
    });
