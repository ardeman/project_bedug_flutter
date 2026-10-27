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

  for (final (size, compact) in [
    (const Size(402, 874), false),
    (const Size(874, 402), true),
  ]) {
    testWidgets(
      'glass tabs are ${compact ? '' : 'not '}compact in a $size window',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(bottom: compact ? 21 : 34);
        addTearDown(tester.view.reset);
        late BuildContext barContext;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: Scaffold(
              body: Stack(
                children: [
                  Builder(
                    builder: (context) {
                      barContext = context;
                      return GlassNavBar(
                        currentIndex: 0,
                        onTap: (_) {},
                        items: const [
                          GlassNavItem(
                            icon: Icons.schedule,
                            activeIcon: Icons.schedule,
                            label: 'Prayers',
                          ),
                          GlassNavItem(
                            icon: Icons.settings,
                            activeIcon: Icons.settings,
                            label: 'Settings',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final bar = tester.widget<LiquidGlassTabBar>(
          find.byType(LiquidGlassTabBar),
        );
        expect(
          bar.height,
          compact ? GlassNavBar.compactHeight : GlassNavBar.height,
        );
        final occupied = GlassNavBar.occupiedHeight(barContext);
        // The page's bottom padding covers the bar and its margin.
        expect(occupied, greaterThanOrEqualTo(bar.height + bar.margin.bottom));
        if (compact) expect(occupied, lessThan(size.height / 5));
        expect(find.text('Settings'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  for (final (padding, rail) in [
    // iPhone Duo: the system's vertical bar takes the right side.
    (const FakeViewPadding(right: 84, bottom: 34), true),
    // Other iPhones in landscape inset both sides alike.
    (const FakeViewPadding(left: 59, right: 59, bottom: 21), false),
  ]) {
    testWidgets(
      'glass tabs ${rail ? 'move into' : 'stay out of'} a side bar with '
      'insets ${padding.left}/${padding.right}',
      (tester) async {
        tester.view.physicalSize = const Size(466, 678);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = padding;
        addTearDown(tester.view.reset);
        var selected = 0;
        late BuildContext barContext;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  barContext = context;
                  return Stack(
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
                            icon: Icons.settings,
                            activeIcon: Icons.settings,
                            label: 'Settings',
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LiquidGlassTabBar), rail ? findsNothing : findsOne);
        if (!rail) return;
        final settings = find.byIcon(Icons.settings);
        // The rail sits in the side bar, under the right thumb.
        expect(tester.getCenter(settings).dx, greaterThan(466 - 84));
        expect(GlassNavBar.occupiedHeight(barContext), 34);
        await tester.tap(settings);
        await tester.pumpAndSettle();
        expect(selected, 1);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
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
