import 'dart:convert';

import 'package:bedug/core/design/platform_capabilities.dart';
import 'package:bedug/features/update/update_checker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String response({
    String tag = 'v1.2.0',
    String url =
        'https://github.com/ardeman/project_bedug_flutter/releases/tag/v1.2.0',
  }) => jsonEncode([
    {'tag_name': tag, 'html_url': url},
  ]);

  test('detects an update using numeric version components', () {
    final result = parseUpdateCheckResponse(response(tag: 'v1.10.0'), '1.9.9');

    expect(result.latestVersion, '1.10.0');
    expect(result.releaseUrl.host, 'github.com');
    expect(result.updateAvailable, isTrue);
  });

  test('reports no update when the remote version is current or older', () {
    for (final tag in ['v1.2.0', 'v1.1.9']) {
      final result = parseUpdateCheckResponse(response(tag: tag), '1.2.0');
      expect(result.updateAvailable, isFalse, reason: tag);
    }
  });

  test('rejects malformed or untrusted release metadata', () {
    expect(
      () => parseUpdateCheckResponse('{}', '1.0.0'),
      throwsA(isA<UpdateCheckException>()),
    );
    expect(
      () => parseUpdateCheckResponse(
        response(url: 'https://example.com/download'),
        '1.0.0',
      ),
      throwsA(isA<UpdateCheckException>()),
    );
  });

  test('rejects invalid current versions', () {
    expect(
      () => parseUpdateCheckResponse(response(), 'not-a-version'),
      throwsA(isA<UpdateCheckException>()),
    );
  });

  test('offers the manual update check only outside the app stores', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const expected = {
      TargetPlatform.iOS: true,
      TargetPlatform.macOS: true,
      TargetPlatform.android: true,
      TargetPlatform.windows: false,
      TargetPlatform.linux: false,
    };
    for (final MapEntry(key: platform, value: viaStore) in expected.entries) {
      debugDefaultTargetPlatformOverride = platform;
      expect(
        PlatformCapabilities.updatesThroughStore,
        viaStore,
        reason: platform.name,
      );
    }
  });
}
