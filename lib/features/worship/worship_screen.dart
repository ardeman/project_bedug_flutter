import 'package:flutter/material.dart';

import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../generated/l10n/app_localizations.dart';
import '../qibla/widgets/qibla_card.dart';

/// Worship tab: Qibla now, and later the prayer tracker, tasbih and duas.
class WorshipScreen extends StatelessWidget {
  const WorshipScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.worship),
      body: Center(
        child: ConstrainedBox(
          // Keep the card readable on wide desktop windows.
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(children: const [QiblaCard()]),
        ),
      ),
    );
  }
}
