import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The changelog shared by the app and the website (`site/build.py`).
const changelogAsset = 'assets/changelog/changelog.json';

enum ChangeType { added, improved, fixed }

class Change {
  final ChangeType type;

  /// The change in each language, keyed by language code.
  final Map<String, String> text;

  const Change({required this.type, required this.text});

  /// The text in [languageCode], falling back to English.
  String textFor(String languageCode) =>
      text[languageCode] ?? text['en'] ?? text.values.first;
}

class Release {
  final String version;

  /// Release day, or null while the version is still in testing.
  final DateTime? date;
  final List<Change> changes;

  const Release({required this.version, this.date, required this.changes});
}

const _changeTypes = {
  'new': ChangeType.added,
  'improved': ChangeType.improved,
  'fixed': ChangeType.fixed,
};

/// Parses the changelog JSON, newest release first.
List<Release> parseChangelog(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  return [
    for (final r in json['releases'] as List)
      Release(
        version: r['version'] as String,
        date: r['date'] == null ? null : DateTime.parse(r['date'] as String),
        changes: [
          for (final c in r['changes'] as List)
            Change(
              type: _changeTypes[c['type']]!,
              text: Map<String, String>.from(c['text'] as Map),
            ),
        ],
      ),
  ];
}

final changelogProvider = FutureProvider<List<Release>>((ref) async {
  return parseChangelog(await rootBundle.loadString(changelogAsset));
});
