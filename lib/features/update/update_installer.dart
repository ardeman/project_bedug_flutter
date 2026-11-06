import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'update_checker.dart';

enum UpdateInstallFailure {
  /// The download failed or was cut short.
  download,

  /// The file didn't match its SHA-256 in `SHA256SUMS.txt`.
  checksum,

  /// The app's folder can't be written (e.g. installed for all users), so the
  /// app can't replace itself.
  notWritable,

  /// Android: the user hasn't let Bedug install apps yet; the settings page
  /// for it was opened.
  needsPermission,

  /// The installer couldn't start.
  install,
}

class UpdateInstallException implements Exception {
  final UpdateInstallFailure failure;
  const UpdateInstallException(this.failure);
}

const _android = MethodChannel('com.ardeman.bedug/update');

/// Downloads [update]'s file for this platform and checks its SHA-256.
///
/// [onProgress] gets the fraction done, or null while the size is unknown.
Future<File> downloadUpdate(
  UpdateCheckResult update, {
  ValueChanged<double?>? onProgress,
}) async {
  final url = update.downloadUrl;
  final checksumsUrl = update.checksumsUrl;
  final name = update.assetName;
  if (url == null || checksumsUrl == null || name == null) {
    throw const UpdateInstallException(UpdateInstallFailure.download);
  }

  final dir = await _downloadDir();
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  final client = HttpClient()..userAgent = 'Bedug';
  try {
    final checksums = await _fetchText(client, checksumsUrl);
    final expected = expectedChecksum(checksums, name);
    if (expected == null) {
      throw const UpdateInstallException(UpdateInstallFailure.checksum);
    }

    final request = await client.getUrl(url);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw const UpdateInstallException(UpdateInstallFailure.download);
    }
    final total = response.contentLength;
    var received = 0;
    final sink = file.openWrite();
    try {
      await response
          .map((chunk) {
            received += chunk.length;
            onProgress?.call(total > 0 ? received / total : null);
            return chunk;
          })
          // A stalled connection fails instead of hanging the dialog.
          .timeout(const Duration(seconds: 30))
          .pipe(sink);
    } catch (_) {
      await sink.close().catchError((Object _) {});
      rethrow;
    }

    final actual = (await sha256.bind(file.openRead()).first).toString();
    if (actual != expected) {
      await file.delete().catchError((Object _) => file);
      throw const UpdateInstallException(UpdateInstallFailure.checksum);
    }
    return file;
  } on UpdateInstallException {
    rethrow;
  } on Exception {
    throw const UpdateInstallException(UpdateInstallFailure.download);
  } finally {
    client.close(force: true);
  }
}

Future<String> _fetchText(HttpClient client, Uri url) async {
  final response = await (await client.getUrl(url))
      .close()
      .timeout(const Duration(seconds: 15));
  if (response.statusCode != HttpStatus.ok) {
    throw const UpdateInstallException(UpdateInstallFailure.download);
  }
  return response
      .transform(const SystemEncoding().decoder)
      .join()
      .timeout(const Duration(seconds: 15));
}

/// The SHA-256 listed for [name] in a `shasum -a 256` file.
@visibleForTesting
String? expectedChecksum(String checksums, String name) {
  for (final line in checksums.split('\n')) {
    final match = RegExp(r'^([0-9a-fA-F]{64}) [ *](.+)$')
        .firstMatch(line.trim());
    if (match != null && match.group(2) == name) {
      return match.group(1)!.toLowerCase();
    }
  }
  return null;
}

Future<Directory> _downloadDir() async {
  if (Platform.isAndroid) {
    // The cache folder the installer's FileProvider shares.
    final path = await _android.invokeMethod<String>('updateDir');
    if (path == null) {
      throw const UpdateInstallException(UpdateInstallFailure.download);
    }
    return Directory(path).create(recursive: true);
  }
  return Directory.systemTemp.createTemp('bedug-update');
}

/// Installs a verified download. On the desktops this quits Bedug; a helper
/// script swaps the app once it has exited and opens the new version.
Future<void> installUpdate(File download) async {
  if (Platform.isAndroid) {
    final result = await _android.invokeMethod<String>('installApk', {
      'path': download.path,
    });
    switch (result) {
      case 'started':
        return;
      case 'needsPermission':
        throw const UpdateInstallException(
          UpdateInstallFailure.needsPermission,
        );
      default:
        throw const UpdateInstallException(UpdateInstallFailure.install);
    }
  }

  // The folder the new version replaces: bedug.app on macOS, the bundle
  // folder on Linux and the folder holding bedug.exe on Windows.
  final exe = File(Platform.resolvedExecutable);
  final Directory target;
  final Directory writable;
  if (Platform.isMacOS) {
    target = exe.parent.parent.parent; // …/bedug.app/Contents/MacOS/bedug
    writable = target.parent;
  } else if (Platform.isLinux) {
    target = exe.parent;
    writable = target.parent;
  } else if (Platform.isWindows) {
    target = exe.parent;
    writable = target;
  } else {
    throw const UpdateInstallException(UpdateInstallFailure.install);
  }
  if (!target.path.endsWith('.app') && Platform.isMacOS) {
    throw const UpdateInstallException(UpdateInstallFailure.install);
  }
  if (!await _canWrite(writable)) {
    throw const UpdateInstallException(UpdateInstallFailure.notWritable);
  }

  final work = download.parent;
  try {
    if (Platform.isWindows) {
      final script = File('${work.path}\\install.ps1');
      await script.writeAsString(_windowsScript);
      await Process.start('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-WindowStyle',
        'Hidden',
        '-File',
        script.path,
        '$pid',
        download.path,
        target.path,
        exe.path,
      ], mode: ProcessStartMode.detached);
    } else {
      final staging = Directory('${work.path}/new');
      await staging.create();
      final extract = Platform.isMacOS
          ? await Process.run('ditto', [
              '-x',
              '-k',
              download.path,
              staging.path,
            ])
          : await Process.run('tar', [
              '-xzf',
              download.path,
              '-C',
              staging.path,
            ]);
      final extracted = Directory(
        '${staging.path}/${Platform.isMacOS ? 'bedug.app' : 'bundle'}',
      );
      if (extract.exitCode != 0 || !await extracted.exists()) {
        throw const UpdateInstallException(UpdateInstallFailure.install);
      }
      final script = File('${work.path}/install.sh');
      await script.writeAsString(_unixScript);
      await Process.start('/bin/sh', [
        script.path,
        '$pid',
        extracted.path,
        target.path,
        if (Platform.isMacOS) 'open' else '${target.path}/bedug',
      ], mode: ProcessStartMode.detached);
    }
  } on UpdateInstallException {
    rethrow;
  } on Exception {
    throw const UpdateInstallException(UpdateInstallFailure.install);
  }
  exit(0);
}

Future<bool> _canWrite(Directory dir) async {
  final probe = File('${dir.path}${Platform.pathSeparator}.bedug-update-probe');
  try {
    await probe.writeAsString('');
    await probe.delete();
    return true;
  } on FileSystemException {
    return false;
  }
}

/// Waits for Bedug to quit, swaps the new app in (restoring the old one if
/// the copy fails) and opens it. Arguments: pid, new app, app, launcher
/// (`open` on macOS, the executable on Linux).
const _unixScript = r'''
pid="$1"; new="$2"; app="$3"; launch="$4"
while kill -0 "$pid" 2>/dev/null; do sleep 0.2; done
old="$app.old"
rm -rf "$old"
if mv "$app" "$old"; then
  if cp -R "$new" "$app"; then
    rm -rf "$old"
  else
    rm -rf "$app"; mv "$old" "$app"
  fi
fi
rm -rf "$(dirname "$new")"
if [ "$launch" = open ]; then
  xattr -dr com.apple.quarantine "$app" 2>/dev/null
  open "$app"
else
  cd "$app" && nohup "$launch" >/dev/null 2>&1 &
fi
''';

/// Waits for Bedug to quit, unpacks the new version over the old one and
/// opens it. Arguments: process ID, zip, app folder, bedug.exe.
const _windowsScript = r'''
param([int]$ProcessId, [string]$Zip, [string]$Dir, [string]$Exe)
Wait-Process -Id $ProcessId -ErrorAction SilentlyContinue
$staging = Join-Path (Split-Path $Zip) 'new'
try {
  Expand-Archive -Path $Zip -DestinationPath $staging -Force
  Copy-Item -Path (Join-Path $staging '*') -Destination $Dir -Recurse -Force
} finally {
  Start-Process -FilePath $Exe -WorkingDirectory $Dir
  Remove-Item -Path (Split-Path $Zip) -Recurse -Force -ErrorAction SilentlyContinue
}
''';
