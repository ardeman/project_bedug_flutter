import 'dart:convert';
import 'dart:typed_data';

/// Unpadded Base32 (RFC 4648) shared by unlock codes and activations.
abstract final class DahlunasBase32 {
  static const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Uppercases ASCII letters and drops spaces, tabs, CR and LF.
  static String normalizeAscii(String input) {
    if (utf8.encode(input).length > 512) return '';
    return String.fromCharCodes([
      for (final unit in input.codeUnits)
        if (unit != 0x20 && unit != 0x09 && unit != 0x0D && unit != 0x0A)
          unit >= 0x61 && unit <= 0x7A ? unit - 0x20 : unit,
    ]);
  }

  static Uint8List? decodeBody(String body, int byteLength) {
    final bitsNeeded = byteLength * 8;
    final charsNeeded = (bitsNeeded + 4) ~/ 5;
    if (body.length != charsNeeded) return null;
    final bytes = Uint8List(byteLength);
    var buffer = 0;
    var bits = 0;
    var index = 0;
    for (final char in body.split('')) {
      final value = alphabet.indexOf(char);
      if (value < 0) return null;
      buffer = (buffer << 5 | value) & 0xFFFF;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        if (index >= byteLength) return null;
        bytes[index++] = buffer >> bits & 0xFF;
      }
    }
    return index == byteLength && bits == 0 ? bytes : null;
  }

  static String encode(List<int> bytes) {
    final out = StringBuffer();
    var buffer = 0;
    var bits = 0;
    for (final byte in bytes) {
      buffer = (buffer << 8 | byte) & 0xFFFF;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.write(alphabet[buffer >> bits & 0x1F]);
      }
    }
    // Unlock and activation envelopes are exact multiples of 5 bits.
    return out.toString();
  }

  static List<int> hex(String value) => [
    for (var i = 0; i + 1 < value.length; i += 2)
      int.parse(value.substring(i, i + 2), radix: 16),
  ];
}
