import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final _releasesUri = Uri.https(
  'api.github.com',
  '/repos/ardeman/project_bedug_flutter/releases',
  {'per_page': '1'},
);

class UpdateCheckResult {
  final String latestVersion;
  final Uri releaseUrl;
  final bool updateAvailable;

  const UpdateCheckResult({
    required this.latestVersion,
    required this.releaseUrl,
    required this.updateAvailable,
  });
}

class UpdateCheckException implements Exception {
  const UpdateCheckException();
}

final updateCheckerProvider =
    Provider<Future<UpdateCheckResult> Function(String currentVersion)>(
      (ref) => checkForUpdate,
    );

Future<UpdateCheckResult> checkForUpdate(String currentVersion) async {
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(_releasesUri)
        .timeout(const Duration(seconds: 10));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'Bedug');
    final response = await request.close().timeout(const Duration(seconds: 10));
    if (response.statusCode != HttpStatus.ok) {
      throw const UpdateCheckException();
    }

    final body = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 10));
    return parseUpdateCheckResponse(body, currentVersion);
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
  String currentVersion,
) {
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

    final latest = _versionParts(latestVersion);
    final current = _versionParts(currentVersion);
    if (latest == null || current == null) {
      throw const FormatException();
    }

    return UpdateCheckResult(
      latestVersion: latestVersion,
      releaseUrl: url,
      updateAvailable: _compareVersions(latest, current) > 0,
    );
  } on FormatException {
    throw const UpdateCheckException();
  }
}

bool _isReleaseUrl(Uri url) {
  final segments = url.pathSegments;
  return segments.length == 5 &&
      segments.take(4).join('/') ==
          'ardeman/project_bedug_flutter/releases/tag' &&
      segments.last.isNotEmpty;
}

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
