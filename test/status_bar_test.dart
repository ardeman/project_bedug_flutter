import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'status icons follow the app theme on launch and after leaving the hero',
    (tester) async {
      var brightness = Brightness.light;
      var showHero = false;
      // A saved light theme must win even when the device itself is dark.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      late StateSetter update;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MaterialApp(
              theme: buildAppTheme(brightness),
              builder: (context, child) => AppThemeScope(child: child!),
              home: showHero
                  ? const AnnotatedRegion<SystemUiOverlayStyle>(
                      value: SystemUiOverlayStyle.light,
                      child: SizedBox.expand(),
                    )
                  : const SizedBox.expand(),
            );
          },
        ),
      );

      SystemUiOverlayStyle? styleAt(Offset point) => tester
          .binding
          .renderViews
          .single
          .debugLayer!
          .find<SystemUiOverlayStyle>(point);

      void expectStyle(SystemUiOverlayStyle expected) {
        // Both the usual top bar and a foldable phone's side status area.
        for (final point in [const Offset(200, 10), const Offset(790, 300)]) {
          final style = styleAt(point)!;
          expect(style.statusBarBrightness, expected.statusBarBrightness);
          expect(
            style.statusBarIconBrightness,
            expected.statusBarIconBrightness,
          );
        }
      }

      expectStyle(SystemUiOverlayStyle.dark);
      update(() => showHero = true);
      await tester.pumpAndSettle();
      expectStyle(SystemUiOverlayStyle.light);
      update(() => showHero = false);
      await tester.pumpAndSettle();
      expectStyle(SystemUiOverlayStyle.dark);
      update(() => brightness = Brightness.dark);
      await tester.pumpAndSettle();
      expectStyle(SystemUiOverlayStyle.light);
      update(() => brightness = Brightness.light);
      await tester.pumpAndSettle();
      expectStyle(SystemUiOverlayStyle.dark);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );
}
