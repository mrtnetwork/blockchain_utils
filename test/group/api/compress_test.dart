// ignore_for_file: depend_on_referenced_packages

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  BlockchainUtilsTestApi.runTest(
    () {},
    "compress",
    onNative: (_) {
      group('compressed/uncompressed round-trips', () {
        test('secp256k1 weierstrass', () {
          final api = WeierstrassSecp256k1CurveApi();
          expect(api.uncompressedLen, 65);
          final g = api.generator();
          final u = api.uncompress(g);
          expect(u.length, 65);
          expect(u[0], 0x04);
          expect(api.compress(u), g);
          expect(api.compress(g), g);
          // infinity both ways
          final id = api.identity();
          expect(id, List.filled(33, 0));
          final idU = api.uncompress(id);
          expect(idU, List.filled(65, 0));
          expect(api.compress(idU), id);
          // garbage rejected
          expect(() => api.compress(List.filled(33, 0xFF)), throwsA(anything));
          expect(() => api.uncompress([1, 2, 3]), throwsA(anything));
        });

        test('secp256r1 weierstrass', () {
          final api = WeierstrassSecp256r1CurveApi();
          expect(api.uncompressedLen, 65);
          final g = api.generator();
          final u = api.uncompress(g);
          expect(u.length, 65);
          expect(api.compress(u), g);
          expect(api.uncompress(api.identity()), List.filled(65, 0));
        });

        test('BLS G1 dart', () {
          final api = DartG1ProjectiveCurveApi();
          expect(api.uncompressedLen, 96);
          final g = api.generator();
          expect(g.length, 48);
          final u = api.uncompress(g);
          expect(u.length, 96);
          expect(api.compress(u), g);
          expect(api.compress(g), g);
        });

        test('BLS G2 dart', () {
          final api = DartG2ProjectiveCurveApi();
          expect(api.uncompressedLen, 192);
          final g = api.generator();
          expect(g.length, 96);
          final u = api.uncompress(g);
          expect(u.length, 192);
          expect(api.compress(u), g);
        });
      });

      // Needs both implementations (Dart + native): skip on the pure-Dart
      // backend instead of crashing on `blockchainUtils.backend!`.
      group('native backends',
          skip: blockchainUtils.hasNativeBackend
              ? null
              : 'native backend not active', () {
        test('secp256k1 native', () {
          final api = NativeSecp256k1CurveApi(
            blockchainUtils.backend!.curves.secp256k1(),
          );
          expect(api.uncompressedLen, 65);
          final g = api.generator();
          final u = api.uncompress(g);
          expect(u.length, 65);
          expect(api.compress(u), g);
        });

        test('secp256r1 native', () {
          final api = NativeSecp256r1CurveApi(
            blockchainUtils.backend!.curves.secp256r1(),
          );
          final u = api.uncompress(api.generator());
          expect(u.length, 65);
          expect(api.compress(u), api.generator());
        });

        test('BLS native', () {
          final g1 = NativeG1ProjectiveCurveApi(
            blockchainUtils.backend!.curves.g1(),
          );
          final u1 = g1.uncompress(g1.generator());
          expect(u1.length, 96);
          expect(g1.compress(u1), g1.generator());
          final g2 = NativeG2ProjectiveCurveApi(
            blockchainUtils.backend!.curves.g2(),
          );
          final u2 = g2.uncompress(g2.generator());
          expect(u2.length, 192);
          expect(g2.compress(u2), g2.generator());
        });
      });
    },
  );
}