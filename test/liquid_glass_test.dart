import 'package:bedug/core/design/liquid_glass.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'long pushed title clears controls in $brightness and $direction',
        (tester) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final navigator = GlobalKey<NavigatorState>();
          const title = 'A very long translated calculation method title';
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigator,
              theme: buildAppTheme(brightness),
              builder: (context, child) => AppThemeScope(
                child: Directionality(textDirection: direction, child: child!),
              ),
              home: const Scaffold(body: Text('Home')),
            ),
          );
          navigator.currentState!.push(
            PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const Scaffold(
                    extendBodyBehindAppBar: true,
                    appBar: GlassTopBar(title: title),
                    body: SizedBox.expand(),
                  ),
            ),
          );
          await tester.pumpAndSettle();

          final titleRect = tester.getRect(find.text(title));
          final buttonRect = tester.getRect(find.byType(GlassIconButton));
          expect(titleRect.overlaps(buttonRect), isFalse);
          expect(titleRect.left, greaterThanOrEqualTo(windowControlsInset));
          expect(titleRect.right, lessThanOrEqualTo(320 - windowControlsInset));
          expect(titleRect.center.dx, closeTo(160, 0.1));
          expect(tester.takeException(), isNull);

          await tester.tap(find.byType(GlassIconButton));
          await tester.pumpAndSettle();
          expect(find.text('Home'), findsOneWidget);
          expect(find.text(title), findsNothing);
        },
        variant: TargetPlatformVariant({
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }),
      );
    }
  }
}
