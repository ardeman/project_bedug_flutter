import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../design/platform_design.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';

import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import '../providers/locale_provider.dart';
import '../services/kemenag_method.dart';
import '../design/glass_controls.dart';
import '../design/liquid_glass.dart';
import '../design/platform_capabilities.dart';
import 'glass_menu.dart';

String calculationMethodLabel(BuildContext ctx, AppCalculationMethod method) {
  final l10n = AppLocalizations.of(ctx);
  return switch (method) {
    AppCalculationMethod.kemenag => l10n.methodKemenag,
    AppCalculationMethod.muslimWorldLeague => l10n.methodMWL,
    AppCalculationMethod.isna => l10n.methodISNA,
    AppCalculationMethod.egyptian => l10n.methodEgyptian,
    AppCalculationMethod.ummAlQura => l10n.methodUmmAlQura,
    AppCalculationMethod.karachi => l10n.methodKarachi,
    AppCalculationMethod.kuwait => l10n.methodKuwait,
    AppCalculationMethod.qatar => l10n.methodQatar,
    AppCalculationMethod.singapore => l10n.methodSingapore,
    AppCalculationMethod.turkey => l10n.methodTurkey,
  };
}

Future<void> showCalculationMethodPicker(
  BuildContext ctx,
  WidgetRef ref, {
  required AppCalculationMethod current,
}) {
  if (_isApple) {
    return _showNativeAppleMethodPicker(ctx, ref, current: current);
  }

  final l10n = AppLocalizations.of(ctx);
  if (PlatformDesign.usesExpressive) {
    return M3EBottomSheet.show<void>(
      ctx,
      labels: M3EBottomSheetLabels(
        dragHandle: l10n.sheetHandle,
        expand: l10n.sheetExpand,
        collapse: l10n.sheetCollapse,
        dismiss: l10n.sheetDismiss,
        close: l10n.sheetDismiss,
        scrim: l10n.sheetDismiss,
        preview: l10n.sheetPreview,
        collapsed: l10n.sheetCollapsed,
        expanded: l10n.sheetExpanded,
        fullScreen: l10n.sheetFullScreen,
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final selected = ref.watch(settingsProvider).method;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                l10n.calculationMethod,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.calculationMethodDesc,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final method in AppCalculationMethod.values)
                M3EListItem(
                  headline: calculationMethodLabel(context, method),
                  supportingText: method == AppCalculationMethod.kemenag
                      ? l10n.recommended
                      : null,
                  selected: selected == method,
                  trailing: selected == method ? const Icon(Icons.check) : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setMethod(method);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
  return Navigator.of(ctx).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, animation, _) => _CalculationMethodPickerSheet(
        animation: animation,
        title: l10n.calculationMethod,
        current: current,
      ),
      transitionsBuilder: (_, _, _, child) => child,
    ),
  );
}

/// On Apple platforms, a Liquid Glass pop-up menu that grows from [anchor]
/// (the global rect of the button that opened it), like the system's pull-down
/// menus. Elsewhere, the same picker as [showCalculationMethodPicker].
Future<void> showCalculationMethodMenu(
  BuildContext ctx,
  WidgetRef ref, {
  required AppCalculationMethod current,
  required Rect anchor,
}) {
  if (!_isApple) {
    return showCalculationMethodPicker(ctx, ref, current: current);
  }
  final l10n = AppLocalizations.of(ctx);
  return showGlassMenu(
    ctx,
    anchor: anchor,
    title: l10n.calculationMethod,
    options: [
      for (final method in AppCalculationMethod.values)
        GlassMenuOption(
          value: method,
          label: calculationMethodLabel(ctx, method),
          note: method == AppCalculationMethod.kemenag
              ? l10n.recommended
              : null,
        ),
    ],
    selected: current,
    onSelected: ref.read(settingsProvider.notifier).setMethod,
  );
}

bool get _isApple =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

Future<void> _showNativeAppleMethodPicker(
  BuildContext ctx,
  WidgetRef ref, {
  required AppCalculationMethod current,
}) {
  return showCupertinoSheet<void>(
    context: ctx,
    showDragHandle: true,
    topGap: 0.08,
    // Sharing the controller lets a downward drag at the top of the list
    // dismiss the sheet, like native iOS sheets.
    scrollableBuilder: (sheetCtx, controller) =>
        _NativeAppleMethodSheet(current: current, controller: controller),
  );
}

class _NativeAppleMethodSheet extends ConsumerWidget {
  final AppCalculationMethod current;
  final ScrollController controller;

  const _NativeAppleMethodSheet({
    required this.current,
    required this.controller,
  });

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final selectedMethod = ref.watch(settingsProvider).method;
    final theme = Theme.of(ctx);
    final colors = theme.colorScheme;
    final accent = AppColors.accentOf(ctx);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface.withValues(alpha: 0.96),
        automaticBackgroundVisibility: false,
        middle: Text(
          l10n.calculationMethod,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.calculationMethodDesc,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: AppCalculationMethod.values.length,
                itemBuilder: (context, index) {
                  final method = AppCalculationMethod.values[index];
                  final isSelected = selectedMethod == method;
                  final isKemenag = method == AppCalculationMethod.kemenag;
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    onPressed: () {
                      ref.read(settingsProvider.notifier).setMethod(method);
                      Navigator.of(ctx, rootNavigator: true).pop();
                    },
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: AppControlSizes.toolbarIcon,
                          color: isSelected ? accent : colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                calculationMethodLabel(ctx, method),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isSelected ? accent : colors.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              if (isKemenag) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: .15),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.sm,
                                    ),
                                  ),
                                  child: Text(
                                    l10n.recommended,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculationMethodPickerSheet extends ConsumerStatefulWidget {
  final Animation<double> animation;
  final String title;
  final AppCalculationMethod current;

  const _CalculationMethodPickerSheet({
    required this.animation,
    required this.title,
    required this.current,
  });

  @override
  ConsumerState<_CalculationMethodPickerSheet> createState() =>
      _CalculationMethodPickerSheetState();
}

class _CalculationMethodPickerSheetState
    extends ConsumerState<_CalculationMethodPickerSheet> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final colors = theme.colorScheme;
    final bottom = MediaQuery.of(ctx).padding.bottom;
    final h = MediaQuery.of(ctx).size.height;

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final curved = Curves.easeOutCubic.transform(widget.animation.value);
        final routeOffset = (1 - curved) * (h * 0.6 + AppSpacing.xxl);

        return GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Scaffold(
            backgroundColor: Colors.black.withValues(alpha: .38 * curved),
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  // The panel runs one corner radius past the screen edge,
                  // so only its top corners show.
                  bottom: -(routeOffset + _dragOffset) - AppRadii.xl,
                  child: GestureDetector(
                    onTap: () {},
                    child: RepaintBoundary(
                      child: Material(
                        color: Colors.transparent,
                        child: LiquidGlassLite(
                          shape:
                              const LiquidGlassShape.continuousRoundedRectangle(
                                cornerRadius: AppRadii.xl,
                              ),
                          blur: 28,
                          color: glassSheetTintOf(ctx),
                          child: Container(
                            height: h * 0.6 + AppRadii.xl,
                            padding: EdgeInsets.only(
                              bottom: bottom + AppRadii.xl,
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onVerticalDragUpdate: (details) {
                                    if (details.delta.dy <= 0) return;
                                    setState(() {
                                      _dragOffset =
                                          (_dragOffset + details.delta.dy)
                                              .clamp(0, 220);
                                    });
                                  },
                                  onVerticalDragEnd: (details) {
                                    final shouldClose =
                                        _dragOffset > 72 ||
                                        (details.primaryVelocity ?? 0) > 700;
                                    if (shouldClose) {
                                      Navigator.pop(ctx);
                                    } else {
                                      setState(() => _dragOffset = 0);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.xs,
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: Container(
                                      width: 36,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: colors.onSurfaceVariant
                                            .withValues(alpha: .3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: Text(
                                    widget.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: colors.outlineVariant,
                                ),
                                Expanded(
                                  child: MediaQuery.removePadding(
                                    context: ctx,
                                    removeTop: true,
                                    child: ListView(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.xxs,
                                      ),
                                      children: AppCalculationMethod.values.indexed.map((
                                        entry,
                                      ) {
                                        final i = entry.$1;
                                        final method = entry.$2;
                                        final isSelected =
                                            ref
                                                .watch(settingsProvider)
                                                .method ==
                                            method;
                                        final isKemenag =
                                            method ==
                                            AppCalculationMethod.kemenag;
                                        return TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0, end: 1),
                                          duration: Duration(
                                            milliseconds: 220 + (i * 45),
                                          ),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, child) =>
                                              Opacity(
                                                opacity: value,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                    0,
                                                    (1 - value) * AppSpacing.md,
                                                  ),
                                                  child: child,
                                                ),
                                              ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: AppSpacing.xxs,
                                            ),
                                            child: Material(
                                              color: isSelected
                                                  ? AppColors.accentOf(ctx)
                                                        .withValues(alpha: .08)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadii.sm,
                                                  ),
                                              clipBehavior: Clip.antiAlias,
                                              child: ListTile(
                                                leading: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 180,
                                                  ),
                                                  child: isSelected
                                                      ? Icon(
                                                          Icons.check_circle,
                                                          key: ValueKey(
                                                            'selected',
                                                          ),
                                                          color:
                                                              AppColors.accentOf(
                                                                ctx,
                                                              ),
                                                        )
                                                      : Icon(
                                                          Icons
                                                              .radio_button_unchecked,
                                                          key: ValueKey(
                                                            'unselected',
                                                          ),
                                                          color: colors
                                                              .onSurfaceVariant,
                                                        ),
                                                ),
                                                title: Text(
                                                  calculationMethodLabel(
                                                    ctx,
                                                    method,
                                                  ),
                                                  style: theme
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        fontWeight: isSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                        color: isSelected
                                                            ? AppColors.accentOf(
                                                                ctx,
                                                              )
                                                            : null,
                                                      ),
                                                ),
                                                trailing: isKemenag
                                                    ? Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal:
                                                                  AppSpacing.xs,
                                                              vertical:
                                                                  AppSpacing
                                                                      .xxs,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              AppColors.accentOf(
                                                                ctx,
                                                              ).withValues(
                                                                alpha: .15,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                AppRadii.sm,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          AppLocalizations.of(
                                                            ctx,
                                                          ).recommended,
                                                          style: theme
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color:
                                                                    AppColors.accentOf(
                                                                      ctx,
                                                                    ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      )
                                                    : null,
                                                onTap: () {
                                                  ref
                                                      .read(
                                                        settingsProvider
                                                            .notifier,
                                                      )
                                                      .setMethod(method);
                                                  Navigator.pop(ctx);
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      },
    );
  }
}

/// Opens the calculation method picker as a full page, so it slides in like
/// the other settings pages and closes with the edge swipe back.
Future<void> showCalculationMethodPage(BuildContext ctx) => Navigator.of(ctx)
    .push(
      MaterialPageRoute<void>(builder: (_) => const CalculationMethodScreen()),
    );

class CalculationMethodScreen extends ConsumerWidget {
  const CalculationMethodScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final isApple = PlatformCapabilities.isApple;
    final accent = AppColors.accentOf(ctx);
    final selected = ref.watch(settingsProvider).method;

    final rows = [
      for (final method in AppCalculationMethod.values)
        PlatformListTile(
          title: Text(calculationMethodLabel(ctx, method)),
          subtitle: method == AppCalculationMethod.kemenag
              ? Text(l10n.recommended)
              : null,
          trailing: method == selected
              ? Icon(Icons.check, color: accent)
              : null,
          onTap: () {
            ref.read(settingsProvider.notifier).setMethod(method);
            Navigator.of(ctx).pop();
          },
        ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: isApple,
      appBar: GlassTopBar(title: l10n.calculationMethod),
      body: ListView(
        // Explicit list padding disables ListView's automatic safe-area
        // padding. Start below the floating toolbar; scrolling can still
        // carry the content behind the glass.
        padding: EdgeInsets.only(
          top: isApple ? kToolbarHeight + MediaQuery.of(ctx).padding.top : 0,
          bottom: GlassNavBar.occupiedHeight(ctx),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Text(
              l10n.calculationMethodDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (PlatformDesign.usesExpressive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: M3EList(
                itemCount: rows.length,
                onTap: (i) => rows[i].onTap?.call(),
                itemBuilder: (ctx, i) => rows[i],
              ),
            )
          else if (isApple)
            GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  for (final (i, row) in rows.indexed) ...[
                    if (i > 0) const Hairline(indent: AppSpacing.md),
                    row,
                  ],
                ],
              ),
            )
          else
            ...rows,
        ],
      ),
    );
  }
}
