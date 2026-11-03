import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'locale_provider.dart';

enum AppPermission { location, locationSettings, notifications, preciseAlarms }

/// System prompts require an explicit acknowledgement from the UI.
/// Tests and headless consumers default to declining the request.
final permissionAcknowledgementProvider =
    Provider<Future<bool> Function(AppPermission)>(
      (ref) =>
          (_) async => false,
    );

const notificationAcknowledgementKey = 'notification_permission_acknowledged';
const locationAcknowledgementKey = 'location_permission_acknowledged';

/// Record the location rationale before the service requests system access.
final locationConsentProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final acknowledged = await ref.read(permissionAcknowledgementProvider)(
      AppPermission.location,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setBool(locationAcknowledgementKey, acknowledged);
    return acknowledged;
  };
});

/// Ask once automatically; a deferred request remains available in Settings.
final notificationConsentProvider = FutureProvider<void>((ref) async {
  if (!NotificationService.supportsScheduling) return;
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.containsKey(notificationAcknowledgementKey)) return;
  final acknowledged = await ref.read(permissionAcknowledgementProvider)(
    AppPermission.notifications,
  );
  await prefs.setBool(notificationAcknowledgementKey, acknowledged);
  if (acknowledged) {
    await NotificationService.requestPermissions();
    if (!await NotificationService.notificationsAllowed()) {
      await NotificationService.openSystemSettings();
    }
  }
  if (!acknowledged) {
    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .setNotifications(settings.notifications.copyWith(enabled: false));
  }
  ref.invalidate(notificationAccessProvider);
});

/// Refresh authorization when returning from the system notification settings.
final notificationAccessProvider = FutureProvider.autoDispose<bool>((ref) {
  final lifecycle = AppLifecycleListener(onResume: () => ref.invalidateSelf());
  ref.onDispose(lifecycle.dispose);
  return NotificationService.notificationsAllowed();
});

final notificationsEnabledProvider = Provider.autoDispose<bool>((ref) {
  final allowed = ref.watch(notificationAccessProvider).value ?? false;
  return ref.watch(settingsProvider.select((s) => s.notifications.enabled)) &&
      allowed;
});
