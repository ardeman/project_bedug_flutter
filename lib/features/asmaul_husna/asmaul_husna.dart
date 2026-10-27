import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const asmaulHusnaAsset = 'assets/content/asmaul_husna.json';

class DivineName {
  final String arabic;
  final String transliteration;

  /// The meaning in each language, keyed by language code. Arabic has none.
  final Map<String, String> meaning;

  const DivineName({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });

  /// The meaning in [languageCode], falling back to English; null for Arabic,
  /// where the name itself is read.
  String? meaningFor(String languageCode) =>
      languageCode == 'ar' ? null : meaning[languageCode] ?? meaning['en'];
}

class AsmaulHusna {
  /// Credit for the list and its meanings, shown under it.
  final Map<String, String> source;

  /// The 99 names, in reading order.
  final List<DivineName> names;

  const AsmaulHusna({required this.source, required this.names});

  String sourceFor(String languageCode) =>
      source[languageCode] ?? source['en'] ?? '';
}

/// Parses the Asmaul Husna JSON ([asmaulHusnaAsset]).
AsmaulHusna parseAsmaulHusna(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  return AsmaulHusna(
    source: Map<String, String>.from(json['source'] as Map),
    names: [
      for (final n in json['names'] as List)
        DivineName(
          arabic: n['arabic'] as String,
          transliteration: n['transliteration'] as String,
          meaning: Map<String, String>.from(n['meaning'] as Map),
        ),
    ],
  );
}

final asmaulHusnaProvider = FutureProvider<AsmaulHusna>(
  (ref) async =>
      parseAsmaulHusna(await rootBundle.loadString(asmaulHusnaAsset)),
);
