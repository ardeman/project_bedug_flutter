import 'package:flutter/foundation.dart';

import 'dahlunas_base32.dart';
import 'dahlunas_client.dart';
import 'dahlunas_unlock.dart';
import 'dahlunas_activation.dart';

/// Bedug's Dahlunas shop, keys and helpers for direct (and later F-Droid) builds.
///
/// Sandbox key 1 is for debug/profile only. Production keys land when Dahlunas
/// adds Bedug to the production catalog.
abstract final class DahlunasConfig {
  static const projectId = 2;
  static const supportEmail = 'mail@ardeman.com';

  /// Sandbox public key for Bedug key id 1 (Dahlunas README / catalog).
  static const sandboxKey1Hex =
      '31267471750b709622d73dbf2dc88df415d67895609910fa967a0545b04f7e50';

  static final sandboxShop = Uri.parse(
    'https://dah-lunas-sandbox.web.app/projects/bedug',
  );
  static final productionShop = Uri.parse(
    'https://dahlunas.ardeman.com/projects/bedug',
  );

  /// Debug/profile builds talk to the sandbox; release uses production.
  static bool get useSandbox => !kReleaseMode;

  static Uri get shopUri => useSandbox ? sandboxShop : productionShop;

  static Uri get apiBase => useSandbox
      ? Uri.parse('https://dah-lunas-sandbox.web.app')
      : Uri.parse('https://dahlunas.ardeman.com');

  static Map<int, List<int>> get publicKeys => {
    if (useSandbox) 1: DahlunasBase32.hex(sandboxKey1Hex),
    // Production key id goes here once Dahlunas mints it.
  };

  static bool get codesEnabled => publicKeys.isNotEmpty;

  static DahlunasUnlock get unlock =>
      DahlunasUnlock.bedug(publicKeys: publicKeys);

  static DahlunasActivation get activation =>
      DahlunasActivation.bedug(publicKeys: publicKeys);

  static DahlunasClient client({DahlunasClient Function()? create}) =>
      create?.call() ?? DahlunasClient(baseUri: apiBase);
}
