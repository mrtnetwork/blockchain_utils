import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../../utils.dart';

void xtzTest() {
  group('XtzAddrEncoder / XtzAddrDecoder — real test vectors', () {
    // ------------------------------------------------------------------
    // encodeKey: raw public key bytes -> Tezos address
    // ------------------------------------------------------------------
    group('encodeKey', () {
      for (final v in testVecotr) {
        final t = v['type'] as XtzAddrPrefixes;

        test('${t.name} — ${v['address']}', () {
          final pubKey = Base58Decoder.decodeWithChecksum(v['Base58']);
          final got = XtzAddrEncoder().encodeKey(
            pubKey.sublist(4),
            addressPrefix: t,
          );
          expect(got, v['address']);
        });
      }
    });

    // ------------------------------------------------------------------
    // decodeAddr: Base58 address -> 20-byte Blake2b-160 hash
    // ------------------------------------------------------------------
    group('decodeAddr', () {
      for (final v in testVecotr) {
        final t = v['type'] as XtzAddrPrefixes;
        test('${t.name} — ${v['address']}', () {
          final got = XtzAddrDecoder().decodeAddr(
            v['address'] as String,
            addressPrefix: t,
          );
          expect(got.toHex(), v['decode']);
        });
      }
    });

    // ------------------------------------------------------------------
    // encode: 20-byte hash -> Base58 address
    // ------------------------------------------------------------------
    group('encode', () {
      for (final v in testVecotr) {
        final t = v['type'] as XtzAddrPrefixes;
        test('${t.name} — ${v['address']}', () {
          final hash = BytesUtils.fromHexString(v['decode'] as String);
          final got = XtzAddrEncoder().encode(hash, addressPrefix: t);
          expect(got.address, v['address']);
        });
      }
    });

    // ------------------------------------------------------------------
    // Round-trip: hash -> encode -> decode -> hash
    // ------------------------------------------------------------------
    group('round-trip', () {
      for (final v in testVecotr) {
        final t = v['type'] as XtzAddrPrefixes;
        test('${t.name} — ${v['address']}', () {
          final hash = BytesUtils.fromHexString(v['decode'] as String);
          final encode = XtzAddrEncoder().encode(hash, addressPrefix: t);
          final decoded = XtzAddrDecoder().decodeAddr(
            encode.address,
            addressPrefix: t,
          );
          expect(decoded.toHex(), v['decode']);
          expect(encode.type, t);
        });
      }
    });

    // ------------------------------------------------------------------
    // Auto-detection (omit the type hint)
    // ------------------------------------------------------------------
    group('prefix auto-detection', () {
      for (final v in testVecotr) {
        final t = v['type'] as XtzAddrPrefixes;
        test('${t.name} — ${v['address']}', () {
          final decoded = XtzAddrDecoder().decodeAddr(v['address'] as String);
          expect(decoded.toHex(), v['decode']);
        });
      }
    });

    // ------------------------------------------------------------------
    // Error cases
    // ------------------------------------------------------------------
    group('error cases', () {
      test('type mismatch throws AddressConverterException', () {
        expect(
          () => XtzAddrDecoder().decodeAddr(
            'tz1ipB38oB5F76HnbTRqWPLEnVtCgj6yf2nB',
            addressPrefix: XtzAddrPrefixes.tz2,
          ),
          throwsA(isA<BuError>()),
        );
      });

      test('invalid base58 string throws', () {
        expect(() => XtzAddrDecoder().decodeAddr('tz1!!!'), throwsA(anything));
      });

      test('wrong hash length throws', () {
        expect(
          () => XtzAddrEncoder().encode(
            [0x00, 0x01, 0x02], // 3 bytes, not 20
            addressPrefix: XtzAddrPrefixes.tz1,
          ),
          throwsA(isA<BuError>()),
        );
      });
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(xtzTest, "Xtz");
}
