import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/kemenag_method.dart';

// ─── Locale Provider ──────────────────────────────────────────────────────────

const _kLocale = 'app_locale';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    Future.microtask(() => _load()); // load async setelah build selesai
    return const Locale('id');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocale);
    if (code != null) state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

const supportedLocales = [
  Locale('id'),
  Locale('en'),
  Locale('ar'),
  Locale('ms'),
];

const localeDisplayNames = {
  'id': 'Bahasa Indonesia',
  'en': 'English',
  'ar': 'العربية',
  'ms': 'Bahasa Melayu',
};

// ─── Settings ─────────────────────────────────────────────────────────────────

const _kMethod = 'calc_method';
const _kMadhab = 'madhab';
const _kTheme  = 'theme_mode';

class AppSettings {
  final AppCalculationMethod method;
  final bool isHanafi;
  final int themeMode;

  const AppSettings({
    this.method    = AppCalculationMethod.kemenag,
    this.isHanafi  = false,
    this.themeMode = 0,
  });

  AppSettings copyWith({
    AppCalculationMethod? method,
    bool? isHanafi,
    int? themeMode,
  }) => AppSettings(
    method:    method    ?? this.method,
    isHanafi:  isHanafi  ?? this.isHanafi,
    themeMode: themeMode ?? this.themeMode,
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    Future.microtask(() => _load()); // load async setelah build selesai
    return const AppSettings();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = AppSettings(
      method:    AppCalculationMethod.values[p.getInt(_kMethod) ?? 0],
      isHanafi:  p.getBool(_kMadhab) ?? false,
      themeMode: p.getInt(_kTheme)   ?? 0,
    );
  }

  Future<void> setMethod(AppCalculationMethod m) async {
    state = state.copyWith(method: m);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kMethod, m.index);
  }

  Future<void> setMadhab(bool isHanafi) async {
    state = state.copyWith(isHanafi: isHanafi);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMadhab, isHanafi);
  }

  Future<void> setThemeMode(int mode) async {
    state = state.copyWith(themeMode: mode);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTheme, mode);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);