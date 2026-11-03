import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../design/platform_capabilities.dart';
import '../providers/permission_provider.dart';
import '../../generated/l10n/app_localizations.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> _queue = Future.value();
final _pending = <AppPermission, Future<bool>>{};

/// Serialize rationales so concurrent loads never stack permission dialogs.
Future<bool> showPermissionAcknowledgement(AppPermission permission) {
  if (_pending.isEmpty) _queue = Future.value();
  return _pending.putIfAbsent(permission, () {
    final result = _queue.then((_) => _show(permission));
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result.whenComplete(() {
      _pending.remove(permission);
    });
  });
}

Future<bool> _show(AppPermission permission) async {
  final context = appNavigatorKey.currentContext;
  if (context == null || !context.mounted) return false;
  final l10n = AppLocalizations.of(context);
  final (title, body) = switch (permission) {
    AppPermission.location => (
      l10n.permissionLocationTitle,
      l10n.permissionLocationBody,
    ),
    AppPermission.locationSettings => (
      l10n.permissionLocationTitle,
      PlatformCapabilities.isApple
          ? l10n.locationPermissionDeniedForeverApple
          : l10n.locationPermissionDeniedForeverAndroid,
    ),
    AppPermission.notifications => (
      l10n.notifications,
      l10n.permissionNotificationBody,
    ),
    AppPermission.preciseAlarms => (
      l10n.precisePrayerAlerts,
      l10n.permissionAlarmBody,
    ),
  };
  if (PlatformCapabilities.isApple) {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.permissionNotNow),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.permissionContinue),
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
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.permissionNotNow),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.permissionContinue),
            ),
          ],
        ),
      ) ??
      false;
}
