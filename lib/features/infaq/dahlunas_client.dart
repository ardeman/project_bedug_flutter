import 'dart:convert';

import 'package:http/http.dart' as http;

/// Answers from `POST /activations` (Dahlunas `docs/activation.md`).
sealed class DahlunasActivationResult {
  const DahlunasActivationResult();
}

final class DahlunasActivationOk extends DahlunasActivationResult {
  const DahlunasActivationOk({
    required this.activation,
    required this.movesLeft,
  });

  final String activation;
  final int movesLeft;
}

final class DahlunasActivationError extends DahlunasActivationResult {
  const DahlunasActivationError(this.code, {this.movesLeft});

  /// `moved`, `move_limit`, `invalid`, `not_supported`, `busy`, or `network`.
  final String code;
  final int? movesLeft;
}

/// HTTP client for Dahlunas device activation.
class DahlunasClient {
  DahlunasClient({required this.baseUri, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final Uri baseUri;
  final http.Client _http;

  Uri get activationsUri => baseUri.resolve('/activations');

  Future<DahlunasActivationResult> activate({
    required String code,
    required String installId,
    required bool move,
  }) async {
    try {
      final response = await _http
          .post(
            activationsUri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': code,
              'install_id': installId,
              'move': move,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final body = _json(response.body);
      final moves = body == null ? null : _int(body['moves_left']);
      switch (response.statusCode) {
        case 200:
          final activation = body?['activation'];
          if (activation is! String || activation.isEmpty || moves == null) {
            return const DahlunasActivationError('invalid');
          }
          return DahlunasActivationOk(activation: activation, movesLeft: moves);
        case 409:
          final error = body?['error'];
          if (error == 'moved' || error == 'move_limit') {
            return DahlunasActivationError(error as String, movesLeft: moves);
          }
          return const DahlunasActivationError('invalid');
        case 400:
          return const DahlunasActivationError('invalid');
        case 404:
          return const DahlunasActivationError('not_supported');
        case 429:
        case 503:
          return const DahlunasActivationError('busy');
        default:
          return const DahlunasActivationError('busy');
      }
    } on Object {
      return const DahlunasActivationError('network');
    }
  }

  static Map<String, Object?>? _json(String raw) {
    try {
      final value = jsonDecode(raw);
      return value is Map<String, Object?>
          ? value
          : value is Map
          ? value.cast<String, Object?>()
          : null;
    } on Object {
      return null;
    }
  }

  static int? _int(Object? value) => switch (value) {
    int n => n,
    num n => n.toInt(),
    _ => null,
  };
}
