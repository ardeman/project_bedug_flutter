// ─── main.dart ───────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Notifications are scheduled as absolute instants in `tz.local` (UTC), so the
// 10-year database is enough and far smaller than `latest.dart`.
import 'package:timezone/data/latest_10y.dart' as tz;
import 'core/providers/locale_provider.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The bundled font's OFL must ship with it; show it on the licenses page.
  LicenseRegistry.addLicense(() async* {
    final text =
        await rootBundle.loadString('assets/fonts/plus_jakarta_sans/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans'], text);
  });
  tz.initializeTimeZones();
  // Not awaited: scheduling waits for it, and the first frame shouldn't.
  NotificationService.init();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BedugApp(),
    ),
  );
}
