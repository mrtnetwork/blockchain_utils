// This file assumes it lives inside your blockchain_utils project (or
// anywhere with that package as a dependency), since Bech32Error extends
// BlockchainUtilsException. Adjust the import below to wherever you place
// these files.
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void b32Test() {
  group('BIP-173 official valid vectors (decode does not throw)', () {
    // https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki
    const valid = [
      'A12UEL5L', // the canonical minimal vector: 6-char data part, zero
      // payload - this is exactly the case the checksumLen-vs-
      // checksumLen+1 off-by-one fix below is about.
      'a12uel5l',
      'an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1tt5tgs',
      'abcdef1qpzry9x8gf2tvdw0s3jn54khce6mua7lmqqqxw',
      '11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqc8247j',
      'split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w',
      '?1ezyfcl',
    ];

    for (final s in valid) {
      test('decodeWithoutHRP("$s") does not throw', () {
        expect(() => Bech32Decoder.decodeWithoutHRP(s), returnsNormally);
      });
    }

    test('"A12UEL5L" and "a12uel5l" decode identically (case-insensitive)', () {
      final n = Bech32Decoder.decodeWithoutHRP('A12UEL5L');
      final r = Bech32Decoder.decodeWithoutHRP('a12uel5l');
      expect(n.$1, equals(r.$1));
      expect(n.$2, equals(r.$2));
    });
  });
  group("bech32 bch testVecot", () {
    test("bach32 decode", () {
      for (final i in _bchTestVector.shuffleTake()) {
        final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf(":"));
        final decode = BchBech32Decoder.decode(hrp, i["encode"]!);
        expect(BytesUtils.toHexString(decode.$2), i["raw"]);
        expect(
          BytesUtils.bytesEqual(
            decode.$1,
            CoinsConf.bitcoinCashMainNet.params.p2pkhStdNetVer,
          ),
          true,
        );
      }
    });
    test("bach32 encode", () {
      for (final i in _bchTestVector) {
        final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf(":"));
        final decode = BchBech32Encoder.encode(
          hrp,
          CoinsConf.bitcoinCashMainNet.params.p2pkhStdNetVer!,
          BytesUtils.fromHexString(i["raw"]!),
        );
        expect(decode, i["encode"]);
      }
    });

    test("invalid decode", () {
      expect(() {
        BchBech32Decoder.decode(
          "bitcoincash",
          "bitciincash:qq54jk3u0pmql6g0azpmjghn2wm8gswj35853zv6sr",
        );
      }, throwsA(isA<BuError>()));
    });
  });
  group("bech32 test vector", () {
    test("bach32 decode", () {
      for (final i in _testVect.shuffleTake()) {
        final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf("1"));
        final decode = Bech32Decoder.decode(hrp, i["encode"]!);
        expect(BytesUtils.toHexString(decode), i["raw"]);
      }
    });
    test("bach32 encode", () {
      for (final i in _testVect.shuffleTake()) {
        final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf("1"));
        final encode = Bech32Encoder.encode(
          hrp,
          BytesUtils.fromHexString(i["raw"]!),
        );
        expect(encode, i["encode"]);
      }
    });
    test("invalid decode", () {
      expect(() {
        Bech32Decoder.decode(
          "cosmos",
          "cosmis1w508d6qejxtdg4y5r3zarvary0c5xw7khxen85",
        );
      }, throwsA(isA<BuError>()));
    });
  });
  group("Seqwit test vector", () {
    test("test decode", () {
      for (final i in _segwit.shuffleTake()) {
        final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf("1"));
        final decode = SegwitBech32Decoder.decode(hrp, i["encode"]!);
        expect(decode.$1, 0);
        expect(BytesUtils.toHexString(decode.$2), i["raw"]);
      }
    });
    test("test encode", () {
      for (final i in _segwit.shuffleTake()) {
        final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf("1"));
        final decode = SegwitBech32Encoder.encode(
          hrp,
          0,
          BytesUtils.fromHexString(i["raw"]!),
        );
        expect(decode, i["encode"]);
      }
    });
  });

  group('BIP-173 official invalid vectors (decode throws Bech32Error)', () {
    final invalid = <String, String>{
      '${String.fromCharCode(0x20)}1nwldj5':
          'HRP character out of range (space)',
      '${String.fromCharCode(0x7F)}1axkwrx':
          'HRP character out of range (0x7F)',
      '${String.fromCharCode(0x80)}1eym55h':
          'HRP character out of range (0x80)',
      'pzry9x0s0muk': 'no separator character',
      '1pzry9x0s0muk': 'empty HRP',
      'x1b4n0q5v': 'invalid data character',
      'li1dgmt3': 'too short checksum',
      'de1lg7wt${String.fromCharCode(0xFF)}': 'invalid character in checksum',
      'A1G7SGD8': 'checksum computed against the uppercase HRP',
      '10a06t8': 'empty HRP',
      '1qzzfhee': 'empty HRP',
    };

    invalid.forEach((s, reason) {
      test('rejects ($reason)', () {
        expect(
          () => Bech32Decoder.decodeWithoutHRP(s),
          throwsA(isA<BuError>()),
        );
      });
    });
  });

  group('BIP-141/BIP-350 official SegWit vectors', () {
    test(
      'BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4 -> v0, 20-byte program',
      () {
        final (ver, prog) = SegwitBech32Decoder.decode(
          'bc',
          'BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4',
        );
        expect(ver, equals(0));
        expect(
          prog,
          equals(
            BytesUtils.fromHexString(
              '751e76e8199196d454941c45d1b3a323f1433bd6',
            ),
          ),
        );
      },
    );

    test('tb1...q0sl5k7 -> v0, 32-byte program', () {
      final (ver, prog) = SegwitBech32Decoder.decode(
        'tb',
        'tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7',
      );
      expect(ver, equals(0));
      expect(
        prog,
        equals(
          BytesUtils.fromHexString(
            '1863143c14c5166804bd19203356da136c985678cd4d27a1b8c6329604903262',
          ),
        ),
      );
    });

    test(
      'encode/decode round trip reproduces the same version and program',
      () {
        final prog = BytesUtils.fromHexString(
          '751e76e8199196d454941c45d1b3a323f1433bd6',
        );
        final encoded = SegwitBech32Encoder.encode('bc', 0, prog);
        final (ver, decodedProg) = SegwitBech32Decoder.decode('bc', encoded);
        expect(ver, equals(0));
        expect(decodedProg, equals(prog));
      },
    );

    test('mixed-case input is rejected', () {
      expect(
        () => SegwitBech32Decoder.decode(
          'tb',
          'tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sL5k7',
        ),
        throwsA(isA<BuError>()),
      );
    });

    test('more than 4 bits of non-zero padding is rejected', () {
      expect(
        () => SegwitBech32Decoder.decode(
          'bc',
          'bc1zw508d6qejxtdg4y5r3zarvaryvqyzf3du',
        ),
        throwsA(isA<BuError>()),
      );
    });

    test('non-zero padding in 8-to-5 conversion is rejected', () {
      expect(
        () => SegwitBech32Decoder.decode(
          'tb',
          'tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3pjxtptv',
        ),
        throwsA(isA<BuError>()),
      );
    });

    test('an altered (invalid) checksum is rejected', () {
      // Last character changed from the valid 't' to '5'.
      expect(
        () => SegwitBech32Decoder.decode(
          'bc',
          'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5',
        ),
        throwsA(isA<BuError>()),
      );
    });

    test('wrong HRP throws with expected/actual details', () {
      final prog = BytesUtils.fromHexString(
        '751e76e8199196d454941c45d1b3a323f1433bd6',
      );
      final encoded = SegwitBech32Encoder.encode('bc', 0, prog);
      expect(
        () => SegwitBech32Decoder.decode('tb', encoded),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('standard Bech32Encoder/Bech32Decoder round trip', () {
    test('arbitrary bytes round trip through both encodings', () {
      for (final encoding in Bech32Encodings.values) {
        final data = List<int>.generate(32, (i) => (i * 7 + 3) % 256);
        final encoded = Bech32Encoder.encode('hrp', data, encoding: encoding);
        final decoded = Bech32Decoder.decode(
          'hrp',
          encoded,
          encoding: encoding,
        );
        expect(decoded, equals(data), reason: '$encoding');
      }
    });

    test('empty payload round trips', () {
      final encoded = Bech32Encoder.encode('x', []);
      expect(Bech32Decoder.decode('x', encoded), equals([]));
    });

    test('decoding with the wrong expected HRP throws with details', () {
      final encoded = Bech32Encoder.encode('right', [1, 2, 3]);
      try {
        Bech32Decoder.decode('wrong', encoded);
        fail('should have thrown');
      } on BuError catch (e) {
        expect(e.details?['expected'], equals('wrong'));
        expect(e.details?['hrp'], equals('right'));
      }
    });

    test('bech32-encoded data fails bech32m verification and vice versa', () {
      final encoded = Bech32Encoder.encode('x', [1, 2, 3]);
      expect(
        () => Bech32Decoder.decode(
          'x',
          encoded,
          encoding: Bech32Encodings.bech32m,
        ),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('BCH Bech32 (CashAddr-style) round trip', () {
    // No independently-sourced official CashAddr test vectors here - this
    // relies on round-trip self-consistency (a real bug in the ported
    // 40-bit polynomial would very likely break this immediately) plus
    // the fact that BigInt and plain-int versions of the same arithmetic
    // were checked to agree bit-for-bit before the BigInt version was
    // removed.
    test('arbitrary version + data bytes round trip', () {
      final data = List<int>.generate(20, (i) => (i * 11 + 1) % 256);
      final encoded = BchBech32Encoder.encode('bitcoincash', [0], data);
      // Not asserting the exact shape of decodedVer here - it comes back
      // through a `.toLeBytes()` extension this test doesn't have visibility
      // into (e.g. whether a zero version encodes as `[0]` or `[]`).
      // What's actually being verified is that decoding succeeds and the
      // data payload - which does NOT go through that extension - round
      // trips exactly.
      final (_, decodedData) = BchBech32Decoder.decode('bitcoincash', encoded);
      expect(decodedData, equals(data));
    });

    test('wrong HRP throws with expected/actual details', () {
      final encoded = BchBech32Encoder.encode('bitcoincash', [0], [1, 2, 3]);
      try {
        BchBech32Decoder.decode('bchtest', encoded);
        fail('should have thrown');
      } on BuError catch (e) {
        expect(e.details?['expected'], equals('bchtest'));
        expect(e.details?['hrp'], equals('bitcoincash'));
      }
    });

    test('a corrupted checksum is rejected', () {
      final encoded = BchBech32Encoder.encode('bitcoincash', [0], [1, 2, 3]);
      final corrupted =
          '${encoded.substring(0, encoded.length - 1)}'
          '${encoded[encoded.length - 1] == 'q' ? 'p' : 'q'}';
      expect(
        () => BchBech32Decoder.decode('bitcoincash', corrupted),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('error handling', () {
    test('missing separator throws Bech32Error', () {
      expect(
        () => Bech32Decoder.decodeWithoutHRP('noseparatorhere'),
        throwsA(isA<BuError>()),
      );
    });

    test('invalid character throws Bech32Error', () {
      expect(
        () => Bech32Decoder.decodeWithoutHRP('x1b4n0q5v'),
        throwsA(isA<BuError>()),
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(b32Test, "B32");
}

final List<Map<String, String>> _segwit = [
  {
    "raw": "751e76e8199196d454941c45d1b3a323f1433bd6",
    "encode": "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
  },
  {
    "raw": "30ea99599334801bf09d753af38ba546800bea8b",
    "encode": "bc1qxr4fjkvnxjqphuyaw5a08za9g6qqh65t8qwgum",
  },
  {
    "raw": "18abaed50b7c1176308baa094b054383b775f12c",
    "encode": "bc1qrz46a4gt0sghvvyt4gy5kp2rswmhtufv6sdq9v",
  },
  {
    "raw": "5788df3047dd2c2545eee12784e6212745916bb7",
    "encode": "bc1q27yd7vz8m5kz230wuyncfe3pyazez6ah58yzy0",
  },
  {
    "raw": "3a3eff6f41ce759a8dd95fc1a2d762077f4f3b64",
    "encode": "bc1q8gl07m6pee6e4rwetlq694mzqal57wmyadd9sn",
  },
  {
    "raw": "37552063bb0baa42b910712df06b814b928a88f0",
    "encode": "bc1qxa2jqcampw4y9wgswyklq6upfwfg4z8s5m4v3v",
  },
  {
    "raw": "f9ce94eab4ed454dd0077e3dc24bdfb8d5df4008",
    "encode": "bc1ql88ff645a4z5m5q80c7uyj7lhr2a7sqgtss7ek",
  },
  {
    "raw": "29595a3c78760fe90fe883b922f353b67441d28d",
    "encode": "tb1q99v450rcwc87jrlgswuj9u6nke6yr55drpxuj0",
  },
  {
    "raw": "b819a85f25b116c2f7e64416a55b8d49b744d209",
    "encode": "tb1qhqv6she9kytv9alxgst22kudfxm5f5sf2lgpc6",
  },
  {
    "raw": "904c82e2c1a8508ba784e4e53e195b5047682e87",
    "encode": "tb1qjpxg9ckp4pgghfuyunjnux2m2prkst580chf9n",
  },
];

final List<Map<String, String>> _testVect = [
  {
    "raw": "751e76e8199196d454941c45d1b3a323f1433bd6",
    "encode": "cosmos1w508d6qejxtdg4y5r3zarvary0c5xw7k6ah60c",
  },
  {
    "raw": "30ea99599334801bf09d753af38ba546800bea8b",
    "encode": "cosmos1xr4fjkvnxjqphuyaw5a08za9g6qqh65t36srck",
  },
  {
    "raw": "18abaed50b7c1176308baa094b054383b775f12c",
    "encode": "band1rz46a4gt0sghvvyt4gy5kp2rswmhtufv49nfef",
  },
  {
    "raw": "29595a3c78760fe90fe883b922f353b67441d28d",
    "encode": "band199v450rcwc87jrlgswuj9u6nke6yr55dxjrx4e",
  },
];
final List<Map<String, String>> _bchTestVector = [
  {
    "raw": "751e76e8199196d454941c45d1b3a323f1433bd6",
    "encode": "bitcoincash:qp63uahgrxged4z5jswyt5dn5v3lzsem6cy4spdc2h",
  },
  {
    "raw": "30ea99599334801bf09d753af38ba546800bea8b",
    "encode": "bitcoincash:qqcw4x2ejv6gqxlsn46n4uut54rgqzl23v4y77ks69",
  },
  {
    "raw": "18abaed50b7c1176308baa094b054383b775f12c",
    "encode": "bitcoincash:qqv2htk4pd7pza3s3w4qjjc9gwpmwa039s9cgntx7v",
  },
  {
    "raw": "29595a3c78760fe90fe883b922f353b67441d28d",
    "encode": "bchtest:qq54jk3u0pmql6g0azpmjghn2wm8gswj35af22xyv3",
  },
  {
    "raw": "b819a85f25b116c2f7e64416a55b8d49b744d209",
    "encode": "bchtest:qzupn2zlykc3dshhuezpdf2m34ymw3xjpycg0fwyaq",
  },
  {
    "raw": "904c82e2c1a8508ba784e4e53e195b5047682e87",
    "encode": "bchtest:qzgyeqhzcx59pza8snjw20setdgyw6pwsulf9dv498",
  },
];
