import 'package:bedug/features/infaq/dahlunas_activation.dart';
import 'package:bedug/features/infaq/dahlunas_base32.dart';
import 'package:bedug/features/infaq/dahlunas_client.dart';
import 'package:bedug/features/infaq/dahlunas_unlock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Fixture from Dahlunas `docs/code-format.md` (project 1 — unlock shape only).
const _unlockPublicKey =
    '008c7deff2cbf3a7a1a584bcd07688840e98a21e79758af3d14dae5f60c44c1f';
const _unlockCanonical =
    'DL1.AEAQAAIAAEAQEAYEAUDAOCAJBIFQYDIOB4IAAACRBYIBSQIHQTFDZHGEMZNXGYM42TXYHEJBIKITDDAZYRSQNKCYNM52JLTMUTVMZTGGYJDXMOVISMS4ZJBSFW7E262RZBFJWNGXPJFGC5AI';

/// Fixture from Dahlunas `docs/activation.md` (project 2).
const _activationPublicKey =
    '03a107bff3ce10be1d70dd18e74bc09967e4d6309ba50d5f1ddc8664125531b8';
const _activationInstallId = '000102030405060708090a0b0c0d0e0f';
const _activationCodeIdHex = '0102030405060708090a0b0c0d0e0f10';
const _activationCanonical =
    'DA1.AEAQAAQBAIBQIBIGA4EASCQLBQGQ4DYQ2ZO7RH3QF3WFRSR4PPZAAHE77R6NQBKTVYA5IKTZTORGOVQUFWLAAACRCBLKDC75ZPO3ZHAXJRM4UJXCRSML45BMOTSEOX5KTE27G7AOG4UA5A2S4TG6WABQDI4YAZ5VOIDBGAQPHGBN2RBWVRMQIF6NUCR3O6IK';

void main() {
  group('DahlunasUnlock', () {
    final unlock = DahlunasUnlock(
      project: 1,
      products: const {1},
      publicKeys: {1: DahlunasBase32.hex(_unlockPublicKey)},
    );

    test('accepts the code-format fixture and grouping variants', () async {
      expect(await unlock.verify(_unlockCanonical), _unlockCanonical);
      expect(
        await unlock.verify(
          'dl1.${_unlockCanonical.substring(4).toLowerCase()}',
        ),
        _unlockCanonical,
      );
      final body = _unlockCanonical.substring(4);
      final grouped = StringBuffer('DL1.');
      for (var i = 0; i < body.length; i += 8) {
        if (i > 0) grouped.write('-');
        grouped.write(body.substring(i, i + 8));
      }
      expect(await unlock.verify(grouped.toString()), _unlockCanonical);
    });

    test('rejects a changed character and the wrong project', () async {
      final tweaked = _unlockCanonical.replaceRange(10, 11, 'B');
      expect(await unlock.verify(tweaked), isNull);
      final bedug = DahlunasUnlock.bedug(
        publicKeys: {1: DahlunasBase32.hex(_unlockPublicKey)},
      );
      expect(await bedug.verify(_unlockCanonical), isNull);
    });
  });

  group('DahlunasActivation', () {
    final activation = DahlunasActivation(
      project: 2,
      publicKeys: {1: DahlunasBase32.hex(_activationPublicKey)},
    );
    final codeId = DahlunasBase32.hex(_activationCodeIdHex);

    test('accepts the activation fixture for its install ID', () async {
      expect(
        await activation.verify(
          input: _activationCanonical,
          installId: _activationInstallId,
          codeId: codeId,
        ),
        _activationCanonical,
      );
    });

    test(
      'rejects another install ID, DL1 prefix and a changed character',
      () async {
        expect(
          await activation.verify(
            input: _activationCanonical,
            installId: 'ffffffffffffffffffffffffffffffff',
            codeId: codeId,
          ),
          isNull,
        );
        expect(
          await activation.verify(
            input: _unlockCanonical,
            installId: _activationInstallId,
            codeId: codeId,
          ),
          isNull,
        );
        final tweaked = _activationCanonical.replaceRange(12, 13, 'B');
        expect(
          await activation.verify(
            input: tweaked,
            installId: _activationInstallId,
            codeId: codeId,
          ),
          isNull,
        );
      },
    );
  });

  group('DahlunasClient', () {
    test('parses success and move_limit', () async {
      final ok = DahlunasClient(
        baseUri: Uri.parse('https://example.test'),
        httpClient: MockClient(
          (_) async =>
              http.Response('{"activation":"DA1.TEST","moves_left":2}', 200),
        ),
      );
      final result = await ok.activate(
        code: 'DL1.X',
        installId: _activationInstallId,
        move: true,
      );
      expect(
        result,
        isA<DahlunasActivationOk>()
            .having((r) => r.activation, 'activation', 'DA1.TEST')
            .having((r) => r.movesLeft, 'movesLeft', 2),
      );

      final limited = DahlunasClient(
        baseUri: Uri.parse('https://example.test'),
        httpClient: MockClient(
          (_) async =>
              http.Response('{"error":"move_limit","moves_left":0}', 409),
        ),
      );
      final limit = await limited.activate(
        code: 'DL1.X',
        installId: _activationInstallId,
        move: true,
      );
      expect(
        limit,
        isA<DahlunasActivationError>()
            .having((r) => r.code, 'code', 'move_limit')
            .having((r) => r.movesLeft, 'movesLeft', 0),
      );
    });
  });
}
