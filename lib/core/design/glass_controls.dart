import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import 'platform_capabilities.dart';

// Controls that keep iOS and macOS free of Material widgets (ink ripples,
// ListTile, Divider, Material spinners). Each one falls back to its Material
// twin elsewhere, or is only used on Apple paths.

/// Apple tap feedback: a soft fill while pressed, like a UIKit table cell or
/// menu item, instead of Material's ink ripple.
class GlassPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const GlassPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext ctx) {
    if (widget.onTap == null) return widget.child;
    final fill = Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.08);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _pressed ? fill : fill.withValues(alpha: 0),
          borderRadius: widget.borderRadius,
        ),
        child: widget.child,
      ),
    );
  }
}

/// A list row: [ListTile] on Material platforms, and on iOS and macOS a
/// grouped-list cell with [GlassPressable] feedback.
class PlatformListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const PlatformListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  /// Where the text starts: the row padding, a 24pt icon and a gap. Inset
  /// row separators by this, like grouped iOS lists.
  static const textInset = AppSpacing.md + 24 + AppSpacing.md;

  /// A standard iOS table cell height.
  static const _minHeight = 52.0;

  @override
  Widget build(BuildContext ctx) {
    if (!PlatformCapabilities.isApple) {
      return ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      );
    }

    final theme = Theme.of(ctx);
    final muted = theme.colorScheme.onSurfaceVariant;
    return GlassPressable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(children: [
            if (leading != null) ...[
              SizedBox(width: 24, child: Center(child: leading)),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurface),
                    child: title,
                  ),
                  if (subtitle != null)
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      child: subtitle!,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              IconTheme.merge(
                data: IconThemeData(color: muted, size: 20),
                child: trailing!,
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// A one-physical-pixel separator line, for Apple lists and menus.
class Hairline extends StatelessWidget {
  final double indent;

  const Hairline({super.key, this.indent = 0});

  @override
  Widget build(BuildContext ctx) => Padding(
        padding: EdgeInsetsDirectional.only(start: indent),
        child: Container(
          height: 1 / MediaQuery.devicePixelRatioOf(ctx),
          color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      );
}

/// A busy spinner: the system activity indicator on iOS and macOS, the
/// Material one elsewhere.
class AdaptiveSpinner extends StatelessWidget {
  const AdaptiveSpinner({super.key});

  @override
  Widget build(BuildContext ctx) => PlatformCapabilities.isApple
      ? const CupertinoActivityIndicator(radius: 14)
      : const CircularProgressIndicator();
}

/// A small accent pill button in lite glass, for use inside scrolling glass
/// cards where a refracting [LiquidGlassButton] shouldn't go.
class GlassPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const GlassPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  /// Pill height: compact, inside a 48pt row.
  static const _height = 32.0;

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final accent = AppColors.accentOf(ctx);
    final radius = BorderRadius.circular(_height / 2);
    return LiquidGlassLite(
      shape: const LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: _height / 2),
      blur: 6,
      color: accent.withValues(alpha: 0.12),
      child: GlassPressable(
        onTap: onPressed,
        borderRadius: radius,
        child: SizedBox(
          height: _height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: accent),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
