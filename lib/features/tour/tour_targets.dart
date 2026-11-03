import 'package:material_ui/material_ui.dart';

enum TourControl {
  navigation,
  calendar,
  qibla,
  dzikir,
  fasting,
  quranPlan,
  quranBrowse,
  calculation,
  notifications,
  location,
  language,
  replay,
}

const tourStops = <({int tab, TourControl control})>[
  (tab: 0, control: TourControl.navigation),
  (tab: 0, control: TourControl.calendar),
  (tab: 1, control: TourControl.qibla),
  (tab: 1, control: TourControl.dzikir),
  (tab: 1, control: TourControl.fasting),
  (tab: 2, control: TourControl.quranPlan),
  (tab: 2, control: TourControl.quranBrowse),
  (tab: 3, control: TourControl.calculation),
  (tab: 3, control: TourControl.notifications),
  (tab: 3, control: TourControl.location),
  (tab: 3, control: TourControl.language),
  (tab: 3, control: TourControl.replay),
];

/// Owned by Home, never shared across windows or widget trees.
class TourAnchors {
  final keys = {for (final control in TourControl.values) control: GlobalKey()};
  final scrollControllers = List.generate(4, (_) => ScrollController());

  void dispose() {
    for (final controller in scrollControllers) {
      controller.dispose();
    }
  }
}

class TourAnchorScope extends InheritedWidget {
  const TourAnchorScope({
    super.key,
    required this.anchors,
    required super.child,
  });
  final TourAnchors anchors;

  static TourAnchors? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TourAnchorScope>()?.anchors;

  @override
  bool updateShouldNotify(TourAnchorScope oldWidget) =>
      anchors != oldWidget.anchors;
}

/// A real control's marker; screens still work outside the home tour.
class TourTarget extends StatelessWidget {
  const TourTarget({super.key, required this.control, required this.child});
  final TourControl control;
  final Widget child;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: TourAnchorScope.maybeOf(context)?.keys[control],
    child: child,
  );
}
