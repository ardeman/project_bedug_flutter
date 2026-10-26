import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';

/// Bundled dzikir collections, keyed by id, in the order the picker lists
/// them. Adding a collection is adding its JSON here and to `pubspec.yaml`.
const dzikirCollectionAssets = {
  'hisnul_muslim': 'assets/content/dzikir/hisnul_muslim.json',
  'rateb_siribee': 'assets/content/dzikir/rateb_siribee.json',
};

/// The collection used until the user picks another.
const defaultDzikirCollectionId = 'hisnul_muslim';

enum DzikirSession { morning, evening }

class DzikirItem {
  /// When it is recited; empty for dzikir not tied to morning or evening,
  /// such as a ratib.
  final Set<DzikirSession> sessions;
  final String arabic;
  final String transliteration;

  /// The meaning in each language, keyed by language code. Arabic has none.
  final Map<String, String> translation;

  /// How many times to recite it.
  final int repeat;

  /// Where it comes from, such as a surah or hadith collection.
  final String reference;

  const DzikirItem({
    required this.sessions,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.repeat,
    required this.reference,
  });

  /// The meaning in [languageCode], falling back to English; null for Arabic,
  /// where the text itself is read.
  String? translationFor(String languageCode) => languageCode == 'ar'
      ? null
      : translation[languageCode] ?? translation['en'];
}

class DzikirCollection {
  final String id;
  final Map<String, String> name;

  /// Credit for the collection and its translation, shown under the list.
  final Map<String, String> source;
  final List<DzikirItem> items;

  const DzikirCollection({
    required this.id,
    required this.name,
    required this.source,
    required this.items,
  });

  String nameFor(String languageCode) => name[languageCode] ?? name['en'] ?? id;

  String sourceFor(String languageCode) =>
      source[languageCode] ?? source['en'] ?? '';

  /// Whether any item belongs to the morning or evening session, so the
  /// reader splits the collection by session.
  bool get hasSessions => items.any((i) => i.sessions.isNotEmpty);

  /// The items recited in [session], in reading order, including those
  /// recited at any time.
  List<DzikirItem> itemsFor(DzikirSession session) => [
    for (final item in items)
      if (item.sessions.isEmpty || item.sessions.contains(session)) item,
  ];
}

/// Parses one collection's JSON (`assets/content/dzikir/*.json`).
DzikirCollection parseDzikirCollection(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  return DzikirCollection(
    id: json['id'] as String,
    name: Map<String, String>.from(json['name'] as Map),
    source: Map<String, String>.from(json['source'] as Map),
    items: [
      for (final i in json['items'] as List)
        DzikirItem(
          sessions: {
            for (final s in i['sessions'] as List? ?? const [])
              DzikirSession.values.byName(s as String),
          },
          arabic: i['arabic'] as String,
          transliteration: i['transliteration'] as String,
          translation: Map<String, String>.from(i['translation'] as Map),
          repeat: i['repeat'] as int,
          reference: i['reference'] as String,
        ),
    ],
  );
}

/// Every bundled collection, in [dzikirCollectionAssets] order.
final dzikirCollectionsProvider = FutureProvider<List<DzikirCollection>>((
  ref,
) async {
  return [
    for (final asset in dzikirCollectionAssets.values)
      parseDzikirCollection(await rootBundle.loadString(asset)),
  ];
});

const _kDzikirCollection = 'dzikir_collection';

/// The id of the collection the user reads from.
class DzikirCollectionNotifier extends Notifier<String> {
  @override
  String build() {
    final stored = ref
        .read(sharedPreferencesProvider)
        .getString(_kDzikirCollection);
    // A collection removed in a later build falls back to the default.
    return dzikirCollectionAssets.containsKey(stored)
        ? stored!
        : defaultDzikirCollectionId;
  }

  Future<void> select(String id) async {
    state = id;
    await ref.read(sharedPreferencesProvider).setString(_kDzikirCollection, id);
  }
}

final dzikirCollectionIdProvider =
    NotifierProvider<DzikirCollectionNotifier, String>(
      DzikirCollectionNotifier.new,
    );

/// The selected collection, once loaded.
final selectedDzikirCollectionProvider = FutureProvider<DzikirCollection>((
  ref,
) async {
  final id = ref.watch(dzikirCollectionIdProvider);
  final collections = await ref.watch(dzikirCollectionsProvider.future);
  return collections.firstWhere(
    (c) => c.id == id,
    orElse: () => collections.first,
  );
});

/// The session to open on: morning from Subuh until Asar, evening from Asar
/// until the next Subuh. Without prayer times, 15:00 and 04:00 stand in for
/// Asar and Subuh.
DzikirSession dzikirSessionAt(DateTime now, {DateTime? fajr, DateTime? asr}) {
  final morningStart = fajr ?? DateTime(now.year, now.month, now.day, 4);
  final eveningStart = asr ?? DateTime(now.year, now.month, now.day, 15);
  return !now.isBefore(morningStart) && now.isBefore(eveningStart)
      ? DzikirSession.morning
      : DzikirSession.evening;
}
