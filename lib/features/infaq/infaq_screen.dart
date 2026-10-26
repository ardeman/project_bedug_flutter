import 'package:flutter/foundation.dart';
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
import 'infaq_provider.dart';

/// The infaq page: store tiers and restore on Play and App Store builds,
/// Trakteer and Ko-fi links elsewhere. Opened from Settings, never as a
/// pop-up.
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
            child: Text(
              channel.showsAdsOn(defaultTargetPlatform)
                  ? l10n.infaqIntro
                  : l10n.infaqIntroNoAds,
              style: textTheme.bodyMedium,
            ),
          ),
          if (infaq.thanked || infaq.adFree)
            SettingsSection(
              children: [
                PlatformListTile(
                  leading: Icon(Icons.favorite, color: accent),
                  title: Text(
                    infaq.thanked ? l10n.infaqThanks : l10n.infaqThanksSubtitle,
                  ),
                  subtitle: channel.showsAdsOn(defaultTargetPlatform)
                      ? Text(l10n.infaqAdsOff)
                      : null,
                ),
              ],
            ),
          if (channel.usesStoreBilling)
            ..._storeOptions(ctx, l10n, infaq, note)
          else
            ..._linkOptions(ctx, l10n),
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

  List<Widget> _linkOptions(BuildContext ctx, AppLocalizations l10n) {
    final accent = AppColors.accentOf(ctx);
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
    // everyone else.
    final indonesian = ref.watch(localeProvider).languageCode == 'id';
    return [
      SettingsSection(
        title: l10n.infaq,
        children: indonesian ? [trakteer, kofi] : [kofi, trakteer],
      ),
    ];
  }
}

String _productName(AppLocalizations l10n, ProductDetails product) =>
    switch (product.id) {
      InfaqProducts.small => l10n.infaqSmall,
      InfaqProducts.medium => l10n.infaqMedium,
      InfaqProducts.large => l10n.infaqLarge,
      _ => product.title,
    };
