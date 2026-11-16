import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoTextField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import '../settings/settings_section.dart';
import 'dahlunas_config.dart';
import 'infaq_provider.dart';

/// The infaq page: store tiers and restore on Play and App Store builds,
/// Trakteer, Ko-fi and Dahlunas codes on direct builds. Opened from Settings,
/// never as a pop-up.
class InfaqScreen extends ConsumerStatefulWidget {
  const InfaqScreen({super.key});

  @override
  ConsumerState<InfaqScreen> createState() => _InfaqScreenState();
}

class _InfaqScreenState extends ConsumerState<InfaqScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(infaqProvider.notifier).load());
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final channel = ref.watch(distributionChannelProvider);
    final infaq = ref.watch(infaqProvider);
    final textTheme = Theme.of(ctx).textTheme;
    final accent = AppColors.accentOf(ctx);

    Widget note(String text, {Color? color}) => Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(text, style: textTheme.bodySmall?.copyWith(color: color)),
    );

    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.infaq),
      body: ListView(
        padding: EdgeInsets.only(
          top: PlatformCapabilities.isApple
              ? kToolbarHeight + MediaQuery.paddingOf(ctx).top
              : 0,
          bottom: MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(l10n.infaqIntro, style: textTheme.bodyMedium),
          ),
          if (infaq.thanked || infaq.given)
            SettingsSection(
              children: [
                PlatformListTile(
                  leading: Icon(Icons.favorite, color: accent),
                  title: Text(
                    infaq.thanked ? l10n.infaqThanks : l10n.infaqThanksSubtitle,
                  ),
                  subtitle: infaq.movesLeft != null
                      ? Text(l10n.infaqCodeMovesLeft(infaq.movesLeft!))
                      : null,
                ),
              ],
            ),
          if (infaq.codeMovedAway)
            note(l10n.infaqCodeMoved, color: Theme.of(ctx).colorScheme.error),
          if (channel.usesStoreBilling)
            ..._storeOptions(ctx, l10n, infaq, note)
          else
            ..._linkOptions(ctx, l10n, infaq, note),
        ],
      ),
    );
  }

  List<Widget> _storeOptions(
    BuildContext ctx,
    AppLocalizations l10n,
    InfaqState infaq,
    Widget Function(String, {Color? color}) note,
  ) {
    final notifier = ref.read(infaqProvider.notifier);
    final accent = AppColors.accentOf(ctx);
    final error = Theme.of(ctx).colorScheme.error;
    if (infaq.products.isEmpty) {
      if (infaq.loading || infaq.error == null) {
        return const [
          Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: AdaptiveSpinner()),
          ),
        ];
      }
      return [
        note(l10n.infaqUnavailable, color: error),
        SettingsSection(
          children: [
            PlatformListTile(
              leading: Icon(Icons.refresh, color: accent),
              title: Text(l10n.infaqRetry),
              onTap: notifier.load,
            ),
          ],
        ),
      ];
    }
    return [
      SettingsSection(
        title: l10n.infaq,
        children: [
          for (final product in infaq.products)
            PlatformListTile(
              key: ValueKey(product.id),
              enabled: !infaq.pending,
              leading: Icon(Icons.volunteer_activism_outlined, color: accent),
              title: Text(_productName(l10n, product)),
              trailing: Text(
                product.price,
                style: Theme.of(ctx).textTheme.titleSmall
                    ?.copyWith(color: accent, fontWeight: FontWeight.bold),
              ),
              onTap: () => notifier.buy(product),
            ),
        ],
      ),
      if (infaq.pending) note(l10n.infaqPending),
      if (infaq.error == InfaqError.purchaseFailed)
        note(l10n.infaqFailed, color: error),
      SettingsSection(
        children: [
          PlatformListTile(
            leading: Icon(Icons.restore, color: accent),
            title: Text(l10n.infaqRestore),
            onTap: notifier.restore,
          ),
        ],
      ),
      note(l10n.infaqRestoreNote),
    ];
  }

  List<Widget> _linkOptions(
    BuildContext ctx,
    AppLocalizations l10n,
    InfaqState infaq,
    Widget Function(String, {Color? color}) note,
  ) {
    final accent = AppColors.accentOf(ctx);
    final error = Theme.of(ctx).colorScheme.error;
    PlatformListTile link(String name, String methods, Uri url) =>
        PlatformListTile(
          leading: Icon(Icons.volunteer_activism_outlined, color: accent),
          title: Text(name),
          subtitle: Text(methods),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => launchUrl(url, mode: LaunchMode.externalApplication),
        );
    final trakteer = link(
      l10n.infaqTrakteer,
      l10n.infaqTrakteerMethods,
      InfaqLinks.trakteer,
    );
    final kofi = link(l10n.infaqKofi, l10n.infaqKofiMethods, InfaqLinks.kofi);
    // Trakteer takes Indonesian payments (QRIS, e-wallets); Ko-fi suits
    // everyone else. Dahlunas is sandbox-first until Bedug is on production.
    final indonesian = ref.watch(localeProvider).languageCode == 'id';
    final rows = <Widget>[
      if (DahlunasConfig.codesEnabled)
        link(
          l10n.infaqDahlunas,
          l10n.infaqDahlunasMethods,
          InfaqLinks.dahlunas,
        ),
      ...indonesian ? [trakteer, kofi] : [kofi, trakteer],
    ];
    return [
      SettingsSection(title: l10n.infaq, children: rows),
      if (DahlunasConfig.codesEnabled) ...[
        SettingsSection(
          children: [
            PlatformListTile(
              leading: Icon(Icons.vpn_key_outlined, color: accent),
              title: Text(l10n.infaqHaveCode),
              enabled: !infaq.redeeming,
              onTap: () => _askCode(ctx, l10n),
            ),
          ],
        ),
        if (infaq.redeeming) note(l10n.infaqCodePending),
        if (infaq.error case final err?)
          note(_codeError(l10n, err), color: error),
        note(l10n.infaqCodePrivacy),
      ],
    ];
  }

  Future<void> _askCode(BuildContext ctx, AppLocalizations l10n) async {
    final controller = TextEditingController();
    final submitted = await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) {
        final field = PlatformCapabilities.isApple
            ? CupertinoTextField(
                controller: controller,
                placeholder: l10n.infaqCodeHint,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
              )
            : TextField(
                controller: controller,
                decoration: InputDecoration(hintText: l10n.infaqCodeHint),
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
              );
        void submit() => Navigator.of(dialogCtx).pop(controller.text.trim());
        if (PlatformCapabilities.isApple) {
          return AlertDialog.adaptive(
            title: Text(l10n.infaqHaveCode),
            content: field,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(onPressed: submit, child: Text(l10n.infaqCodeSubmit)),
            ],
          );
        }
        return AlertDialog(
          title: Text(l10n.infaqHaveCode),
          content: field,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(onPressed: submit, child: Text(l10n.infaqCodeSubmit)),
          ],
        );
      },
    );
    controller.dispose();
    if (submitted == null || submitted.isEmpty || !ctx.mounted) return;
    await ref.read(infaqProvider.notifier).redeemCode(submitted);
  }
}

String _productName(AppLocalizations l10n, ProductDetails product) =>
    switch (product.id) {
      InfaqProducts.small => l10n.infaqSmall,
      InfaqProducts.medium => l10n.infaqMedium,
      InfaqProducts.large => l10n.infaqLarge,
      _ => product.title,
    };

String _codeError(AppLocalizations l10n, InfaqError error) => switch (error) {
  InfaqError.codeInvalid => l10n.infaqCodeInvalid,
  InfaqError.codeRejected => l10n.infaqCodeRejected,
  InfaqError.codeMoveLimit => l10n.infaqCodeMoveLimit(
    DahlunasConfig.supportEmail,
  ),
  InfaqError.codeBusy => l10n.infaqCodeBusy,
  _ => l10n.infaqCodeRejected,
};
