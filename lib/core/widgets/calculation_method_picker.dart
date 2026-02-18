import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../providers/locale_provider.dart';
import '../services/kemenag_method.dart';

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
  final l10n = AppLocalizations.of(ctx);
  return Navigator.of(ctx).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, animation, ___) => _CalculationMethodPickerSheet(
        animation: animation,
        title: l10n.calculationMethod,
        current: current,
      ),
      transitionsBuilder: (_, __, ___, child) => child,
    ),
  );
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
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final bottom = MediaQuery.of(ctx).padding.bottom;
    final h = MediaQuery.of(ctx).size.height;

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final curved = Curves.easeOutCubic.transform(widget.animation.value);
        final routeOffset = (1 - curved) * (h * 0.6 + 48);

        return GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Scaffold(
            backgroundColor: Colors.black.withValues(alpha: .38 * curved),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Transform.translate(
                    offset: Offset(0, routeOffset + _dragOffset),
                    child: Container(
                      height: h * 0.6,
                      padding: EdgeInsets.only(bottom: bottom),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1E).withValues(alpha: .88)
                            : Colors.white.withValues(alpha: .88),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: .25),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragUpdate: (details) {
                              if (details.delta.dy <= 0) return;
                              setState(() {
                                _dragOffset = (_dragOffset + details.delta.dy)
                                    .clamp(0, 220);
                              });
                            },
                            onVerticalDragEnd: (details) {
                              final shouldClose = _dragOffset > 72 ||
                                  (details.primaryVelocity ?? 0) > 700;
                              if (shouldClose) {
                                Navigator.pop(ctx);
                              } else {
                                setState(() => _dragOffset = 0);
                              }
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 10),
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color:
                                      isDark ? Colors.white24 : Colors.black12,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          Expanded(
                            child: ListView(
                              children: AppCalculationMethod.values.indexed
                                  .map((entry) {
                                final i = entry.$1;
                                final method = entry.$2;
                                final isSelected =
                                    ref.watch(settingsProvider).method ==
                                        method;
                                final isKemenag =
                                    method == AppCalculationMethod.kemenag;
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration:
                                      Duration(milliseconds: 220 + (i * 45)),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) => Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, (1 - value) * 16),
                                      child: child,
                                    ),
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.emerald
                                              .withValues(alpha: .08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check_circle,
                                                key: ValueKey('selected'),
                                                color: AppColors.emerald,
                                              )
                                            : const Icon(
                                                Icons.radio_button_unchecked,
                                                key: ValueKey('unselected'),
                                                color: Colors.grey,
                                              ),
                                      ),
                                      title: Text(
                                        calculationMethodLabel(ctx, method),
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppColors.emerald
                                              : null,
                                        ),
                                      ),
                                      trailing: isKemenag
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.emerald
                                                    .withValues(alpha: .15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                AppLocalizations.of(ctx)
                                                    .recommended,
                                                style: const TextStyle(
                                                  color: AppColors.emerald,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : null,
                                      onTap: () {
                                        ref
                                            .read(settingsProvider.notifier)
                                            .setMethod(method);
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
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
        );
      },
    );
  }
}
