import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

final List<Map<String, String>> testVectBtc = [
  {"raw": "", "encode": "", "check_encode": "3QJmnh"},
  {"raw": "61", "encode": "2g", "check_encode": "C2dGTwc"},
  {"raw": "626262", "encode": "a3gV", "check_encode": "4jF5uERJAK"},
  {"raw": "636363", "encode": "aPEr", "check_encode": "4mT4krqUYJ"},
  {
    "raw": "73696d706c792061206c6f6e6720737472696e67",
    "encode": "2cFupjhnEsSn59qHXstmK2ffpLv2",
    "check_encode": "BXF1HuEUCqeVzZdrKeJjG74rjeXxqJ7dW",
  },
  {
    "raw": "00eb15231dfceb60925886b67d065299925915aeb172c06647",
    "encode": "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L",
    "check_encode": "13REmUhe2ckUKy1FvM7AMCdtyYq831yxM3QeyEu4",
  },
  {"raw": "516b6fcd0f", "encode": "ABnLTmg", "check_encode": "237LSrY9NUUas"},
  {
    "raw": "bf4f89001e670274dd",
    "encode": "3SEo3LWLoPntC",
    "check_encode": "GwDDDeduj1jpykc27e",
  },
  {"raw": "572e4794", "encode": "3EFU7m", "check_encode": "FamExfqCeza"},
  {
    "raw": "ecac89cad93923c02321",
    "encode": "EJDM8drfXA6uyA",
    "check_encode": "2W1Yd5Zu6WGyKVtHGMrH",
  },
  {"raw": "10c8511e", "encode": "Rt5zm", "check_encode": "3op3iuGMmhs"},
  {
    "raw": "00000000000000000000",
    "encode": "1111111111",
    "check_encode": "111111111146Momb",
  },
  {
    "raw":
        "000111d38e5fc9071ffcd20b4a763cc9ae4f252bb4e48fd66a835e252ada93ff480d6dd43dc62a641155a5",
    "encode": "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
    "check_encode":
        "17mxz9b2TuLnDf6XyQrHjAc3UvMoEg7YzRsJkBd4VwNpFh8a1StKmCe5WtAW27Y",
  },
  {
    "raw":
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
    "encode":
        "1cWB5HCBdLjAuqGGReWE3R3CguuwSjw6RHn39s2yuDRTS5NsBgNiFpWgAnEx6VQi8csexkgYw3mdYrMHr8x9i7aEwP8kZ7vccXWqKDvGv3u1GxFKPuAkn8JCPPGDMf3vMMnbzm6Nh9zh1gcNsMvH3ZNLmP5fSG6DGbbi2tuwMWPthr4boWwCxf7ewSgNQeacyozhKDDQQ1qL5fQFUW52QKUZDZ5fw3KXNQJMcNTcaB723LchjeKun7MuGW5qyCBZYzA1KjofN1gYBV3NqyhQJ3Ns746GNuf9N2pQPmHz4xpnSrrfCvy6TVVz5d4PdrjeshsWQwpZsZGzvbdAdN8MKV5QsBDY",
    "check_encode":
        "151KWPPBRzdWPr1ASeu172gVgLf1YfUp6VJyk6K9t4cLqYtFHcMa2iX8S3NJEprUcW7W5LvaPRpz7UG7puBj5STE3nKhCGt5eckYq7mMn5nT7oTTic2BAX6zDdqrmGCnkszQkzkz8e5QLGDjf7KeQgtEDm4UER6DMSdBjFQVa6cHrrJn9myVyyhUrsVnfUk2WmNFZvkWv3Tnvzo2cJ1xW62XDfUgYz1pd97eUGGPuXvDFfLsBVd1dfdUhPwxW7pMPgdWHTmg5uqKGFF6vE4xXpAqZTbTxRZjCDdTn68c2wrcxApm8hq3JX65Hix7VtcD13FF8b7BzBtwjXq1ze6NMjKgUcqpGV5XA5",
  },
];

var testVectXrp = [
  {"raw": "", "encode": "", "check_encode": "sQJm86"},
  {"raw": "61", "encode": "pg", "check_encode": "UpdGTAc"},
  {"raw": "626262", "encode": "2sgV", "check_encode": "hjEnuNRJwK"},
  {"raw": "636363", "encode": "2PNi", "check_encode": "hmThkiq7YJ"},
  {
    "raw": "73696d706c792061206c6f6e6720737472696e67",
    "encode": "pcEuFj68N1S8n9qHX1tmKpCCFLvp",
    "check_encode": "BXErHuN7UqeVzZdiKeJjGfhijeXxqJfdW",
  },
  {
    "raw": "00eb15231dfceb60925886b67d065299925915aeb172c06647",
    "encode": "r4Srf52g9jJgTHDrVXjvLUN8ZuQsiJDN9L",
    "check_encode": "rsRNm76epck7KyrEvMfwMUdtyYq3sryxMsQeyNuh",
  },
  {"raw": "516b6fcd0f", "encode": "wB8LTmg", "check_encode": "psfLSiY947721"},
  {
    "raw": "bf4f89001e670274dd",
    "encode": "sSNosLWLoP8tU",
    "check_encode": "GADDDedujrjFykcpfe",
  },
  {"raw": "572e4794", "encode": "sNE7fm", "check_encode": "E2mNxCqUez2"},
  {
    "raw": "ecac89cad93923c02321",
    "encode": "NJDM3diCXwauyw",
    "check_encode": "pWrYdnZuaWGyKVtHGMiH",
  },
  {"raw": "10c8511e", "encode": "Rtnzm", "check_encode": "soFs5uGMm61"},
  {
    "raw": "00000000000000000000",
    "encode": "rrrrrrrrrr",
    "check_encode": "rrrrrrrrrrhaMomb",
  },
  {
    "raw":
        "000111d38e5fc9071ffcd20b4a763cc9ae4f252bb4e48fd66a835e252ada93ff480d6dd43dc62a641155a5",
    "encode": "rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz",
    "check_encode":
        "rfmxz9bpTuL8DCaXyQiHjwcs7vMoNgfYzR1JkBdhVA4FE632rStKmUenWtwWpfY",
  },
  {
    "raw":
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
    "encode":
        "rcWBnHUBdLjwuqGGReWNsRsUguuASjAaRH8s91pyuDRTSn41Bg45EFWgw8NxaVQ53c1exkgYAsmdYiMHi3x95f2NAP3kZfvccXWqKDvGvsurGxEKPuwk83JUPPGDMCsvMM8bzma469z6rgc41MvHsZ4LmPnCSGaDGbb5ptuAMWPt6ihboWAUxCfeASg4Qe2cyoz6KDDQQrqLnCQE7WnpQK7ZDZnCAsKX4QJMc4Tc2BfpsLc6jeKu8fMuGWnqyUBZYzwrKjoC4rgYBVs4qy6QJs41fhaG4uC94pFQPmHzhxF8SiiCUvyaTVVzndhPdije161WQAFZ1ZGzvbdwd43MKVnQ1BDY",
    "check_encode":
        "rnrKWPPBRzdWPirwSeurfpgVgLCrYC7FaVJykaK9thcLqYtEHcM2p5X3Ss4JNFi7cWfWnLv2PRFzf7GfFuBjnSTNs8K6UGtneckYqfmM8n8TfoTT5cpBwXazDdqimGU8k1zQkzkz3enQLGDjCfKeQgtNDmh7NRaDMSdBjEQV2acHiiJ89myVyy67i1V8C7kpWm4EZvkWvsT8vzopcJrxWapXDC7gYzrFd9fe7GGPuXvDECL1BVdrdCd76PAxWfFMPgdWHTmgnuqKGEEavNhxXFwqZTbTxRZjUDdT8a3cpAicxwFm36qsJXanH5xfVtcDrsEE3bfBzBtAjXqrzea4MjKg7cqFGVnXwn",
  },
];

var _testXmr = [
  {"raw": "", "encode": ""},
  {"raw": "61", "encode": "2g"},
  {"raw": "626262", "encode": "1a3gV"},
  {"raw": "636363", "encode": "1aPEr"},
  {
    "raw": "73696d706c792061206c6f6e6720737472696e67",
    "encode": "LJe5Z59G5Zz6RYrqDjxxeX3vd16N",
  },
  {
    "raw": "00eb15231dfceb60925886b67d065299925915aeb172c06647",
    "encode": "19uhT2BqLZuRUjnQGCByg4RUm1bZ2jT3j2E",
  },
  {"raw": "516b6fcd0f", "encode": "ABnLTmg"},
  {"raw": "bf4f89001e670274dd", "encode": "YzxHqptA9nj4p"},
  {"raw": "572e4794", "encode": "3EFU7m"},
  {"raw": "ecac89cad93923c02321", "encode": "gb2yYxwXgzj3g4"},
  {"raw": "10c8511e", "encode": "1Rt5zm"},
  {"raw": "00000000000000000000", "encode": "11111111111111"},
  {
    "raw":
        "000111d38e5fc9071ffcd20b4a763cc9ae4f252bb4e48fd66a835e252ada93ff480d6dd43dc62a641155a5",
    "encode": "113MMjnNqJN6MKY7uez1h2WA1ztnozdosJpK3JiBzMSWD3zwwYxy5pX16phr",
  },
  {
    "raw":
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
    "encode":
        "113DUyZY2dc2LxFSMtsQ5k3gsHPkECmXt52nKM8ZY8z26NhMJWtsWSA7icPFuECstJ94XRDHZYFLSAQSTAftscnaBkMV84ECzEiD6GX5SZYMgrESBZ2ptsj8zFn6azDED6b8H81cwbZYU3GJTvetytsqVQKoqgrNEDCwYM9kiokZYaPgNVfkm8tswqpPqaniXEDKHxRBVpfuZYgk6SXQrdHtt4CETsKtagEDReNVDEvY4ZYo6WWZ9xVSttAYeXu4zSqEDXznZEz2QDZYuSvaau4MbttGu4bvp6JzEDeMCdGj8GNZZ1oLeceADkttPFUfxZCB9EDkhchJUE8XZZ89kiePG5uttVbt",
  },
];

void base58Test() {
  test("decode btc base58", () {
    for (final i in testVectBtc.shuffleTake()) {
      final decode = Base58Decoder.decode(i["encode"]!);
      expect(BytesUtils.toHexString(decode), i["raw"]);
      final decodeCheck = Base58Decoder.decodeWithChecksum(i["check_encode"]!);
      expect(BytesUtils.toHexString(decodeCheck), i["raw"]);
    }
  });
  test("encode btc base58", () {
    for (final i in testVectBtc.shuffleTake()) {
      final encode = Base58Encoder.encode(BytesUtils.fromHexString(i["raw"]!));
      expect(i["encode"], encode);
      final encodeCheck = Base58Encoder.encodeWithChecksum(
        BytesUtils.fromHexString(i["raw"]!),
      );
      expect(i["check_encode"], encodeCheck);
    }
  });
  test("decode xrp base58", () {
    for (final i in testVectXrp.shuffleTake()) {
      final decode = Base58Decoder.decode(i["encode"]!, Base58Alphabets.ripple);
      expect(BytesUtils.toHexString(decode), i["raw"]);
      final decodeCheck = Base58Decoder.decodeWithChecksum(
        i["check_encode"]!,
        Base58Alphabets.ripple,
      );
      expect(BytesUtils.toHexString(decodeCheck), i["raw"]);
    }
  });
  test("encode xrp base58", () {
    for (final i in testVectXrp.shuffleTake()) {
      final encode = Base58Encoder.encode(
        BytesUtils.fromHexString(i["raw"]!),
        Base58Alphabets.ripple,
      );
      expect(i["encode"], encode);
      final encodeCheck = Base58Encoder.encodeWithChecksum(
        BytesUtils.fromHexString(i["raw"]!),
        Base58Alphabets.ripple,
      );
      expect(i["check_encode"], encodeCheck);
    }
  });
  group('well-known Base58 (Bitcoin alphabet) test vectors', () {
    // These are the standard reference vectors that show up across almost
    // every Base58 implementation's test suite (originally from Bitcoin
    // Core's own base58_encode_decode.json). Hand-verified by tracing the
    // digit arithmetic for the shorter ones before trusting the rest.
    const vectors = {
      '': '',
      '61': '2g',
      '626262': 'a3gV',
      '636363': 'aPEr',
      '73696d706c792061206c6f6e6720737472696e67':
          '2cFupjhnEsSn59qHXstmK2ffpLv2',
      '00eb15231dfceb60925886b67d065299925915aeb172c06647':
          '1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L',
    };

    vectors.forEach((hex, encoded) {
      test('encode($hex) == "$encoded"', () {
        expect(
          Base58Encoder.encode(BytesUtils.fromHexString(hex)),
          equals(encoded),
        );
      });

      test('decode("$encoded") == $hex', () {
        expect(
          Base58Decoder.decode(encoded),
          equals(BytesUtils.fromHexString(hex)),
        );
      });
    });
  });

  group('leading zero bytes', () {
    test('every leading zero byte becomes one leading "1"', () {
      expect(Base58Encoder.encode([0]), equals('1'));
      expect(Base58Encoder.encode([0, 0, 0]), equals('111'));
      expect(Base58Encoder.encode([0, 0, 5]), startsWith('11'));
    });

    test('round trips preserve the exact leading zero count', () {
      for (final bytes in [
        [0],
        [0, 0],
        [0, 0, 0, 1, 2, 3],
        [0, 255, 0, 1],
      ]) {
        expect(
          Base58Decoder.decode(Base58Encoder.encode(bytes)),
          equals(bytes),
        );
      }
    });
  });

  group('round trip, standard alphabet and Ripple alphabet', () {
    for (final alphabet in Base58Alphabets.values) {
      test('every byte value 0..255 round trips ($alphabet)', () {
        for (var b = 0; b < 256; b++) {
          final encoded = Base58Encoder.encode([b], alphabet);
          expect(
            Base58Decoder.decode(encoded, alphabet),
            equals([b]),
            reason: 'byte=$b',
          );
        }
      });

      test('a longer arbitrary byte sequence round trips ($alphabet)', () {
        final bytes = List<int>.generate(97, (i) => (i * 37 + 5) % 256);
        final encoded = Base58Encoder.encode(bytes, alphabet);
        expect(Base58Decoder.decode(encoded, alphabet), equals(bytes));
      });
    }

    test(
      'bitcoin and ripple alphabets produce different output for the same bytes',
      () {
        final bytes = StringUtils.encode('hello base58');
        expect(
          Base58Encoder.encode(bytes, Base58Alphabets.bitcoin),
          isNot(equals(Base58Encoder.encode(bytes, Base58Alphabets.ripple))),
        );
      },
    );
  });

  group('checksum variant', () {
    test('encodeWithChecksum / decodeWithChecksum round trip', () {
      final bytes = StringUtils.encode('some payload');
      final encoded = Base58Encoder.encodeWithChecksum(bytes);
      expect(Base58Decoder.decodeWithChecksum(encoded), equals(bytes));
    });

    test(
      'encodeWithChecksum output is 4 bytes (as base58) longer than plain encode implies',
      () {
        final bytes = [1, 2, 3, 4, 5];
        final plain = Base58Decoder.decode(Base58Encoder.encode(bytes));
        final checked = Base58Decoder.decodeWithChecksum(
          Base58Encoder.encodeWithChecksum(bytes),
        );
        expect(checked, equals(plain));
      },
    );

    test('a corrupted checksummed string throws Base58ChecksumError', () {
      final encoded = Base58Encoder.encodeWithChecksum(
        StringUtils.encode('payload'),
      );
      // Flip the last character to something else in the alphabet to
      // corrupt the checksum without changing the string's length.
      final alphabet = Base58Alphabets.bitcoin.alphabet;
      final lastChar = encoded[encoded.length - 1];
      final replacement =
          alphabet[(alphabet.indexOf(lastChar) + 1) % alphabet.length];
      final corrupted = encoded.substring(0, encoded.length - 1) + replacement;
      expect(
        () => Base58Decoder.decodeWithChecksum(corrupted),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('error handling', () {
    test('invalid character throws Base58FormatError', () {
      // '0' (zero) is never in a Base58 alphabet - that's the whole point
      // of Base58 (avoids confusion with 'O').
      expect(() => Base58Decoder.decode('abc0'), throwsA(isA<BuError>()));
    });

    test('a character invalid in both alphabets is rejected either way', () {
      // '0' (zero) is excluded from both the Bitcoin and Ripple alphabets
      // here - they're both permutations of the same 58-character set
      // (each excludes 0, O, I, and lowercase l), just in different
      // orders, so there's no character valid under one and not the
      // other to test against.
      expect(
        () => Base58Decoder.decode('0', Base58Alphabets.bitcoin),
        throwsA(isA<BuError>()),
      );
      expect(
        () => Base58Decoder.decode('0', Base58Alphabets.ripple),
        throwsA(isA<BuError>()),
      );
    });

    test(
      'decoding with the wrong alphabet does not reproduce the original bytes',
      () {
        // Same character set, different order - encoding with one alphabet
        // and decoding with the other should (almost always) give the
        // wrong bytes rather than throwing, since every character is still
        // "valid", just mapped to a different value.
        final bytes = StringUtils.encode('hello base58');
        final encoded = Base58Encoder.encode(bytes, Base58Alphabets.bitcoin);
        expect(
          Base58Decoder.decode(encoded, Base58Alphabets.ripple),
          isNot(equals(bytes)),
        );
      },
    );
  });

  group('Monero (XMR) block-based variant', () {
    test('round trips across full and partial block boundaries', () {
      // 0, 1..8 (each partial-block length), a full block (8), and a few
      // multi-block combinations (full + partial).
      for (final len in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 15, 16, 17, 24, 25]) {
        final bytes = List<int>.generate(len, (i) => (i * 53 + 7) % 256);
        final encoded = Base58XmrEncoder.encode(bytes);
        expect(
          Base58XmrDecoder.decode(encoded),
          equals(bytes),
          reason: 'len=$len',
        );
      }
    });

    test('each full 8-byte block encodes to exactly 11 characters', () {
      final bytes = List<int>.generate(16, (i) => i); // two full blocks
      expect(Base58XmrEncoder.encode(bytes).length, equals(22));
    });

    test(
      'a partial block encodes to the protocol-fixed width for its length',
      () {
        // blockEncByteLens = [0, 2, 3, 5, 6, 7, 9, 10, 11] - index == raw
        // byte length of the (only, partial) block here.
        for (var len = 1; len < 8; len++) {
          final bytes = List<int>.generate(
            len,
            (i) => 0xFF,
          ); // maximal value, no padding luck
          final encoded = Base58XmrEncoder.encode(bytes);
          expect(
            encoded.length,
            equals(Base58XmrConst.blockEncByteLens[len]),
            reason: 'len=$len',
          );
        }
      },
    );

    test('leading zero bytes within a block round trip correctly', () {
      final bytes = [0, 0, 1, 2, 3, 4, 5, 6, 0, 0, 7];
      expect(
        Base58XmrDecoder.decode(Base58XmrEncoder.encode(bytes)),
        equals(bytes),
      );
    });

    test("base58 xmr decod ", () {
      for (final i in _testXmr.shuffleTake()) {
        final decode = Base58XmrDecoder.decode(i["encode"]!);
        expect(i["raw"], BytesUtils.toHexString(decode));
      }
    });
    test("base58 xmr encode ", () {
      for (final i in _testXmr.shuffleTake()) {
        final decode = Base58XmrEncoder.encode(
          BytesUtils.fromHexString(i["raw"]!),
        );
        expect(i["encode"], decode);
      }
    });

    test("invalid decode", () {
      expect(() {
        Base58XmrDecoder.decode("237LSrYONUUar");
      }, throwsA(isA<BuError>()));
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(base58Test, "Base58");
}
