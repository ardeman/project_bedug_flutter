import 'package:flutter/material.dart';
import '../../../core/design/platform_design.dart';
import '../../../core/design/liquid_glass.dart';

/// Card waktu sholat — adaptive berdasarkan platform
class PrayerTimeCard extends StatelessWidget {
  final String prayerName;
  final String time;
  final bool isNext;
  final bool isActive;
  final VoidCallback? onTap;

  const PrayerTimeCard({
    super.key,
    required this.prayerName,
    required this.time,
    this.isNext = false,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    return switch (PlatformDesign.current) {
      DesignSystem.liquidGlass => _AppleCard(
          prayerName: prayerName,
          time: time,
          isNext: isNext,
          isActive: isActive,
          onTap: onTap,
        ),
      DesignSystem.fluentDesign => _FluentCard(
          prayerName: prayerName,
          time: time,
          isNext: isNext,
          isActive: isActive,
          onTap: onTap,
        ),
      DesignSystem.materialYou => _MaterialCard(
          prayerName: prayerName,
          time: time,
          isNext: isNext,
          isActive: isActive,
          onTap: onTap,
        ),
    };
  }
}

// ─── Apple / Liquid Glass ────────────────────────────────────────────────────
class _AppleCard extends StatelessWidget {
  final String prayerName, time;
  final bool isNext, isActive;
  final VoidCallback? onTap;
  const _AppleCard(
      {required this.prayerName,
      required this.time,
      required this.isNext,
      required this.isActive,
      this.onTap});

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        borderRadius: 18,
        blur: isActive ? 32 : 20,
        tintColor: isActive
            ? const Color(0xFF007AFF) // iOS blue
            : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        tintOpacity: isActive ? 0.35 : 0.15,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon bulat
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              ),
              child: Icon(
                _iconFor(prayerName),
                size: 22,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (isNext)
                    Text(
                      'Berikutnya',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isActive ? Colors.white70 : const Color(0xFF007AFF),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Material You / Android ──────────────────────────────────────────────────
class _MaterialCard extends StatelessWidget {
  final String prayerName, time;
  final bool isNext, isActive;
  final VoidCallback? onTap;
  const _MaterialCard(
      {required this.prayerName,
      required this.time,
      required this.isNext,
      required this.isActive,
      this.onTap});

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Card(
      elevation: isActive ? 3 : 1,
      color: isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                _iconFor(prayerName),
                color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prayerName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              isActive ? cs.onPrimaryContainer : cs.onSurface,
                        )),
                    if (isNext)
                      Text('Berikutnya',
                          style: TextStyle(fontSize: 12, color: cs.primary)),
                  ],
                ),
              ),
              Text(time,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isActive ? cs.onPrimaryContainer : cs.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fluent Design / Windows ─────────────────────────────────────────────────
class _FluentCard extends StatelessWidget {
  final String prayerName, time;
  final bool isNext, isActive;
  final VoidCallback? onTap;
  const _FluentCard(
      {required this.prayerName,
      required this.time,
      required this.isNext,
      required this.isActive,
      this.onTap});

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    // Fluent Acrylic simulation
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isActive
                  ? const Color(0xFF0078D4)
                      .withOpacity(0.15) // Fluent accent blue
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.7)),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF0078D4).withOpacity(0.5)
                    : (isDark
                        ? Colors.white12
                        : Colors.black.withOpacity(0.08)),
                width: isActive ? 1 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _iconFor(prayerName),
                  color: isActive
                      ? const Color(0xFF0078D4)
                      : (isDark ? Colors.white70 : Colors.black54),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prayerName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          )),
                      if (isNext)
                        const Text('Berikutnya',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0078D4),
                            )),
                    ],
                  ),
                ),
                Text(time,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(String name) {
  return switch (name.toLowerCase()) {
    'subuh' || 'fajr' => Icons.nights_stay_outlined,
    'dzuhur' || 'dhuhr' => Icons.wb_sunny_outlined,
    'ashar' || 'asr' => Icons.wb_cloudy_outlined,
    'maghrib' => Icons.wb_twilight_outlined,
    'isya' || 'isha' => Icons.dark_mode_outlined,
    _ => Icons.access_time,
  };
}
