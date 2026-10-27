import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/design/glass_controls.dart';
import '../../../core/design/liquid_glass.dart';
import '../../../core/design/platform_capabilities.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/selection_feedback.dart';
import '../../../core/utils/qibla_utils.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Within this many degrees of the Qibla the user counts as facing it.
const double _facingToleranceDeg = 3;

/// Move clearly outside the alignment zone before another tick is allowed.
const double _feedbackResetToleranceDeg = 6;

/// Desktop devices have no compass sensor; keep their dial north-up.
final compassEventsProvider = Provider<Stream<CompassEvent>>((ref) {
  if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) {
    return const Stream.empty();
  }
  return FlutterCompass.events ?? const Stream.empty();
});

/// Within this many degrees of the sun (or of directly away from it) the hint
/// says "toward" / "away" instead of a left/right angle.
const double _sunAlignedToleranceDeg = 5;

/// Heading error (degrees) above which the user is asked to calibrate.
const double _poorAccuracyDeg = 30;

/// Keeps guide lines to a comfortable reading length on wide windows.
const double _guideMaxWidth = 360;

/// Qibla direction card: a compass dial that turns with the device heading on
/// phones, and stays north-up with text guidance on desktops.
class QiblaCard extends ConsumerStatefulWidget {
  const QiblaCard({super.key, this.feedbackEnabled = true});

  final bool feedbackEnabled;

  @override
  ConsumerState<QiblaCard> createState() => _QiblaCardState();
}

class _QiblaCardState extends ConsumerState<QiblaCard> {
  StreamSubscription<CompassEvent>? _compassSub;
  Timer? _sunTimer;
  double? _heading;
  double? _accuracy;

  bool _alignmentFeedbackSent = false;

  @override
  void initState() {
    super.initState();
    _compassSub = ref
        .read(compassEventsProvider)
        .listen(
          _onCompassEvent,
          onError: (_) {
            _alignmentFeedbackSent = false;
            setState(() => _heading = null);
          },
        );
    // The sun moves about 1° every 4 minutes; refresh the hint each minute.
    _sunTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  void _onCompassEvent(CompassEvent event) {
    setState(() {
      _heading = event.heading;
      _accuracy = event.accuracy;
    });

    final coords = ref.read(prayerProvider).times?.coordinates;
    final heading = event.heading;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!widget.feedbackEnabled ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed) ||
        ModalRoute.of(context)?.isCurrent == false ||
        coords == null ||
        heading == null ||
        !heading.isFinite) {
      _alignmentFeedbackSent = false;
      return;
    }

    final error = relativeAngle(heading, qiblaBearing(coords)).abs();
    if (error > _feedbackResetToleranceDeg) {
      _alignmentFeedbackSent = false;
    } else if (error <= _facingToleranceDeg && !_alignmentFeedbackSent) {
      _alignmentFeedbackSent = true;
      SelectionFeedback.tick();
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _sunTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final prayer = ref.watch(prayerProvider);
    final coords = prayer.times?.coordinates;

    final Widget content;
    if (coords == null) {
      content = prayer.loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: AdaptiveSpinner()),
            )
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.qiblaNoLocation,
                style: Theme.of(ctx).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            );
    } else {
      return _buildQibla(ctx, l10n, coords, prayer.locationLabel);
    }

    return GlassCard(child: content);
  }

  Widget _buildQibla(
    BuildContext ctx,
    AppLocalizations l10n,
    Coordinates coords,
    String? locationLabel,
  ) {
    final theme = Theme.of(ctx);
    final localeName = Localizations.localeOf(ctx).toString();
    final bearing = qiblaBearing(coords);
    final heading = _heading;
    final facing =
        heading != null &&
        relativeAngle(heading, bearing).abs() <= _facingToleranceDeg;

    final fromNorth = angleFromNorth(bearing);
    // West of north, also give the compass bearing that phone compasses show.
    final bearingLabel = fromNorth >= 0
        ? l10n.qiblaBearingEast(fromNorth.toString())
        : l10n.qiblaBearingWest(
            (360 + fromNorth).toString(),
            (-fromNorth).toString(),
          );
    final km = NumberFormat.decimalPattern(localeName)
        .format(distanceToKaabaKm(coords).round());
    // Short windows need smaller secondary text and tighter card spacing.
    final compact = MediaQuery.sizeOf(ctx).height < 600;
    final bodyStyle = compact
        ? theme.textTheme.bodySmall
        : theme.textTheme.bodyMedium;
    final muted = bodyStyle?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final accent = AppColors.accentOf(ctx);
    // Keep the dial proportional to short screens, leaving room for guidance
    // and the floating navigation bar. Large text can still scroll naturally.
    final dialSize = (MediaQuery.sizeOf(ctx).height * (compact ? 0.20 : 0.27))
        .clamp(112.0, 240.0);
    return GlassCard(
      margin: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xxs,
              children: [
                Text(
                  l10n.qibla,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (locationLabel != null)
                  Text(
                    locationLabel,
                    style: muted,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialSize),
              child: AspectRatio(
                aspectRatio: 1,
                child: _QiblaDial(
                  bearing: bearing,
                  heading: heading ?? 0,
                  highlight: facing,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              bearingLabel,
              style: theme.textTheme.titleSmall?.copyWith(color: accent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.qiblaDistance(km),
              style: muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            // The guide lines share one start-aligned column so wrapped
            // translations stay readable; the column itself stays centered.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _guideMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GuideLine(
                    icon: facing
                        ? Icons.check_circle_outline
                        : Icons.explore_outlined,
                    iconColor: accent,
                    text: heading == null
                        ? l10n.qiblaFaceNorthHint
                        : facing
                        ? l10n.qiblaFacing
                        : l10n.qiblaRotateHint,
                    style: bodyStyle?.copyWith(
                      color: facing ? accent : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (heading == null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _GuideLine(
                      icon: Icons.map_outlined,
                      iconColor: theme.colorScheme.onSurfaceVariant,
                      text: l10n.qiblaFindNorthHint,
                      style: muted,
                    ),
                    ?_buildSunHint(l10n, theme, coords, bearing, bodyStyle),
                  ] else if ((_accuracy ?? 0) > _poorAccuracyDeg) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _GuideLine(
                      icon: Icons.all_inclusive,
                      iconColor: theme.colorScheme.onSurfaceVariant,
                      text: l10n.qiblaCalibrate,
                      style: muted,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "The Qibla is N° left/right of the sun", shown while the sun is up.
  Widget? _buildSunHint(
    AppLocalizations l10n,
    ThemeData theme,
    Coordinates coords,
    double bearing,
    TextStyle? style,
  ) {
    final sun = sunPosition(DateTime.now(), coords);
    if (!sun.isUsable) return null;

    final rel = relativeAngle(sun.azimuth, bearing);
    final degrees = rel.abs().round().toString();
    final String text;
    if (rel.abs() <= _sunAlignedToleranceDeg) {
      text = l10n.qiblaSunAhead;
    } else if (rel.abs() >= 180 - _sunAlignedToleranceDeg) {
      text = l10n.qiblaSunBehind;
    } else if (rel < 0) {
      text = l10n.qiblaSunLeft(degrees);
    } else {
      text = l10n.qiblaSunRight(degrees);
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: _GuideLine(
        icon: Icons.wb_sunny_outlined,
        iconColor: theme.colorScheme.tertiary,
        text: text,
        style: style,
      ),
    );
  }
}

/// One guide step: an icon beside text that may wrap over several lines.
class _GuideLine extends StatelessWidget {
  const _GuideLine({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.style,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext ctx) {
    final resolved = DefaultTextStyle.of(ctx).style.merge(style);
    // Center the icon on the first line rather than on the whole paragraph,
    // so it stays beside the start of a wrapped hint.
    final fontSize = MediaQuery.textScalerOf(ctx)
        .scale(resolved.fontSize ?? AppControlSizes.toolbarIcon);
    final textLineHeight = fontSize * (resolved.height ?? 1.2);
    final firstLineHeight = math.max(
      textLineHeight,
      AppControlSizes.toolbarIcon,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: firstLineHeight,
          child: Icon(
            icon,
            color: iconColor,
            size: AppControlSizes.toolbarIcon,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Padding(
            // Line the text's first line up with the icon when the icon is
            // taller than the text.
            padding: EdgeInsets.only(
              top: (firstLineHeight - textLineHeight) / 2,
            ),
            child: Text(text, style: style),
          ),
        ),
      ],
    );
  }
}

/// Compass rose turned by -[heading] so north tracks the real north, with an
/// arrow at [bearing] pointing to the Kaaba.
class _QiblaDial extends StatelessWidget {
  final double bearing;
  final double heading;
  final bool highlight;

  const _QiblaDial({
    required this.bearing,
    required this.heading,
    required this.highlight,
  });

  @override
  Widget build(BuildContext ctx) {
    final scheme = Theme.of(ctx).colorScheme;
    final accent = AppColors.accentOf(ctx);
    final center = Center(
      child: Icon(
        Icons.my_location,
        key: const ValueKey('qibla-device-marker'),
        size: AppControlSizes.navigationIcon,
        color: highlight ? accent : scheme.onSurface,
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: highlight ? 0.20 : 0.10),
            AppColors.secondaryOf(ctx).withValues(alpha: 0.04),
            accent.withValues(alpha: 0.08),
          ],
          stops: const [0, 0.72, 1],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Transform.rotate(
              angle: -heading * math.pi / 180,
              child: CustomPaint(
                painter: _DialPainter(
                  bearing: bearing,
                  tickColor: scheme.onSurfaceVariant,
                  ringColor: highlight ? accent : scheme.outlineVariant,
                  northColor: scheme.error,
                  arrowColor: accent,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final diameter = constraints.maxWidth;
                final angle = (bearing - heading) * math.pi / 180;
                // Keep the destination on the arrow shaft, clear of its tip
                // and the device marker. The Kaaba stays upright as you turn.
                final markerSize = diameter * 0.18;
                final offset =
                    Offset(math.sin(angle), -math.cos(angle)) *
                    (diameter / 2 * 0.56);
                return Stack(
                  children: [
                    Positioned(
                      left: diameter / 2 + offset.dx - markerSize / 2,
                      top: diameter / 2 + offset.dy - markerSize / 2,
                      width: markerSize,
                      height: markerSize,
                      child: Semantics(
                        label: AppLocalizations.of(ctx).qibla,
                        image: true,
                        child: DecoratedBox(
                          key: const ValueKey('qibla-kaaba-marker'),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.surface,
                            border: Border.all(color: accent),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxs),
                            child: CustomPaint(
                              painter: _KaabaPainter(
                                gold: Theme.of(ctx).colorScheme.tertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          FractionallySizedBox(
            widthFactor: 0.27,
            heightFactor: 0.27,
            child: PlatformCapabilities.isApple
                ? LiquidGlassLite(
                    shape: const LiquidGlassShape.continuousRoundedRectangle(
                      cornerRadius: AppRadii.lg,
                    ),
                    color: glassTintOf(ctx),
                    child: center,
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceContainerHighest,
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: center,
                  ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double bearing;
  final Color tickColor;
  final Color ringColor;
  final Color northColor;
  final Color arrowColor;

  _DialPainter({
    required this.bearing,
    required this.tickColor,
    required this.ringColor,
    required this.northColor,
    required this.arrowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ringColor,
    );

    // Fine five-degree graduations, with longer marks every thirty degrees.
    final tick = Paint()..color = tickColor;
    for (var deg = 0; deg < 360; deg += 5) {
      final cardinal = deg % 90 == 0;
      final major = deg % 30 == 0;
      tick
        ..strokeWidth = cardinal ? 2.5 : 1
        ..color = tickColor.withValues(alpha: major ? 0.8 : 0.3);
      final dir = _unit(deg.toDouble());
      final outer = radius - 12;
      final inner =
          outer -
          (cardinal
              ? 20
              : major
              ? 12
              : 6);
      canvas.drawLine(center + dir * inner, center + dir * outer, tick);
    }

    canvas.drawCircle(
      center,
      radius * 0.67,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ringColor.withValues(alpha: 0.45),
    );

    // North marker: a triangle at the top of the rose.
    final north = Path()
      ..moveTo(center.dx, center.dy - radius + 6)
      ..lineTo(center.dx - 9, center.dy - radius + 26)
      ..lineTo(center.dx + 9, center.dy - radius + 26)
      ..close();
    canvas.drawPath(north, Paint()..color = northColor);

    // Qibla arrow from the centre icon's edge to just inside the ticks.
    final dir = _unit(bearing);
    final normal = Offset(-dir.dy, dir.dx);
    final start = center + dir * (radius * 0.28);
    final tip = center + dir * (radius - 30);
    final arrow = Paint()
      ..color = arrowColor
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, tip - dir * 14, arrow);
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        (tip - dir * 22 + normal * 12).dx,
        (tip - dir * 22 + normal * 12).dy,
      )
      ..lineTo(
        (tip - dir * 22 - normal * 12).dx,
        (tip - dir * 22 - normal * 12).dy,
      )
      ..close();
    canvas.drawPath(head, Paint()..color = arrowColor);
  }

  /// Unit vector for a compass bearing (0 = up, clockwise).
  Offset _unit(double deg) {
    final rad = deg * math.pi / 180;
    return Offset(math.sin(rad), -math.cos(rad));
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.bearing != bearing ||
      old.tickColor != tickColor ||
      old.ringColor != ringColor ||
      old.northColor != northColor ||
      old.arrowColor != arrowColor;
}

/// A small vector Kaaba, with the gold kiswa band and a visible door.
/// Normalized coordinates keep it sharp at every compass size.
class _KaabaPainter extends CustomPainter {
  const _KaabaPainter({required this.gold});

  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 40, size.height / 40);
    final body = Paint()..color = AppColors.darkBg;
    final trim = Paint()..color = gold;
    final roof = Path()
      ..moveTo(5, 10)
      ..lineTo(15, 7)
      ..lineTo(35, 11)
      ..lineTo(25, 14)
      ..close();
    canvas.drawPath(roof, Paint()..color = AppColors.darkSurface);
    final front = Path()
      ..moveTo(5, 10)
      ..lineTo(25, 14)
      ..lineTo(25, 35)
      ..lineTo(5, 31)
      ..close();
    final side = Path()
      ..moveTo(25, 14)
      ..lineTo(35, 11)
      ..lineTo(35, 31)
      ..lineTo(25, 35)
      ..close();
    canvas.drawPath(front, body);
    canvas.drawPath(side, Paint()..color = AppColors.darkSurface);
    final band = Path()
      ..moveTo(5, 15)
      ..lineTo(25, 19)
      ..lineTo(35, 16)
      ..lineTo(35, 20)
      ..lineTo(25, 23)
      ..lineTo(5, 19)
      ..close();
    canvas.drawPath(band, trim);
    final door = Path()
      ..moveTo(18, 24)
      ..lineTo(23, 25)
      ..lineTo(23, 34)
      ..lineTo(18, 33)
      ..close();
    canvas.drawPath(door, trim);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KaabaPainter oldDelegate) => oldDelegate.gold != gold;
}
