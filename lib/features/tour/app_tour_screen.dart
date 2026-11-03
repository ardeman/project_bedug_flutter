import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/material_controls.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'tour_targets.dart';

/// One spotlight and an explanation beside the actual control, as in the
/// Catat Saja and Coba Lagi screen guides.
class AppTourOverlay extends StatefulWidget {
  const AppTourOverlay({
    super.key,
    required this.step,
    required this.onNext,
    required this.onBack,
    required this.onFinish,
    required this.anchors,
  });

  final int step;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final TourAnchors anchors;

  @override
  State<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends State<AppTourOverlay> {
  Rect? _target;
  Rect? _navigationRect;
  int _generation = 0;
  bool _forward = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleTarget();
  }

  @override
  void didUpdateWidget(AppTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step != oldWidget.step) {
      _forward = widget.step > oldWidget.step;
      _scheduleTarget();
    }
  }

  void _scheduleTarget() {
    final generation = ++_generation;
    _target = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare(generation));
  }

  Rect? _rectOf(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null || !targetContext.mounted) return null;
    final box = targetContext.findRenderObject();
    final overlay = context.findRenderObject();
    if (box is! RenderBox ||
        !box.hasSize ||
        !box.attached ||
        overlay is! RenderBox) {
      return null;
    }
    return box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  }

  Future<void> _layout() async {
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
  }

  void _skipUnavailable() {
    if (_forward && widget.step < tourStops.length - 1) {
      widget.onNext();
    } else if (!_forward && widget.step > 0) {
      widget.onBack();
    } else {
      widget.onFinish();
    }
  }

  Future<void> _prepare(int generation) async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stop = tourStops[widget.step];
    final key = widget.anchors.keys[stop.control]!;
    final controller = widget.anchors.scrollControllers[stop.tab];
    bool current() => mounted && generation == _generation;
    // Lazy lists may not have built the control yet. Search their viewport,
    // then let ensureVisible place the actual control rather than guessing.
    if (key.currentContext == null && controller.hasClients) {
      controller.jumpTo(controller.position.minScrollExtent);
      await _layout();
      for (
        var attempt = 0;
        current() && key.currentContext == null && attempt < 20;
        attempt++
      ) {
        final position = controller.position;
        final next = math.min(
          position.maxScrollExtent,
          position.pixels + position.viewportDimension * 0.6,
        );
        if (next <= position.pixels) break;
        controller.jumpTo(next);
        await _layout();
      }
    }
    if (!current()) return;
    final targetContext = key.currentContext;
    if (targetContext == null) {
      // Optional/loading controls are left out, as in the reference guides.
      _skipUnavailable();
      return;
    }
    if (!targetContext.mounted) return;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.5,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 250),
    );
    if (!current()) return;
    final rect = _rectOf(key);
    if (rect == null) {
      _skipUnavailable();
      return;
    }
    final navigationRect = _rectOf(
      widget.anchors.keys[TourControl.navigation]!,
    );
    setState(() {
      _target = rect;
      _navigationRect = navigationRect;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final control = tourStops[widget.step].control;
    final (title, body) = switch (control) {
      TourControl.navigation => (l10n.appTour, l10n.guideNavigation),
      TourControl.calendar => (l10n.prayerTimes, l10n.guideCalendar),
      TourControl.qibla => (l10n.worship, l10n.guideQibla),
      TourControl.dzikir => (l10n.dzikir, l10n.guideDzikir),
      TourControl.fasting => (l10n.fastingLog, l10n.guideFasting),
      TourControl.quranPlan => (l10n.quran, l10n.guideQuranPlan),
      TourControl.quranBrowse => (l10n.quran, l10n.guideQuranBrowse),
      TourControl.calculation => (
        l10n.calculationMethod,
        l10n.guideCalculation,
      ),
      TourControl.notifications => (
        l10n.notifications,
        l10n.guideNotifications,
      ),
      TourControl.location => (l10n.locationModeAuto, l10n.guideLocation),
      TourControl.language => (l10n.language, l10n.guideLanguage),
      TourControl.replay => (l10n.appTour, l10n.guideReplay),
    };
    final last = widget.step == tourStops.length - 1;
    final target = _target;
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final nav = _navigationRect;
    final bottom =
        nav != null &&
            control != TourControl.navigation &&
            nav.width > nav.height
        ? math.min(size.height - padding.bottom, nav.top)
        : size.height - padding.bottom;
    final bounds = Rect.fromLTRB(
      AppSpacing.md + padding.left,
      AppSpacing.md + padding.top,
      size.width - padding.right - AppSpacing.md,
      bottom - AppSpacing.md,
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onFinish,
        const SingleActivator(LogicalKeyboardKey.arrowRight): last
            ? widget.onFinish
            : widget.onNext,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): widget.step > 0
            ? widget.onBack
            : () {},
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            if (widget.step > 0) {
              widget.onBack();
            } else {
              widget.onFinish();
            }
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: target == null
                    ? null
                    : last
                    ? widget.onFinish
                    : widget.onNext,
                child: CustomPaint(
                  painter: _TourScrim(
                    target,
                    theme.colorScheme.scrim.withValues(alpha: 0.55),
                    AppColors.accentOf(context),
                  ),
                ),
              ),
            ),
            if (target != null)
              CustomSingleChildLayout(
                delegate: _BubbleLayout(target.inflate(AppSpacing.xs), bounds),
                child: Semantics(
                  scopesRoute: true,
                  explicitChildNodes: true,
                  child: Focus(
                    autofocus: true,
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      child: SingleChildScrollView(
                        key: ValueKey(widget.step),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              l10n.tourProgress(
                                widget.step + 1,
                                tourStops.length,
                              ),
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                body,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                if (!last)
                                  _TourButton(
                                    label: l10n.tourSkip,
                                    icon: Icons.close,
                                    onPressed: widget.onFinish,
                                  ),
                                if (widget.step > 0)
                                  _TourButton(
                                    label: l10n.tourBack,
                                    icon: Icons.arrow_back,
                                    onPressed: widget.onBack,
                                  ),
                                _TourButton(
                                  label: last ? l10n.tourDone : l10n.tourNext,
                                  icon: last
                                      ? Icons.check
                                      : Icons.arrow_forward,
                                  filled: true,
                                  onPressed: last
                                      ? widget.onFinish
                                      : widget.onNext,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Keep the bubble beside its control, choosing room above, below or beside
/// a rail. Large text can scroll inside the available region.
class _BubbleLayout extends SingleChildLayoutDelegate {
  const _BubbleLayout(this.target, this.bounds);
  final Rect target;
  final Rect bounds;

  Rect get _region {
    const gap = AppSpacing.sm;
    final regions = [
      Rect.fromLTRB(
        bounds.left,
        math.max(bounds.top, target.bottom + gap),
        bounds.right,
        bounds.bottom,
      ),
      Rect.fromLTRB(
        bounds.left,
        bounds.top,
        bounds.right,
        math.min(bounds.bottom, target.top - gap),
      ),
      Rect.fromLTRB(
        math.max(bounds.left, target.right + gap),
        bounds.top,
        bounds.right,
        bounds.bottom,
      ),
      Rect.fromLTRB(
        bounds.left,
        bounds.top,
        math.min(bounds.right, target.left - gap),
        bounds.bottom,
      ),
    ];
    final usable = regions
        .where((r) => r.width >= math.min(240, bounds.width) && r.height >= 100)
        .toList();
    if (usable.isEmpty) return bounds;
    // Prefer a nearby vertical bubble when it fits a compact explanation.
    for (final r in usable.take(2)) {
      if (r.height >= 230) return r;
    }
    usable.sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    return usable.first;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.min(360, _region.width),
        maxHeight: _region.height,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final region = _region;
    final x = (target.center.dx - childSize.width / 2).clamp(
      region.left,
      region.right - childSize.width,
    );
    final below = region.top >= target.bottom;
    final y = below
        ? region.top
        : math.max(region.top, region.bottom - childSize.height);
    return Offset(x.toDouble(), y);
  }

  @override
  bool shouldRelayout(_BubbleLayout oldDelegate) =>
      target != oldDelegate.target || bounds != oldDelegate.bounds;
}

class _TourButton extends StatelessWidget {
  const _TourButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (!PlatformCapabilities.isApple) {
      return MaterialLabelButton(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        filled: filled,
      );
    }
    // These controls scroll with the introduction, so use lite glass.
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: GlassCard(
        margin: EdgeInsets.zero,
        child: GlassPressable(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: filled ? AppColors.accentOf(context) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TourScrim extends CustomPainter {
  const _TourScrim(this.target, this.color, this.accent);
  final Rect? target;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    final rect = target;
    if (rect == null) {
      canvas.drawPath(path, Paint()..color = color);
      return;
    }
    final hole = RRect.fromRectAndRadius(
      rect.inflate(AppSpacing.xs),
      const Radius.circular(AppRadii.md),
    );
    path.addRRect(hole);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawRRect(
      hole,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TourScrim oldDelegate) =>
      target != oldDelegate.target ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
}
