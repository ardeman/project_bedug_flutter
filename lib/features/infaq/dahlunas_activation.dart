import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'dahlunas_base32.dart';

/// Offline check for Dahlunas device activations (`DA1.`).
///
/// Contract: Dahlunas `docs/activation.md`.
class DahlunasActivation {
  const DahlunasActivation({required this.project, required this.publicKeys});

  factory DahlunasActivation.bedug({required Map<int, List<int>> publicKeys}) =>
      DahlunasActivation(project: 2, publicKeys: publicKeys);

  final int project;
  final Map<int, List<int>> publicKeys;

  static const prefix = 'DA1.';
  static const _payloadLength = 56;
  static const _envelopeLength = 120;
  static const _domain = 'Dahlunas/activation/v1';

  /// Canonical `DA1.…` when genuine for [installId] and [codeId], else null.
  Future<String?> verify({
    required String input,
    required String installId,
    required List<int> codeId,
  }) async {
    if (codeId.length != 16) return null;
    final device = await _deviceHash(installId);
    if (device == null) return null;
    final envelope = decode(input);
    if (envelope == null) return null;
    final data = ByteData.sublistView(envelope);
    final version = data.getUint8(0);
    final keyId = data.getUint8(1);
    final codeProject = data.getUint16(2);
    final payloadCodeId = envelope.sublist(4, 20);
    final payloadDevice = envelope.sublist(20, 52);
    if (version != 1 ||
        keyId == 0 ||
        codeProject == 0 ||
        codeProject != project ||
        !_same(payloadCodeId, codeId) ||
        !_same(payloadDevice, device)) {
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

  static Uint8List? decode(String input) {
    final upper = DahlunasBase32.normalizeAscii(input);
    if (upper.isEmpty || !upper.startsWith(prefix)) return null;
    final body = upper.substring(prefix.length).replaceAll('-', '');
    return DahlunasBase32.decodeBody(body, _envelopeLength);
  }

  static Future<Uint8List?> _deviceHash(String installId) async {
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(installId)) return null;
    final digest = await Sha256().hash(ascii.encode(installId));
    return Uint8List.fromList(digest.bytes);
  }

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
