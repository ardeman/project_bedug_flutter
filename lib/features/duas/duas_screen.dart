import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/recitation_card.dart';
import '../../generated/l10n/app_localizations.dart';
import 'duas.dart';

/// Daily duas grouped by situation; each situation opens its duas.
class DuasScreen extends ConsumerWidget {
  const DuasScreen({super.key});

  static const _categoryIcons = {
    'sleep': Icons.bedtime_outlined,
    'eating': Icons.restaurant,
    'clothing': Icons.checkroom,
    'toilet': Icons.wc,
    'wudu': Icons.water_drop_outlined,
    'home': Icons.home_outlined,
    'mosque': Icons.mosque,
    'travel': Icons.directions_car_outlined,
    'rain': Icons.umbrella_outlined,
    'sneezing': Icons.air,
    'hardship': Icons.healing_outlined,
    'anytime': Icons.volunteer_activism_outlined,
  };

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final book = ref.watch(duaBookProvider);
    final languageCode = Localizations.localeOf(ctx).languageCode;

    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.duas),
      body: book.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (_, _) => _LoadError(message: l10n.duasLoadError),
        data: (book) => _ReadableList(
          children: [
            const SizedBox(height: AppSpacing.sm),
            for (final category in book.categories)
              GlassCard(
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: PlatformListTile(
                  leading: Icon(
                    _categoryIcons[category.id] ?? Icons.menu_book_outlined,
                    color: AppColors.accentOf(ctx),
                  ),
                  title: Text(category.nameFor(languageCode)),
                  subtitle: Text(
                    category.items
                        .map((d) => d.titleFor(languageCode))
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          _DuaCategoryScreen(book: book, category: category),
                    ),
                  ),
                ),
              ),
            _Source(text: book.sourceFor(languageCode)),
          ],
        ),
      ),
    );
  }
}

class _DuaCategoryScreen extends StatelessWidget {
  final DuaBook book;
  final DuaCategory category;

  const _DuaCategoryScreen({required this.book, required this.category});

  @override
  Widget build(BuildContext ctx) {
    final languageCode = Localizations.localeOf(ctx).languageCode;
    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: category.nameFor(languageCode)),
      body: _ReadableList(
        children: [
          const SizedBox(height: AppSpacing.sm),
          for (final dua in category.items)
            RecitationCard(
              title: dua.titleFor(languageCode),
              arabic: dua.arabic,
              transliteration: dua.transliteration,
              translation: dua.translationFor(languageCode),
              reference: dua.reference,
            ),
          _Source(text: book.sourceFor(languageCode)),
        ],
      ),
    );
  }
}

class _ReadableList extends StatelessWidget {
  final List<Widget> children;

  const _ReadableList({required this.children});

  @override
  Widget build(BuildContext ctx) => Center(
    child: ConstrainedBox(
      // Keep lines readable on wide desktop windows.
      constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(children: children),
    ),
  );
}

class _LoadError extends StatelessWidget {
  final String message;

  const _LoadError({required this.message});

  @override
  Widget build(BuildContext ctx) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

class _Source extends StatelessWidget {
  final String text;

  const _Source({required this.text});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xl,
    ),
    child: Text(
      AppLocalizations.of(ctx).dzikirSource(text),
      textAlign: TextAlign.center,
      style: Theme.of(ctx).textTheme.bodySmall
          ?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
    ),
  );
}
