import 'dart:convert';

import 'package:bedug/features/update/update_channel.dart';
import 'package:bedug/features/update/update_checker.dart';
import 'package:bedug/features/update/update_installer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const download =
      'https://github.com/ardeman/project_bedug_flutter/releases/download';

  String response({
    String tag = 'v1.2.0',
    String url =
        'https://github.com/ardeman/project_bedug_flutter/releases/tag/v1.2.0',
    List<Map<String, String>> assets = const [],
  }) => jsonEncode([
    {'tag_name': tag, 'html_url': url, 'assets': assets},
  ]);

  Map<String, String> asset(String name, {String tag = 'v1.2.0'}) => {
    'name': name,
    'browser_download_url': '$download/$tag/$name',
  };

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

  test('finds the platform file and the checksums on the release', () {
    final result = parseUpdateCheckResponse(
      response(
        assets: [
          asset('bedug-windows.zip'),
          asset('bedug-linux.tar.gz'),
          asset(checksumsAssetName),
        ],
      ),
      '1.0.0',
      assetName: 'bedug-linux.tar.gz',
    );

    expect(
      result.downloadUrl.toString(),
      '$download/v1.2.0/bedug-linux.tar.gz',
    );
    expect(
      result.checksumsUrl.toString(),
      '$download/v1.2.0/$checksumsAssetName',
    );
    expect(result.assetName, 'bedug-linux.tar.gz');
  });

  test('installs nothing without checksums or from another repository', () {
    final noChecksums = parseUpdateCheckResponse(
      response(assets: [asset('bedug-macos.zip')]),
      '1.0.0',
      assetName: 'bedug-macos.zip',
    );
    expect(noChecksums.downloadUrl, isNull);

    final elsewhere = parseUpdateCheckResponse(
      response(
        assets: [
          {
            'name': 'bedug-macos.zip',
            'browser_download_url': 'https://github.com/someone/else/releases/download/v1.2.0/bedug-macos.zip',
          },
          asset(checksumsAssetName),
        ],
      ),
      '1.0.0',
      assetName: 'bedug-macos.zip',
    );
    expect(elsewhere.downloadUrl, isNull);
  });

  test('reads the App Store version and listing', () {
    final body = jsonEncode({
      'resultCount': 1,
      'results': [
        {
          'version': '1.0.2',
          'trackViewUrl': 'https://apps.apple.com/id/app/bedug/id$appStoreId',
        },
      ],
    });

    final result = parseAppStoreLookup(body, '1.0.1');
    expect(result.updateAvailable, isTrue);
    expect(result.releaseUrl.host, 'apps.apple.com');
    expect(result.downloadUrl, isNull);
    expect(
      () => parseAppStoreLookup(jsonEncode({'results': []}), '1.0.1'),
      throwsA(isA<UpdateCheckException>()),
    );
  });

  test('reads the checksum for one file from SHA256SUMS.txt', () {
    final a = 'a' * 64;
    final b = 'B' * 64;
    final sums = '$a  bedug-android.apk\n$b  bedug-macos.zip\n';

    expect(expectedChecksum(sums, 'bedug-macos.zip'), 'b' * 64);
    expect(expectedChecksum(sums, 'bedug-linux.tar.gz'), isNull);
  });

  test('updates through the store unless the build is from GitHub', () {
    const store = {
      TargetPlatform.iOS: UpdateChannel.appStore,
      TargetPlatform.macOS: UpdateChannel.appStore,
      TargetPlatform.android: UpdateChannel.playStore,
      TargetPlatform.windows: UpdateChannel.github,
      TargetPlatform.linux: UpdateChannel.github,
    };
    for (final MapEntry(key: platform, value: channel) in store.entries) {
      expect(
        updateChannelFor(platform, distribution: ''),
        channel,
        reason: platform.name,
      );
    }

    const github = {
      TargetPlatform.iOS: UpdateChannel.appStore,
      TargetPlatform.macOS: UpdateChannel.github,
      TargetPlatform.android: UpdateChannel.github,
      TargetPlatform.windows: UpdateChannel.github,
      TargetPlatform.linux: UpdateChannel.github,
    };
    for (final MapEntry(key: platform, value: channel) in github.entries) {
      expect(
        updateChannelFor(platform, distribution: 'github'),
        channel,
        reason: platform.name,
      );
    }

    expect(
      updateChannelFor(TargetPlatform.android, isWeb: true),
      UpdateChannel.none,
    );
  });
}
