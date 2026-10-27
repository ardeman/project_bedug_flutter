import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Use the generated path directly, not flutter_gen.
import 'generated/l10n/app_localizations.dart';
import 'core/design/glass_accessibility.dart';
import 'core/design/linux_desktop.dart';
import 'core/design/platform_capabilities.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/system_accent_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_scope.dart';
import 'home/home_screen.dart';
import 'core/services/prayer_widget_service.dart';
import 'features/infaq/infaq_provider.dart';
import 'features/quran/daily_ayah_widget.dart';

/// Lets a tapped home screen widget open a screen from outside the tree.
final _navigatorKey = GlobalKey<NavigatorState>();

class BedugApp extends ConsumerWidget {
  const BedugApp({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    ref.watch(prayerWidgetSyncProvider);
    ref.watch(infaqListenerProvider);
    ref.watch(dailyAyahWidgetSyncProvider);
    ref.watch(dailyAyahWidgetTapProvider(_navigatorKey));
    final locale = ref.watch(localeProvider);
    final settings = ref.watch(settingsProvider);
    final accent = ref.watch(systemAccentProvider).value;
    final glass =
        ref.watch(glassAccessibilityProvider).value ??
        GlassAccessibility.standard;

    final themeMode = switch (settings.themeMode) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      navigatorKey: _navigatorKey,
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
      theme: buildAppTheme(
        Brightness.light,
        desktop: currentLinuxDesktop,
        accent: accent,
      ),
      darkTheme: buildAppTheme(
        Brightness.dark,
        desktop: currentLinuxDesktop,
        accent: accent,
      ),
      // Cupertino scrollbars on iOS and macOS, not Material ones.
      scrollBehavior: PlatformCapabilities.isApple
          ? const CupertinoScrollBehavior()
          : null,
      home: const HomeScreen(),
      builder: (context, child) => GlassAccessibilityScope(
        settings: glass,
        child: AppThemeScope(child: child!),
      ),
    );
  }
}
