import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/utils/qibla_utils.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Within this many degrees of the Qibla the user counts as facing it.
const double _facingToleranceDeg = 3;

/// Within this many degrees of the sun (or of directly away from it) the hint
/// says "toward" / "away" instead of a left/right angle.
const double _sunAlignedToleranceDeg = 5;

/// Heading error (degrees) above which the user is asked to calibrate.
const double _poorAccuracyDeg = 30;

/// Qibla direction card: a compass dial that turns with the device heading on
/// phones, and stays north-up with text guidance on desktops.
class QiblaCard extends ConsumerStatefulWidget {
  const QiblaCard({super.key});

  @override
  ConsumerState<QiblaCard> createState() => _QiblaCardState();
}

class _QiblaCardState extends ConsumerState<QiblaCard> {
  StreamSubscription<CompassEvent>? _compassSub;
  Timer? _sunTimer;
  double? _heading;
  double? _accuracy;

  /// Only phones have a heading sensor plugin; desktops stay north-up.
  static bool get _hasCompassPlugin =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  @override
  void initState() {
    super.initState();
    if (_hasCompassPlugin) {
      _compassSub = FlutterCompass.events?.listen(
        (e) => setState(() {
          _heading = e.heading;
          _accuracy = e.accuracy;
        }),
        onError: (_) => setState(() => _heading = null),
      );
    }
    // The sun moves about 1° every 4 minutes; refresh the hint each minute.
    _sunTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
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
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.qiblaNoLocation, textAlign: TextAlign.center),
            );
    } else {
      content = _buildQibla(ctx, l10n, coords, prayer.locationLabel);
    }

    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
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
    final facing = heading != null &&
        relativeAngle(heading, bearing).abs() <= _facingToleranceDeg;

    final direction = _directionName(l10n, compassPointIndex(bearing));
    final km = NumberFormat.decimalPattern(localeName)
        .format(distanceToKaabaKm(coords).round());
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          Text(
            l10n.qibla,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (locationLabel != null) ...[
            const SizedBox(height: 4),
            Text(locationLabel, style: muted, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: AspectRatio(
              aspectRatio: 1,
              child: _QiblaDial(
                bearing: bearing,
                heading: heading ?? 0,
                highlight: facing,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.qiblaBearing(bearing.round().toString(), direction),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(l10n.qiblaDistance(km), style: muted),
          const SizedBox(height: 16),
          if (heading != null) ...[
            Text(
              facing ? l10n.qiblaFacing : l10n.qiblaRotateHint,
              textAlign: TextAlign.center,
              style: facing
                  ? theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.bold,
                    )
                  : null,
            ),
            if ((_accuracy ?? 0) > _poorAccuracyDeg) ...[
              const SizedBox(height: 8),
              Text(l10n.qiblaCalibrate,
                  style: muted, textAlign: TextAlign.center),
            ],
          ] else ...[
            Text(l10n.qiblaFaceNorthHint, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              l10n.qiblaFindNorthHint,
              style: muted,
              textAlign: TextAlign.center,
            ),
            ..._buildSunHint(l10n, theme, coords, bearing),
          ],
        ],
      ),
    );
  }

  /// "The Qibla is N° left/right of the sun", shown while the sun is up.
  List<Widget> _buildSunHint(
    AppLocalizations l10n,
    ThemeData theme,
    Coordinates coords,
    double bearing,
  ) {
    final sun = sunPosition(DateTime.now(), coords);
    if (!sun.isUsable) return const [];

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

    return [
      const SizedBox(height: 16),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_outlined, color: AppColors.gold),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    ];
  }

  String _directionName(AppLocalizations l10n, int index) => switch (index) {
        0 => l10n.dirN,
        1 => l10n.dirNE,
        2 => l10n.dirE,
        3 => l10n.dirSE,
        4 => l10n.dirS,
        5 => l10n.dirSW,
        6 => l10n.dirW,
        _ => l10n.dirNW,
      };
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
    return Transform.rotate(
      angle: -heading * math.pi / 180,
      child: CustomPaint(
        painter: _DialPainter(
          bearing: bearing,
          tickColor: scheme.onSurfaceVariant,
          ringColor: highlight ? AppColors.emerald : scheme.outlineVariant,
          northColor: scheme.error,
        ),
        child: Center(
          child: Transform.rotate(
            // Keep the centre icon upright while the dial turns.
            angle: heading * math.pi / 180,
            child: Icon(
              Icons.mosque,
              size: 36,
              color: highlight ? AppColors.emerald : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double bearing;
  final Color tickColor;
  final Color ringColor;
  final Color northColor;

  _DialPainter({
    required this.bearing,
    required this.tickColor,
    required this.ringColor,
    required this.northColor,
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
        ..strokeWidth = 3
        ..color = ringColor,
    );

    // A tick every 15°, longer and thicker on the cardinal points.
    final tick = Paint()..color = tickColor;
    for (var deg = 0; deg < 360; deg += 15) {
      final cardinal = deg % 90 == 0;
      tick.strokeWidth = cardinal ? 3 : 1.5;
      final dir = _unit(deg.toDouble());
      final outer = radius - 8;
      final inner = outer - (cardinal ? 16 : 8);
      canvas.drawLine(center + dir * inner, center + dir * outer, tick);
    }

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
      ..color = AppColors.emerald
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, tip - dir * 14, arrow);
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
          (tip - dir * 22 + normal * 12).dx, (tip - dir * 22 + normal * 12).dy)
      ..lineTo(
          (tip - dir * 22 - normal * 12).dx, (tip - dir * 22 - normal * 12).dy)
      ..close();
    canvas.drawPath(head, Paint()..color = AppColors.emerald);
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
      old.northColor != northColor;
}
