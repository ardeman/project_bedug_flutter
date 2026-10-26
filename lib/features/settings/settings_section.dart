import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/design/platform_design.dart';
import '../../core/theme/app_tokens.dart';

/// A titled group of rows: an inset glass card on iOS and macOS, like the
/// system Settings app, and a flat list elsewhere.
class SettingsSection extends StatelessWidget {
  /// Null for an untitled group, such as a page's single master switch.
  final String? title;
  final List<Widget> children;

  const SettingsSection({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext ctx) {
    final isApple = PlatformCapabilities.isApple;
    final title = this.title;
    final header = title == null
        ? const SizedBox(height: AppSpacing.md)
        : Padding(
            padding: EdgeInsets.fromLTRB(
              // Line the header up with the rows inside the inset card.
              isApple ? AppSpacing.md * 2 : AppSpacing.md,
              AppSpacing.md + AppSpacing.xxs,
              AppSpacing.md,
              AppSpacing.xxs,
            ),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.accentOf(ctx),
                letterSpacing: 1.2,
              ),
            ),
          );
    if (PlatformDesign.usesExpressive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: M3EList(
              itemCount: children.length,
              onTap: (index) {
                final row = children[index];
                if (row is PlatformListTile && row.enabled) row.onTap?.call();
              },
              itemBuilder: (context, index) => children[index],
            ),
          ),
        ],
      );
    }
    if (!isApple) {
      return Column(children: [header, ...children]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (final (i, row) in children.indexed) ...[
                // Inset past the leading icon, like grouped iOS lists.
                if (i > 0) const Hairline(indent: PlatformListTile.textInset),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
