import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Gunakan path generated langsung, bukan flutter_gen
import 'generated/l10n/app_localizations.dart';
import 'core/constants/app_colors.dart';
import 'core/providers/locale_provider.dart';
import 'home/home_screen.dart';

class BedugApp extends ConsumerWidget {
  const BedugApp({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final locale   = ref.watch(localeProvider);
    final settings = ref.watch(settingsProvider);

    final themeMode = switch (settings.themeMode) {
      1    => ThemeMode.light,
      2    => ThemeMode.dark,
      _    => ThemeMode.system,
    };

    return MaterialApp(
      title: 'Bedug',
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
      theme:     _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.emerald,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
    );
  }
}