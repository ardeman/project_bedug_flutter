import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'platform_design.dart';

/// Toolbar action with Expressive press morphing on the Material path.
class MaterialIconButton extends StatelessWidget {
  const MaterialIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isSelected,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool? isSelected;

  @override
  Widget build(BuildContext context) => PlatformDesign.usesExpressive
      ? M3EIconButton(
          icon: icon,
          onPressed: onPressed,
          tooltip: tooltip,
          isSelected: isSelected,
        )
      : IconButton(
          icon: icon,
          onPressed: onPressed,
          tooltip: tooltip,
          isSelected: isSelected,
        );
}

/// Labeled actions use the package's spring-driven button shapes.
class MaterialLabelButton extends StatelessWidget {
  const MaterialLabelButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final Widget icon;
  final Widget label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (PlatformDesign.usesExpressive) {
      return M3EButton.icon(
        icon: icon,
        label: label,
        onPressed: onPressed,
        style: filled ? M3EButtonStyle.filled : M3EButtonStyle.text,
      );
    }
    return filled
        ? FilledButton.icon(icon: icon, label: label, onPressed: onPressed)
        : TextButton.icon(icon: icon, label: label, onPressed: onPressed);
  }
}
