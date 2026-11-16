import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'dahlunas_base32.dart';

/// Offline check for Dahlunas unlock codes (`DL1.`), project 2 (Bedug).
///
/// Contract: Dahlunas `docs/code-format.md`.
class DahlunasUnlock {
  const DahlunasUnlock({
    required this.project,
    required this.products,
    required this.publicKeys,
  });

  /// Bedug: project 2, product 1 (every infaq tier), sandbox key 1.
  factory DahlunasUnlock.bedug({required Map<int, List<int>> publicKeys}) =>
      DahlunasUnlock(project: 2, products: const {1}, publicKeys: publicKeys);

  final int project;
  final Set<int> products;
  final Map<int, List<int>> publicKeys;

  static const prefix = 'DL1.';
  static const _payloadLength = 26;
  static const _envelopeLength = 90;
  static const _domain = 'Dahlunas/unlock/v1';

  /// Canonical `DL1.…` text when genuine, else null.
  Future<String?> verify(String input) async {
    final envelope = decode(input);
    if (envelope == null) return null;
    final data = ByteData.sublistView(envelope);
    final version = data.getUint8(0);
    final keyId = data.getUint8(1);
    final codeProject = data.getUint16(2);
    final product = data.getUint16(4);
    final codeId = envelope.sublist(6, 22);
    if (version != 1 ||
        keyId == 0 ||
        codeProject == 0 ||
        codeProject != project ||
        product == 0 ||
        !products.contains(product) ||
        codeId.every((byte) => byte == 0)) {
      return null;
    }
    final key = publicKeys[keyId];
    if (key == null || key.length != 32) return null;
    final payload = envelope.sublist(0, _payloadLength);
    final genuine = await Ed25519().verify(
      [...ascii.encode(_domain), 0, ...payload],
      signature: Signature(
        envelope.sublist(_payloadLength),
        publicKey: SimplePublicKey(key, type: KeyPairType.ed25519),
      ),
    );
    return genuine ? '$prefix${DahlunasBase32.encode(envelope)}' : null;
  }

  /// The 16-byte code ID from a verified canonical code, or null.
  static Uint8List? codeIdOf(String canonical) {
    final envelope = decode(canonical);
    return envelope?.sublist(6, 22);
  }

  static Uint8List? decode(String input) {
    final upper = DahlunasBase32.normalizeAscii(input);
    if (upper.isEmpty || !upper.startsWith(prefix)) return null;
    final body = upper.substring(prefix.length).replaceAll('-', '');
    return DahlunasBase32.decodeBody(body, _envelopeLength);
  }
}
