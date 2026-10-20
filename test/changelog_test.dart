import 'dart:io';

import 'package:bedug/features/changelog/changelog.dart';
import 'package:bedug/features/changelog/changelog_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final releases = parseChangelog(File(changelogAsset).readAsStringSync());

  test('every change is written in every app language', () {
    final languages =
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    for (final release in releases) {
      expect(release.changes, isNotEmpty, reason: release.version);
      for (final change in release.changes) {
        expect(change.text.keys.toSet(), languages, reason: release.version);
        expect(change.text.values.every((t) => t.trim().isNotEmpty), isTrue);
      }
    }
  });

  test('the newest release is the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version =
        RegExp(r'^version:\s*([^+\s]+)', multiLine: true).firstMatch(pubspec)!;
    expect(releases.first.version, version.group(1));
    expect(releases.map((r) => r.version).toSet().length, releases.length,
        reason: 'versions are unique');
  });

  test('only the newest release may be undated', () {
    for (final release in releases.skip(1)) {
      expect(release.date, isNotNull, reason: release.version);
    }
  });

  testWidgets('lists each release with its changes', (tester) async {
    final sample = [
      Release(version: '1.1.0', date: DateTime(2026, 11, 2), changes: const [
        Change(type: ChangeType.fixed, text: {'en': 'Fixed a thing.'}),
      ]),
      const Release(version: '1.0.0', changes: [
        Change(type: ChangeType.added, text: {'en': 'Added a thing.'}),
      ]),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [changelogProvider.overrideWith((ref) async => sample)],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangelogScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text("What's New"), findsOneWidget);
    expect(find.text('Version 1.1.0'), findsOneWidget);
    expect(find.text('November 2, 2026'), findsOneWidget);
    expect(find.text('Fixed a thing.'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('Not released yet'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
  });
}
