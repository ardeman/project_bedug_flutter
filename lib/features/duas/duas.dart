import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const dailyDuasAsset = 'assets/content/duas/daily.json';

class Dua {
  /// When it is read, such as "Before eating", in each language.
  final Map<String, String> title;
  final String arabic;
  final String transliteration;

  /// The meaning in each language, keyed by language code. Arabic has none.
  final Map<String, String> translation;

  /// Where it comes from, such as a surah or hadith collection.
  final String reference;

  const Dua({
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.reference,
  });

  String titleFor(String languageCode) =>
      title[languageCode] ?? title['en'] ?? '';

  /// The meaning in [languageCode], falling back to English; null for Arabic,
  /// where the text itself is read.
  String? translationFor(String languageCode) => languageCode == 'ar'
      ? null
      : translation[languageCode] ?? translation['en'];
}

/// A situation, such as eating or travel, and its duas in reading order.
class DuaCategory {
  final String id;
  final Map<String, String> name;
  final List<Dua> items;

  const DuaCategory({
    required this.id,
    required this.name,
    required this.items,
  });

  String nameFor(String languageCode) => name[languageCode] ?? name['en'] ?? id;
}

class DuaBook {
  /// Credit for the duas and their translation, shown under each list.
  final Map<String, String> source;
  final List<DuaCategory> categories;

  const DuaBook({required this.source, required this.categories});

  String sourceFor(String languageCode) =>
      source[languageCode] ?? source['en'] ?? '';
}

/// Parses the daily duas JSON ([dailyDuasAsset]).
DuaBook parseDuaBook(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  return DuaBook(
    source: Map<String, String>.from(json['source'] as Map),
    categories: [
      for (final c in json['categories'] as List)
        DuaCategory(
          id: c['id'] as String,
          name: Map<String, String>.from(c['name'] as Map),
          items: [
            for (final i in c['items'] as List)
              Dua(
                title: Map<String, String>.from(i['title'] as Map),
                arabic: i['arabic'] as String,
                transliteration: i['transliteration'] as String,
                translation: Map<String, String>.from(i['translation'] as Map),
                reference: i['reference'] as String,
              ),
          ],
        ),
    ],
  );
}

final duaBookProvider = FutureProvider<DuaBook>(
  (ref) async => parseDuaBook(await rootBundle.loadString(dailyDuasAsset)),
);
