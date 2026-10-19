import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../generated/l10n/app_localizations.dart';
import '../qibla/widgets/qibla_card.dart';

/// Worship tab: Qibla now, and later the prayer tracker, tasbih and duas.
class WorshipScreen extends StatelessWidget {
  const WorshipScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.worship),
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
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
