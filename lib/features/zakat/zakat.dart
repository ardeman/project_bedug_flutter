import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/locale_provider.dart';

/// The share of zakatable wealth that is due: one fortieth.
const double kZakatRate = 0.025;

/// The nisab of zakat maal in grams of gold, as BAZNAS and the Malaysian
/// state zakat bodies reckon it (20 mithqal).
const int kNisabGoldGrams = 85;

/// Zakat fitrah per person in kilograms of the staple food (one sa').
const double kFitrahStapleKg = 2.5;

/// Zakat maal on what someone owns today, in whole units of their currency.
@immutable
class ZakatMaal {
  final int goldPricePerGram;

  /// Cash, savings, gold and silver, investments, trade goods and money
  /// owed to them that they expect to get back.
  final int assets;

  /// Debts due now, which are taken off the assets.
  final int debts;

  const ZakatMaal({
    required this.goldPricePerGram,
    required this.assets,
    required this.debts,
  });

  int get netWealth => assets - debts < 0 ? 0 : assets - debts;

  int get nisab => goldPricePerGram * kNisabGoldGrams;

  /// Whether the nisab can be found; it needs the gold price.
  bool get hasNisab => goldPricePerGram > 0;

  bool get reachesNisab => hasNisab && netWealth > 0 && netWealth >= nisab;

  /// The zakat due, rounded up so it is never short.
  int get zakat => reachesNisab ? (netWealth * kZakatRate).ceil() : 0;
}

/// Zakat fitrah for [people] at [perPerson] each, in whole units.
int zakatFitrah({required int people, required int perPerson}) =>
    people < 0 || perPerson < 0 ? 0 : people * perPerson;

/// The staple food for [people] when paid in kind, in kilograms.
double fitrahStapleKg(int people) => people < 0 ? 0 : people * kFitrahStapleKg;

/// The prices the calculator needs, kept between visits. The amounts
/// someone owns are never stored.
@immutable
class ZakatPrices {
  /// Zero when not entered.
  final int goldPricePerGram;

  /// The local zakat body's amount per person; zero when not entered.
  final int fitrahPerPerson;

  const ZakatPrices({this.goldPricePerGram = 0, this.fitrahPerPerson = 0});
}

const _kGoldPrice = 'zakat_gold_price_per_gram';
const _kFitrahPerPerson = 'zakat_fitrah_per_person';

class ZakatPricesNotifier extends Notifier<ZakatPrices> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ZakatPrices build() => ZakatPrices(
    goldPricePerGram: _prefs.getInt(_kGoldPrice) ?? 0,
    fitrahPerPerson: _prefs.getInt(_kFitrahPerPerson) ?? 0,
  );

  Future<void> setGoldPricePerGram(int value) async {
    state = ZakatPrices(
      goldPricePerGram: value,
      fitrahPerPerson: state.fitrahPerPerson,
    );
    await _prefs.setInt(_kGoldPrice, value);
  }

  Future<void> setFitrahPerPerson(int value) async {
    state = ZakatPrices(
      goldPricePerGram: state.goldPricePerGram,
      fitrahPerPerson: value,
    );
    await _prefs.setInt(_kFitrahPerPerson, value);
  }
}

final zakatPricesProvider = NotifierProvider<ZakatPricesNotifier, ZakatPrices>(
  ZakatPricesNotifier.new,
);

/// Parses a whole amount typed with any grouping separators; empty or
/// unreadable text is zero.
int parseAmount(String text) =>
    int.tryParse(text.replaceAll(_nonDigits, '')) ?? 0;

final _digit = RegExp('[0-9]');
final _nonDigits = RegExp('[^0-9]');

/// Groups the digits of an amount as the [locale] does while it is typed,
/// keeping the cursor after the same digit.
class AmountInputFormatter extends TextInputFormatter {
  final NumberFormat _format;

  AmountInputFormatter(String locale)
    : _format = NumberFormat.decimalPattern(locale);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(_nonDigits, '');
    if (digits.isEmpty) return const TextEditingValue();
    // Cap the length so the amount stays well inside an int.
    final capped = digits.length > 15 ? digits.substring(0, 15) : digits;
    final text = _format.format(int.parse(capped));

    final cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, newValue.text.length)
        : newValue.text.length;
    final digitsAfter = newValue.text
        .substring(cursor)
        .replaceAll(_nonDigits, '')
        .length;
    var offset = text.length;
    var seen = 0;
    while (offset > 0 && seen < digitsAfter) {
      offset--;
      if (_digit.hasMatch(text[offset])) seen++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
