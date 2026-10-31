import 'package:bedug/core/design/liquid_glass.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:bedug/core/theme/app_tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:liquid_glass_easy/src/widgets/components/bottom_nav_bar/liquid_glass_nav_bar_motion_pill.dart';

void main() {
  testWidgets('glass tabs turn light over a dark backdrop only', (
    tester,
  ) async {
    Future<void> pumpBackdrop(double height) => tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: GlassNavBackdropScope(
            child: Stack(
              children: [
                GlassNavBackdropRegion(
                  color: const Color(0xFF000000),
                  active: true,
                  child: SizedBox(width: double.infinity, height: height),
                ),
                GlassNavBar(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Color settingsColor() =>
        tester.widget<Text>(find.text('Settings').first).style!.color!;
    Color pillColor() => tester
        .widget<LiquidGlassTabBar>(find.byType(LiquidGlassTabBar))
        .pillStyle
        .color;

    // The backdrop covers the whole screen, so the bar sits on it.
    await pumpBackdrop(600);
    await tester.pumpAndSettle();
    expect(settingsColor().computeLuminance(), greaterThan(0.5));
    expect(
      pillColor(),
      LiquidGlassTabPillStyle.defaultRestAdaptivity.glassColorOnDark,
    );

    // The backdrop ends above the bar, which is over the page again.
    await pumpBackdrop(100);
    await tester.pumpAndSettle();
    expect(settingsColor().computeLuminance(), lessThan(0.5));
    expect(pillColor(), const LiquidGlassTabPillStyle().color);
  });

  testWidgets('glass tabs follow a dark card as its list scrolls', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: GlassNavBackdropScope(
            child: Stack(
              children: [
                ListView(
                  controller: controller,
                  children: const [
                    // An inactive region, like the faded hero, mustn't hide
                    // the card's backdrop.
                    GlassNavBackdropRegion(
                      color: Color(0xFF000000),
                      active: false,
                      child: SizedBox(height: 100),
                    ),
                    // Puts the card at 520 to 580 on the 600 tall test
                    // screen, across the bar's center at 560.
                    SizedBox(height: 420),
                    GlassNavBackdropRegion(
                      color: Color(0xFF000000),
                      active: true,
                      child: SizedBox(height: 60),
                    ),
                    SizedBox(height: 1000),
                  ],
                ),
                GlassNavBar(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Color settingsColor() =>
        tester.widget<Text>(find.text('Settings').first).style!.color!;
    expect(settingsColor().computeLuminance(), greaterThan(0.5));

    // Scrolled up past the bar, the card no longer sits under it.
    controller.jumpTo(300);
    await tester.pumpAndSettle();
    expect(settingsColor().computeLuminance(), lessThan(0.5));
  });

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
    (const FakeViewPadding(left: 84, bottom: 34), true),
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
                            icon: Icons.mosque,
                            activeIcon: Icons.mosque,
                            label: 'Worship',
                          ),
                          GlassNavItem(
                            icon: Icons.menu_book,
                            activeIcon: Icons.menu_book,
                            label: 'Quran',
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

        expect(find.byType(LiquidGlassTabBar), findsOne);
        final bar = tester.widget<LiquidGlassTabBar>(
          find.byType(LiquidGlassTabBar),
        );
        // Both layouts use the package's refracting, morphing glass pill.
        expect(bar.glassPill, const LiquidGlassTabPillStyle().mode);
        if (!rail) return;
        final settings = find.byIcon(Icons.settings);
        // The rail sits in the side bar, under the right thumb.
        expect(
          tester.getCenter(settings).dx,
          padding.right > 0 ? greaterThan(466 - 84) : lessThan(84),
        );
        expect(
          tester.getCenter(find.byIcon(Icons.schedule)).dy,
          lessThan(tester.getCenter(settings).dy),
        );
        expect(bar.margin, EdgeInsets.zero);
        expect(bar.width, greaterThan(bar.height));
        final semantics = tester.ensureSemantics();
        expect(find.bySemanticsLabel('Settings'), findsWidgets);
        expect(GlassNavBar.occupiedHeight(barContext), 34);
        await tester.tap(settings);
        await tester.pumpAndSettle();
        expect(selected, 3);
        await tester.tap(find.byIcon(Icons.schedule));
        await tester.pumpAndSettle();
        expect(selected, 0);
        // Widget tests use Skia, where the standalone bar renders its
        // tap-only fallback. Exercise the real glass-pill pipeline used
        // by iPhone Duo explicitly, with the production rail configuration.
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: StatefulBuilder(
              builder: (context, setState) => Stack(
                children: [
                  Positioned(
                    bottom: 21,
                    left: padding.left > 0 ? 14 : null,
                    right: padding.right > 0 ? 14 : null,
                    width: bar.height,
                    height: bar.width,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child:
                          LiquidGlassTabBar(
                            items: bar.items,
                            selectedIndex: selected,
                            onChanged: (index) =>
                                setState(() => selected = index),
                            width: bar.width,
                            height: bar.height,
                            margin: EdgeInsets.zero,
                            itemPadding: bar.itemPadding,
                            alignment: Alignment.center,
                            style: bar.style,
                            itemStyle: bar.itemStyle,
                          ).buildGlassPillBar(
                            body: const SizedBox.expand(),
                            realTimeCapture: false,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        for (var frame = 0; frame < 60; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        // The package keeps the pill lifted under a held finger, then
        // commits the tab on release. Both immediate and held drags must
        // follow the vertical rail, including when reversing direction.
        final icons = [
          Icons.schedule,
          Icons.mosque,
          Icons.menu_book,
          Icons.settings,
        ];
        Future<void> advanceHeldAnimation() async {
          for (var frame = 0; frame < 30; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
        }

        for (final hold in [false, true]) {
          final gesture = await tester.startGesture(
            tester.getCenter(find.byIcon(icons.first).first),
          );
          final pillFinder = find.byType(LiquidGlassNavBarMotionPill);
          if (hold) {
            await advanceHeldAnimation();
            expect(selected, 0);
            final pill = tester.widget<LiquidGlassNavBarMotionPill>(pillFinder);
            expect(pill.active, isTrue);
            expect(pill.morphProgress, greaterThan(0.9));
          }
          for (final index in [1, 2, 3, 2, 1, 0, 1, 2, 3]) {
            final target = tester.getCenter(find.byIcon(icons[index]).first);
            await gesture.moveTo(target);
            await advanceHeldAnimation();
            final pill = tester.widget<LiquidGlassNavBarMotionPill>(pillFinder);
            expect(pill.active, isTrue);
            expect(pill.morphProgress, greaterThan(0.9));
            final box = tester.renderObject<RenderBox>(pillFinder);
            expect(box.localToGlobal(pill.center).dy, closeTo(target.dy, 3));
            expect(selected, 0);
          }
          await gesture.up();
          for (var frame = 0; frame < 60; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          expect(selected, 3);
          expect(pillFinder, findsNothing);
          await tester.tap(find.byIcon(icons.first).first);
          for (var frame = 0; frame < 60; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          expect(selected, 0);
        }
        semantics.dispose();
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  // iPhone Duo turned sideways. On the folded screen (678x466) the camera
  // sits at the bottom of a right-hand side bar and at the top of a
  // left-hand one; the larger unfolded screen keeps it, and the status
  // items, at the top.
  for (final (size, padding, cameraBelow) in [
    (const Size(678, 466), const FakeViewPadding(right: 84), true),
    (const Size(678, 466), const FakeViewPadding(left: 84), false),
    (const Size(1024, 720), const FakeViewPadding(right: 84), false),
  ]) {
    testWidgets('side bar rail keeps clear of the camera in $size with '
        'insets ${padding.left}/${padding.right}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = padding;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: Stack(
              children: [
                GlassNavBar(
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
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rail = tester.getRect(find.byType(LiquidGlassTabBar));
      expect(
        rail.center.dx,
        padding.right > 0 ? greaterThan(size.width - 84) : lessThan(84),
      );
      if (cameraBelow) {
        expect(rail.bottom, lessThan(size.height / 2));
      } else {
        expect(rail.top, greaterThan(size.height / 2));
      }
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      'short title sits beside the back button before several actions in '
      '$direction',
      (tester) async {
        tester.view.physicalSize = const Size(600, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            theme: buildAppTheme(Brightness.light),
            builder: (context, child) => AppThemeScope(
              child: Directionality(textDirection: direction, child: child!),
            ),
            home: const Scaffold(body: Text('Home')),
          ),
        );
        navigator.currentState!.push(
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
              extendBodyBehindAppBar: true,
              appBar: GlassTopBar(
                title: 'Al-Fatihah',
                actions: [
                  for (final icon in const [
                    Icons.menu_book,
                    Icons.text_decrease,
                    Icons.text_increase,
                  ])
                    GlassTopBarAction(
                      icon: icon,
                      tooltip: '',
                      onPressed: () {},
                    ),
                ],
              ),
              body: const SizedBox.expand(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final title = tester.getRect(find.text('Al-Fatihah'));
        final back = tester.getRect(find.byIcon(Icons.arrow_back_ios_new));
        // Only the back button's gap and the capsule's padding lie between.
        final gap = direction == TextDirection.ltr
            ? title.left - back.right
            : back.left - title.right;
        expect(gap, lessThan(AppControlSizes.toolbarButton));
        expect(gap, greaterThan(0));
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
          expect(titleRect.right, lessThanOrEqualTo(320 - AppSpacing.md));
          // Too long to center, it takes the room beside the back button
          // instead of the narrower centered capsule.
          const backSlot = AppControlSizes.toolbarButton + AppSpacing.xs;
          final centered =
              320 - 4 * AppSpacing.md - 2 * (windowControlsInset + backSlot);
          expect(titleRect.width, greaterThan(centered));
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
