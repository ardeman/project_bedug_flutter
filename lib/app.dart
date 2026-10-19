import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Use the generated path directly, not flutter_gen.
import 'generated/l10n/app_localizations.dart';
import 'core/design/linux_desktop.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/system_accent_provider.dart';
import 'core/theme/app_theme.dart';
import 'home/home_screen.dart';

class BedugApp extends ConsumerWidget {
  const BedugApp({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final settings = ref.watch(settingsProvider);
    final accent = ref.watch(systemAccentProvider).value;

    final themeMode = switch (settings.themeMode) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: buildAppTheme(Brightness.light,
          desktop: currentLinuxDesktop, accent: accent),
      darkTheme: buildAppTheme(Brightness.dark,
          desktop: currentLinuxDesktop, accent: accent),
      home: const HomeScreen(),
    );
  }
}
