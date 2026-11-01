import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoTextField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/design/platform_design.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'zakat.dart';

enum _ZakatKind { maal, fitrah }

/// Zakat maal on what someone owns today and zakat fitrah for a household.
/// Only the gold price and the fitrah amount per person are saved.
class ZakatScreen extends ConsumerStatefulWidget {
  const ZakatScreen({super.key});

  @override
  ConsumerState<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends ConsumerState<ZakatScreen> {
  var _kind = _ZakatKind.maal;
  final _assets = <String, int>{};
  var _debts = 0;
  var _people = 1;

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.zakat),
      body: Center(
        child: ConstrainedBox(
          // Keep the fields readable on wide desktop windows.
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: PlatformSegmentedControl<_ZakatKind>(
                  segments: {
                    _ZakatKind.maal: l10n.zakatMaal,
                    _ZakatKind.fitrah: l10n.zakatFitrah,
                  },
                  value: _kind,
                  onChanged: (kind) => setState(() => _kind = kind),
                ),
              ),
              ...switch (_kind) {
                _ZakatKind.maal => _maal(ctx, l10n),
                _ZakatKind.fitrah => _fitrah(ctx, l10n),
              },
              _Note(text: l10n.zakatPrivacyNote),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _maal(BuildContext ctx, AppLocalizations l10n) {
    final prices = ref.watch(zakatPricesProvider);
    final maal = ZakatMaal(
      goldPricePerGram: prices.goldPricePerGram,
      assets: _assets.values.fold(0, (sum, value) => sum + value),
      debts: _debts,
    );
    final format = NumberFormat.decimalPattern(l10n.localeName);
    final theme = Theme.of(ctx);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget asset(String key, String label) => _AmountField(
      key: ValueKey('zakat-$key'),
      label: label,
      initial: _assets[key] ?? 0,
      onChanged: (value) => setState(() => _assets[key] = value),
    );

    return [
      _Note(text: l10n.zakatMaalHint),
      _Section(
        children: [
          _AmountField(
            key: const ValueKey('zakat-gold-price'),
            label: l10n.zakatGoldPrice,
            initial: prices.goldPricePerGram,
            onChanged: ref
                .read(zakatPricesProvider.notifier)
                .setGoldPricePerGram,
          ),
          if (maal.hasNisab)
            Text(
              l10n.zakatNisab(
                format.format(maal.nisab),
                kNisabGoldGrams.toString(),
              ),
              style: muted,
            ),
        ],
      ),
      _Section(
        title: l10n.zakatWealth,
        children: [
          asset('cash', l10n.zakatCash),
          asset('gold', l10n.zakatGold),
          asset('investments', l10n.zakatInvestments),
          asset('trade', l10n.zakatTradeGoods),
          asset('receivables', l10n.zakatReceivables),
        ],
      ),
      _Section(
        title: l10n.zakatDebtsTitle,
        children: [
          _AmountField(
            key: const ValueKey('zakat-debts'),
            label: l10n.zakatDebts,
            initial: _debts,
            onChanged: (value) => setState(() => _debts = value),
          ),
        ],
      ),
      _Result(
        title: l10n.zakatMaalDue,
        amount: maal.reachesNisab ? format.format(maal.zakat) : null,
        details: [
          l10n.zakatNetWealth(format.format(maal.netWealth)),
          if (!maal.hasNisab)
            l10n.zakatNeedsGoldPrice
          else if (!maal.reachesNisab)
            l10n.zakatBelowNisab,
        ],
      ),
    ];
  }

  List<Widget> _fitrah(BuildContext ctx, AppLocalizations l10n) {
    final prices = ref.watch(zakatPricesProvider);
    final format = NumberFormat.decimalPattern(l10n.localeName);
    final total = zakatFitrah(
      people: _people,
      perPerson: prices.fitrahPerPerson,
    );
    return [
      _Note(text: l10n.zakatFitrahHint),
      _Section(
        children: [
          _AmountField(
            key: const ValueKey('zakat-people'),
            label: l10n.zakatPeople,
            initial: _people,
            onChanged: (value) => setState(() => _people = value),
          ),
          _AmountField(
            key: const ValueKey('zakat-fitrah-per-person'),
            label: l10n.zakatFitrahPerPerson,
            initial: prices.fitrahPerPerson,
            onChanged: ref
                .read(zakatPricesProvider.notifier)
                .setFitrahPerPerson,
          ),
        ],
      ),
      _Result(
        title: l10n.zakatFitrahDue,
        amount: total > 0 ? format.format(total) : null,
        details: [
          l10n.zakatFitrahInKind(format.format(fitrahStapleKg(_people))),
        ],
      ),
    ];
  }
}

/// A short muted paragraph between the cards.
class _Note extends StatelessWidget {
  final String text;

  const _Note({required this.text});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A card of fields with an optional heading.
class _Section extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _Section({this.title, required this.children});

  @override
  Widget build(BuildContext ctx) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            if (title != null)
              Text(
                title!,
                style: Theme.of(ctx).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// The amount due, or only the [details] when nothing is due yet.
class _Result extends StatelessWidget {
  final String title;
  final String? amount;
  final List<String> details;

  const _Result({required this.title, this.amount, required this.details});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (amount != null)
              Text(
                amount!,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.accentOf(ctx),
                  fontWeight: FontWeight.bold,
                ),
              ),
            for (final detail in details) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                detail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A whole amount, grouped as the locale does: a Cupertino field on Apple,
/// an Expressive field on Material paths and a text field elsewhere.
class _AmountField extends StatefulWidget {
  final String label;
  final int initial;
  final ValueChanged<int> onChanged;

  const _AmountField({
    super.key,
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  late final TextEditingController _controller;
  AmountInputFormatter? _formatter;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = AppLocalizations.of(context).localeName;
    _formatter = AmountInputFormatter(locale);
    // Fill in the starting amount, or regroup it when the language changes.
    final value = _formatter!.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: _controller.text.isEmpty
            ? (widget.initial > 0 ? widget.initial.toString() : '')
            : parseAmount(_controller.text).toString(),
      ),
    );
    _controller.value = value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) => widget.onChanged(parseAmount(text));

  @override
  Widget build(BuildContext ctx) {
    final formatters = [_formatter!];
    const keyboard = TextInputType.number;
    if (PlatformCapabilities.isApple) {
      final theme = Theme.of(ctx);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xxs,
        children: [
          Text(
            widget.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          CupertinoTextField(
            controller: _controller,
            keyboardType: keyboard,
            inputFormatters: formatters,
            onChanged: _changed,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
        ],
      );
    }
    if (PlatformDesign.usesExpressive) {
      return M3ETextField(
        controller: _controller,
        label: widget.label,
        keyboardType: keyboard,
        inputFormatters: formatters,
        onChanged: _changed,
      );
    }
    return TextField(
      controller: _controller,
      keyboardType: keyboard,
      inputFormatters: formatters,
      onChanged: _changed,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
