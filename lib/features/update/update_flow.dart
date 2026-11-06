import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:in_app_update/in_app_update.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/glass_controls.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/permission_acknowledgement.dart';
import '../../generated/l10n/app_localizations.dart';
import '../changelog/changelog.dart';
import 'update_channel.dart';
import 'update_checker.dart';
import 'update_installer.dart';

const _kCheckOnLaunch = 'update_check_on_launch';

/// Whether Bedug looks for an update each time it opens (on by default).
class UpdateOnLaunchNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_kCheckOnLaunch) ?? true;

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_kCheckOnLaunch, enabled);
  }
}

final updateOnLaunchProvider = NotifierProvider<UpdateOnLaunchNotifier, bool>(
  UpdateOnLaunchNotifier.new,
);

/// Checks for an update once, a few seconds after launch, when the setting
/// is on; watched by the app so it runs once per process.
final launchUpdateCheckProvider = Provider<void>((ref) {
  if (ref.read(updateChannelProvider) == UpdateChannel.none) return;
  if (!ref.read(updateOnLaunchProvider)) return;
  // Leaves the first frames, permission prompts and the tour to settle.
  final timer = Timer(const Duration(seconds: 4), () {
    unawaited(runUpdateCheck(ref.read, quiet: true));
  });
  ref.onDispose(timer.cancel);
});

enum UpdateOutcome {
  upToDate,

  /// A newer version exists, but the user put it off or it didn't install.
  available,
  failed,

  /// The store or the installer took over.
  started,
}

typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

bool _running = false;

/// Looks for an update and, if there is one, asks the user before updating
/// through this build's channel. [quiet] (the launch check) shows nothing
/// unless an update is found.
Future<(UpdateOutcome, String?)> runUpdateCheck(
  ProviderReader read, {
  required bool quiet,
}) async {
  if (_running) return (UpdateOutcome.failed, null);
  _running = true;
  try {
    return await _run(read, quiet: quiet);
  } finally {
    _running = false;
  }
}

Future<(UpdateOutcome, String?)> _run(
  ProviderReader read, {
  required bool quiet,
}) async {
  final channel = read(updateChannelProvider);
  if (channel == UpdateChannel.playStore) return (await _playUpdate(), null);

  final UpdateCheckResult update;
  try {
    final releases = await read(changelogProvider.future);
    if (releases.isEmpty) throw StateError('The changelog is empty.');
    final current = releases.first.version;
    update = channel == UpdateChannel.appStore
        ? await checkAppStore(
            current,
            mac: defaultTargetPlatform == TargetPlatform.macOS,
          )
        : await checkForUpdate(current);
  } catch (error, stackTrace) {
    _report(error, stackTrace);
    return (UpdateOutcome.failed, null);
  }
  if (!update.updateAvailable) return (UpdateOutcome.upToDate, null);

  final version = update.latestVersion;
  final inApp = channel == UpdateChannel.github && update.downloadUrl != null;
  final context = appNavigatorKey.currentContext;
  if (context == null || !context.mounted) {
    return (UpdateOutcome.available, version);
  }
  final l10n = AppLocalizations.of(context);
  final accepted = await _confirm(
    title: l10n.updateDialogTitle,
    body: inApp
        ? l10n.updateDialogBody(version)
        : l10n.updateDialogBodyStore(version),
    cancel: l10n.updateLater,
    action: l10n.updateNow,
  );
  if (!accepted) return (UpdateOutcome.available, version);

  if (!inApp) {
    return (
      await _open(update.releaseUrl)
          ? UpdateOutcome.started
          : UpdateOutcome.available,
      version,
    );
  }

  try {
    final progress = ValueNotifier<double?>(null);
    final file = await _withProgress(
      progress,
      downloadUpdate(update, onProgress: (value) => progress.value = value),
    );
    await installUpdate(file);
    return (UpdateOutcome.started, version);
  } on UpdateInstallException catch (error, stackTrace) {
    _report(error.failure, stackTrace);
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return (UpdateOutcome.available, version);
    final l10n = AppLocalizations.of(ctx);
    final message = switch (error.failure) {
      UpdateInstallFailure.download => l10n.updateDownloadFailed,
      UpdateInstallFailure.checksum => l10n.updateChecksumFailed,
      UpdateInstallFailure.notWritable ||
      UpdateInstallFailure.install => l10n.updateInstallFailed,
      UpdateInstallFailure.needsPermission => l10n.updateNeedsInstallPermission,
    };
    final openPage =
        error.failure != UpdateInstallFailure.needsPermission &&
        await _confirm(
          title: l10n.updateFailedTitle,
          body: message,
          cancel: l10n.cancel,
          action: l10n.openReleasePage,
        );
    if (openPage) await _open(update.releaseUrl);
    if (error.failure == UpdateInstallFailure.needsPermission) {
      await _confirm(
        title: l10n.updateDialogTitle,
        body: message,
        cancel: null,
        action: l10n.permissionContinue,
      );
    }
    return (UpdateOutcome.available, version);
  }
}

/// Play shows its own prompt and update screen, so it is the confirmation.
Future<UpdateOutcome> _playUpdate() async {
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability == UpdateAvailability.updateNotAvailable) {
      return UpdateOutcome.upToDate;
    }
    if (info.updateAvailability != UpdateAvailability.updateAvailable &&
        info.updateAvailability !=
            UpdateAvailability.developerTriggeredUpdateInProgress) {
      return UpdateOutcome.failed;
    }
    if (!info.immediateUpdateAllowed) return UpdateOutcome.available;
    final result = await InAppUpdate.performImmediateUpdate();
    return result == AppUpdateResult.success
        ? UpdateOutcome.started
        : UpdateOutcome.available;
  } catch (error, stackTrace) {
    // Builds not installed from Play (debug, sideloaded) can't use it.
    _report(error, stackTrace);
    return UpdateOutcome.failed;
  }
}

Future<bool> _open(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (error, stackTrace) {
    _report(error, stackTrace);
    return false;
  }
}

void _report(Object error, StackTrace stackTrace) => FlutterError.reportError(
  FlutterErrorDetails(exception: error, stack: stackTrace, library: 'update'),
);

Future<bool> _confirm({
  required String title,
  required String body,
  required String? cancel,
  required String action,
}) async {
  final context = appNavigatorKey.currentContext;
  if (context == null || !context.mounted) return false;
  if (PlatformCapabilities.isApple) {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              if (cancel != null)
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancel),
                ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            if (cancel != null)
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancel),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}

/// Shows a download dialog with [progress] until [work] completes.
Future<T> _withProgress<T>(ValueNotifier<double?> progress, Future<T> work) {
  final context = appNavigatorKey.currentContext;
  if (context == null || !context.mounted) return work;
  final navigator = Navigator.of(context);
  final l10n = AppLocalizations.of(context);
  Widget content(BuildContext context) => ValueListenableBuilder<double?>(
    valueListenable: progress,
    builder: (context, value, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AdaptiveSpinner(),
        const SizedBox(height: 12),
        Text(
          value == null
              ? l10n.updateDownloading
              : '${l10n.updateDownloading} ${(value * 100).round()}%',
        ),
      ],
    ),
  );
  final route = PlatformCapabilities.isApple
      ? CupertinoDialogRoute<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: CupertinoAlertDialog(content: content(context)),
          ),
        )
      : DialogRoute<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(content: content(context)),
          ),
        );
  unawaited(navigator.push(route));
  return work.whenComplete(() {
    if (route.isActive) navigator.removeRoute(route);
    progress.dispose();
  });
}
