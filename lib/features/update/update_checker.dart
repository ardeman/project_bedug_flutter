import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

const _repo = 'ardeman/project_bedug_flutter';

final _releasesUri = Uri.https('api.github.com', '/repos/$_repo/releases', {
  // The newest release, pre-releases included: GitHub builds are published
  // as pre-releases unless the release is run by hand as the latest.
  'per_page': '1',
});

/// The App Store ID of Bedug (iPhone, iPad and Mac share one listing).
const appStoreId = '6824662589';

/// The GitHub release file each platform installs.
String? githubAssetFor(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android => 'bedug-android.apk',
  TargetPlatform.macOS => 'bedug-macos.zip',
  TargetPlatform.windows => 'bedug-windows.zip',
  TargetPlatform.linux => 'bedug-linux.tar.gz',
  _ => null,
};

const checksumsAssetName = 'SHA256SUMS.txt';

class UpdateCheckResult {
  final String latestVersion;

  /// The release page (GitHub) or the store listing (App Store).
  final Uri releaseUrl;
  final bool updateAvailable;

  /// The file for this platform and the checksum list, on GitHub releases
  /// that have them.
  final Uri? downloadUrl;
  final Uri? checksumsUrl;
  final String? assetName;

  const UpdateCheckResult({
    required this.latestVersion,
    required this.releaseUrl,
    required this.updateAvailable,
    this.downloadUrl,
    this.checksumsUrl,
    this.assetName,
  });
}

class UpdateCheckException implements Exception {
  const UpdateCheckException();
}

/// Checks the newest GitHub release against [currentVersion].
Future<UpdateCheckResult> checkForUpdate(String currentVersion) async {
  final body = await _get(_releasesUri);
  return parseUpdateCheckResponse(
    body,
    currentVersion,
    assetName: githubAssetFor(defaultTargetPlatform),
  );
}

/// Checks the App Store version of the iPhone or Mac app.
Future<UpdateCheckResult> checkAppStore(
  String currentVersion, {
  required bool mac,
}) async {
  final region = Platform.localeName.split(RegExp('[_.-]')).elementAtOrNull(1);
  final body = await _get(
    Uri.https('itunes.apple.com', '/lookup', {
      'id': appStoreId,
      if (mac) 'entity': 'desktopSoftware',
      if (region != null && region.length == 2) 'country': region,
    }),
  );
  return parseAppStoreLookup(body, currentVersion);
}

Future<String> _get(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 10));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/json')
      ..set(HttpHeaders.userAgentHeader, 'Bedug');
    final response = await request.close().timeout(const Duration(seconds: 10));
    if (response.statusCode != HttpStatus.ok) {
      throw const UpdateCheckException();
    }
    return await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 10));
  } on UpdateCheckException {
    rethrow;
  } on Exception {
    throw const UpdateCheckException();
  } finally {
    client.close(force: true);
  }
}

UpdateCheckResult parseUpdateCheckResponse(
  String responseBody,
  String currentVersion, {
  String? assetName,
}) {
  try {
    final decoded = jsonDecode(responseBody);
    if (decoded is! List || decoded.isEmpty) {
      throw const FormatException();
    }

    final release = decoded.first;
    if (release is! Map<String, dynamic>) {
      throw const FormatException();
    }
    final tag = release['tag_name'];
    final rawUrl = release['html_url'];
    if (tag is! String || rawUrl is! String) {
      throw const FormatException();
    }

    final latestVersion = tag.startsWith('v') ? tag.substring(1) : tag;
    final url = Uri.tryParse(rawUrl);
    if (url == null ||
        url.scheme != 'https' ||
        url.host != 'github.com' ||
        !_isReleaseUrl(url)) {
      throw const FormatException();
    }

    Uri? asset(String? name) {
      if (name == null) return null;
      final assets = release['assets'];
      if (assets is! List) return null;
      for (final item in assets) {
        if (item is! Map<String, dynamic> || item['name'] != name) continue;
        final download = Uri.tryParse('${item['browser_download_url']}');
        return download != null && _isDownloadUrl(download, tag, name)
            ? download
            : null;
      }
      return null;
    }

    final download = asset(assetName);
    final checksums = asset(checksumsAssetName);
    return UpdateCheckResult(
      latestVersion: latestVersion,
      releaseUrl: url,
      updateAvailable: _isNewer(latestVersion, currentVersion),
      downloadUrl: checksums == null ? null : download,
      checksumsUrl: download == null ? null : checksums,
      assetName: download == null || checksums == null ? null : assetName,
    );
  } on FormatException {
    throw const UpdateCheckException();
  }
}

/// Reads an iTunes lookup response for the App Store version.
UpdateCheckResult parseAppStoreLookup(
  String responseBody,
  String currentVersion,
) {
  try {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    final results = decoded['results'];
    if (results is! List || results.isEmpty) throw const FormatException();
    final app = results.first;
    if (app is! Map<String, dynamic>) throw const FormatException();
    final version = app['version'];
    final url = Uri.tryParse('${app['trackViewUrl']}');
    if (version is! String ||
        url == null ||
        url.scheme != 'https' ||
        url.host != 'apps.apple.com') {
      throw const FormatException();
    }
    return UpdateCheckResult(
      latestVersion: version,
      releaseUrl: url,
      updateAvailable: _isNewer(version, currentVersion),
    );
  } on FormatException {
    throw const UpdateCheckException();
  }
}

bool _isNewer(String latestVersion, String currentVersion) {
  final latest = _versionParts(latestVersion);
  final current = _versionParts(currentVersion);
  if (latest == null || current == null) throw const FormatException();
  return _compareVersions(latest, current) > 0;
}

bool _isReleaseUrl(Uri url) {
  final segments = url.pathSegments;
  return segments.length == 5 &&
      segments.take(4).join('/') == '$_repo/releases/tag' &&
      segments.last.isNotEmpty;
}

bool _isDownloadUrl(Uri url, String tag, String name) =>
    url.scheme == 'https' &&
    url.host == 'github.com' &&
    url.path == '/$_repo/releases/download/$tag/$name';

List<int>? _versionParts(String version) {
  final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:[-+][0-9A-Za-z.-]+)?$')
      .firstMatch(version);
  if (match == null) return null;
  return [
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  ];
}

int _compareVersions(List<int> left, List<int> right) {
  for (var index = 0; index < left.length; index++) {
    final comparison = left[index].compareTo(right[index]);
    if (comparison != 0) return comparison;
  }
  return 0;
}
