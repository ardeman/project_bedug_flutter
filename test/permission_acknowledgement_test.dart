import 'package:bedug/core/providers/permission_provider.dart';
import 'package:bedug/core/services/notification_service.dart';
import 'package:bedug/core/widgets/permission_acknowledgement.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Apple notification initialization never requests permission', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });
    await NotificationService.init();
    final arguments =
        calls.singleWhere((call) => call.method == 'initialize').arguments
            as Map;
    expect(arguments['requestAlertPermission'], isFalse);
    expect(arguments['requestBadgePermission'], isFalse);
    expect(arguments['requestSoundPermission'], isFalse);
    expect(calls.any((call) => call.method == 'requestPermissions'), isFalse);
    await NotificationService.requestPermissions();
    expect(
      calls.where((call) => call.method == 'requestPermissions'),
      hasLength(1),
    );
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      'permission explanations can be declined and serialize on $platform',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: appNavigatorKey,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              ...AppLocalizations.localizationsDelegates,
            ],
            home: const Scaffold(),
          ),
        );
        final first = showPermissionAcknowledgement(AppPermission.location);
        final duplicate = showPermissionAcknowledgement(AppPermission.location);
        expect(identical(first, duplicate), isTrue);
        final next = showPermissionAcknowledgement(AppPermission.notifications);
        await tester.pumpAndSettle();
        expect(find.text('Use your location?'), findsOneWidget);
        expect(find.text('Notifications'), findsNothing);
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();
        expect(await first, isFalse);
        expect(find.text('Notifications'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(await next, isTrue);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant({platform}),
    );
  }
}
