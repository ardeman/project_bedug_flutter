import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../constants/app_colors.dart';
import '../design/liquid_glass.dart';
import '../design/glass_controls.dart';
import '../theme/app_tokens.dart';

/// One choice in a [showGlassMenu] menu.
class GlassMenuOption<T> {
  final T value;
  final String label;

  /// A short accent note under the label, e.g. "Recommended".
  final String? note;

  const GlassMenuOption({required this.value, required this.label, this.note});
}

/// The global rect of the widget that owns [ctx], to anchor a menu to it.
Rect globalRectOf(BuildContext ctx) {
  final box = ctx.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// A Liquid Glass pop-up menu for iOS and macOS that grows from [anchor]
/// (the global rect of the control that opened it), like the system's
/// pull-down menus. It opens below the anchor, or above it when the anchor
/// sits in the lower half of the screen, and calls [onSelected] with the
/// picked value before closing.
Future<void> showGlassMenu<T>(
  BuildContext ctx, {
  required Rect anchor,
  required List<GlassMenuOption<T>> options,
  required T? selected,
  required ValueChanged<T> onSelected,
  String? title,
}) {
  return Navigator.of(ctx).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, animation, __) => _GlassMenu<T>(
        animation: animation,
        anchor: anchor,
        title: title,
        options: options,
        selected: selected,
        onSelected: onSelected,
      ),
      transitionsBuilder: (_, __, ___, child) => child,
    ),
  );
}

class _GlassMenu<T> extends StatelessWidget {
  final Animation<double> animation;
  final Rect anchor;
  final String? title;
  final List<GlassMenuOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  const _GlassMenu({
    required this.animation,
    required this.anchor,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  static const _maxWidth = 320.0;
  static const _minHeight = 160.0;

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final mq = MediaQuery.of(ctx);

    final width = (mq.size.width - AppSpacing.md * 2).clamp(0.0, _maxWidth);
    // Keep the menu's right edge under the anchor, but on screen.
    final right = (mq.size.width - anchor.right)
        .clamp(AppSpacing.md, mq.size.width - width - AppSpacing.md);
    final opensUp = anchor.center.dy > mq.size.height / 2;
    final double? top = opensUp ? null : anchor.bottom + AppSpacing.xs;
    final double? bottom =
        opensUp ? mq.size.height - anchor.top + AppSpacing.xs : null;
    final maxHeight = opensUp
        ? anchor.top - AppSpacing.xs - mq.padding.top - kToolbarHeight
        : mq.size.height - top! - GlassNavBar.occupiedHeight(ctx);
    // A short landscape screen still shows a few rows; the list scrolls.
    final menuMaxHeight = maxHeight.clamp(_minHeight, double.infinity);

    final scale = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

    return Stack(
      children: [
        // Tapping anywhere else closes the menu, like a system menu.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(ctx),
          ),
        ),
        Positioned(
          top: top,
          bottom: bottom,
          right: right,
          width: width,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: menuMaxHeight),
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: Tween(begin: 0.6, end: 1.0).animate(scale),
                // Grow out of the anchor's right edge.
                alignment: opensUp ? Alignment.bottomRight : Alignment.topRight,
                child: Material(
                  color: Colors.transparent,
                  child: LiquidGlassLens(
                    style: LiquidGlassStyle(
                      shape: const LiquidGlassShape.continuousRoundedRectangle(
                          cornerRadius: AppRadii.lg),
                      color: glassTintOf(ctx),
                      blur: 18,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      children: [
                        if (title != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                                AppSpacing.xxs, AppSpacing.md, AppSpacing.xs),
                            child: Text(
                              title!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        for (final (i, option) in options.indexed) ...[
                          if (title != null || i > 0) const Hairline(),
                          _GlassMenuItem(
                            option: option,
                            isSelected: option.value == selected,
                            onTap: () {
                              onSelected(option.value);
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassMenuItem<T> extends StatelessWidget {
  final GlassMenuOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassMenuItem({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final accent = AppColors.accentOf(ctx);
    final note = option.note;
    return GlassPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (note != null)
                    Text(
                      note,
                      style: theme.textTheme.bodySmall?.copyWith(color: accent),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Fixed width, so labels line up whether or not a row is checked.
            SizedBox(
              width: 20,
              child: isSelected
                  ? Icon(Icons.check, size: 20, color: accent)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
