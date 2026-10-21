import 'package:bedug/core/design/liquid_glass.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'glass tabs match visible labels in $direction',
      (tester) async {
        var selected = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) => Stack(
                    children: [
                      GlassNavBar(
                        currentIndex: selected,
                        onTap: (index) => setState(() => selected = index),
                        items: const [
                          GlassNavItem(
                            icon: Icons.schedule,
                            activeIcon: Icons.schedule,
                            label: 'Prayers',
                          ),
                          GlassNavItem(
                            icon: Icons.mosque,
                            activeIcon: Icons.mosque,
                            label: 'Worship',
                          ),
                          GlassNavItem(
                            icon: Icons.settings,
                            activeIcon: Icons.settings,
                            label: 'Settings',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final isRtl = direction == TextDirection.rtl;
        final prayers = tester.getCenter(find.text('Prayers').first).dx;
        final settings = tester.getCenter(find.text('Settings').first).dx;
        expect(prayers < settings, !isRtl);
        for (final entry in [
          'Settings',
          'Worship',
          'Prayers',
        ].asMap().entries) {
          final index = 2 - entry.key;
          await tester.tap(find.text(entry.value).first);
          await tester.pumpAndSettle();
          expect(selected, index);
          final bar = tester.widget<LiquidGlassTabBar>(
            find.byType(LiquidGlassTabBar),
          );
          expect(
            Directionality.of(tester.element(find.byType(LiquidGlassTabBar))),
            TextDirection.ltr,
          );
          expect(bar.selectedIndex, isRtl ? 2 - index : index);
          expect(bar.items[bar.selectedIndex].label, entry.value);
          expect(tester.takeException(), isNull);
        }
      },
      variant: TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }),
    );
  }

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
