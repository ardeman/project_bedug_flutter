import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/providers/permission_provider.dart';
import 'package:bedug/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.android,
  ]) {
    test(
      'system notification access refreshes on resume on $platform',
      () async {
        debugDefaultTargetPlatformOverride = platform;
        switch (platform) {
          case TargetPlatform.iOS:
            IOSFlutterLocalNotificationsPlugin.registerWith();
          case TargetPlatform.macOS:
            MacOSFlutterLocalNotificationsPlugin.registerWith();
          case TargetPlatform.android:
            AndroidFlutterLocalNotificationsPlugin.registerWith();
          default:
            break;
        }
        var allowed = false;
        final calls = <String>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'checkPermissions' => {'isEnabled': allowed},
            'areNotificationsEnabled' => allowed,
            _ => true,
          };
        });
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(() {
          container.dispose();
          messenger.setMockMethodCallHandler(channel, null);
          debugDefaultTargetPlatformOverride = null;
        });
        container.listen(notificationsEnabledProvider, (_, _) {});
        expect(
          await container.read(notificationAccessProvider.future),
          isFalse,
        );
        expect(container.read(notificationsEnabledProvider), isFalse);
        allowed = true;
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await pumpEventQueue();
        expect(await container.read(notificationAccessProvider.future), isTrue);
        expect(container.read(notificationsEnabledProvider), isTrue);
        allowed = false;
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await pumpEventQueue();
        expect(
          await container.read(notificationAccessProvider.future),
          isFalse,
        );
        expect(container.read(notificationsEnabledProvider), isFalse);
        expect(calls.any((method) => method.startsWith('request')), isFalse);
        expect(await NotificationService.notificationsAllowed(), isFalse);
      },
    );
  }
}
