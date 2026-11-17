import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

final List<Map<String, dynamic>> _testVector = [
  {
    "raw": "facc4de5b7745215ec8255c743f044d2a94ef72b2fb6d8e22c35ffbc3ac8ac9e",
    "ss58_format": 0,
    "encode": "16fqfQjHSWMoMxydLYoYixYcTGvcE3csECC69Lik312jNWS9",
  },
  {
    "raw": "0ae7387f2bbf2846df7a1fb07b0676f1e4c35787f96b6a618e254afea5434d04",
    "ss58_format": 2,
    "encode": "CpcgbdXbwSbUJF38WTzR2r8CpeF29Jeyqm1EZmJmey7sXVE",
  },
  {
    "raw": "9494d77c224df8b09e05b91ebe7a2f475c12a4cfd103da6b58679b22fc995fda",
    "ss58_format": 42,
    "encode": "5FRXACEYAEcDiWnScWfuqGkYVrq8wyNysbgMGvjDnKLUKFv5",
  },
  {
    "raw": "f2b0e94f4d04acb16ecbe3348482b207ba6e60585dd641a8b0f6f28ca99795bc",
    "ss58_format": 63,
    "encode": "7P5mRixqQk1Z1h4U15Z2zMc6vKoprgWs645jehsbti5irbc7",
  },
  {
    "raw": "735ec2e330426e8643745d5bf6b287bfec4e50eaca556c9f2781b02db5e7a236",
    "ss58_format": 64,
    "encode": "cEYBURAnCdz1eMtzsDW3JAz8dEGrahsjYiHXZCBFsxHK7VJX1",
  },
  {
    "raw": "735ec2e330426e8643745d5bf6b287bfec4e50eaca556c9f2781b02db5e7a236",
    "ss58_format": 127,
    "encode": "jArK6dHqpF4QE6a9H8B54gNRy6hSBzpYBGjCwp4KrqxoADwNq",
  },
];

void ss58Test() {
  group('well-known "Alice" dev key vector', () {
    // Substrate's well-known //Alice dev account, format 42 (generic
    // Substrate). Confirmed across multiple independent sources (Parity's
    // txwrapper examples, subkey output, the pub.dev ss58 package docs).
    const alicePubKeyHex =
        'd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d';
    const aliceAddress = '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY';

    test('encode(alicePubKey, 42) == aliceAddress', () {
      expect(
        SS58Encoder.encode(BytesUtils.fromHexString(alicePubKeyHex), 42),
        equals(aliceAddress),
      );
    });

    test('decode(aliceAddress) == (42, alicePubKey)', () {
      final (format, data) = SS58Decoder.decode(aliceAddress);
      expect(format, equals(42));
      expect(data, equals(BytesUtils.fromHexString(alicePubKeyHex)));
    });
  });

  group('round trip across simple (<64) and full (>=64) formats', () {
    test('simple formats (single format byte)', () {
      for (final format in [0, 2, 5, 42, 63]) {
        final data = List<int>.generate(32, (i) => (i * 13 + 1) % 256);
        final encoded = SS58Encoder.encode(data, format);
        final (decodedFormat, decodedData) = SS58Decoder.decode(encoded);
        expect(decodedFormat, equals(format), reason: 'format=$format');
        expect(decodedData, equals(data), reason: 'format=$format');
      }
    });

    test('full formats (two format bytes)', () {
      for (final format in [64, 100, 255, 1000, 16383]) {
        final data = List<int>.generate(32, (i) => (i * 13 + 1) % 256);
        final encoded = SS58Encoder.encode(data, format);
        final (decodedFormat, decodedData) = SS58Decoder.decode(encoded);
        expect(decodedFormat, equals(format), reason: 'format=$format');
        expect(decodedData, equals(data), reason: 'format=$format');
      }
    });

    test(
      'round trips for the standard SS58 payload lengths (1, 2, 4, 8, 32 bytes)',
      () {
        // These are the byte lengths that actually occur in real SS58
        // usage: AccountIndex<u8/u16/u32/u64> (1/2/4/8 bytes) and
        // AccountId32 (32 bytes, which is also the "34 total payload
        // bytes -> 2-byte checksum" case).
        for (final dataLen in [1, 2, 4, 8, 32]) {
          final data = List<int>.generate(dataLen, (i) => (i * 17 + 3) % 256);
          final encoded = SS58Encoder.encode(data, 42);
          final (format, decodedData) = SS58Decoder.decode(encoded);
          expect(format, equals(42), reason: 'dataLen=$dataLen');
          expect(decodedData, equals(data), reason: 'dataLen=$dataLen');
        }
      },
    );

    test(
      'a data length whose total decoded size is ambiguous still round trips',
      () {
        // Regression test: a 33-byte payload (format 42, 1 format byte +
        // 33 data bytes = 34-byte payload -> 2-byte checksum -> 36 bytes
        // total) has the same total decoded length (36) as a 35-byte
        // payload with a 1-byte checksum would. The old decode logic
        // inferred checksum length from total length alone and picked the
        // wrong split here; decode now tries both candidate lengths and
        // accepts whichever one's checksum actually verifies.
        final data = List<int>.generate(33, (i) => (i * 17 + 3) % 256);
        final encoded = SS58Encoder.encode(data, 42);
        final (format, decodedData) = SS58Decoder.decode(encoded);
        expect(format, equals(42));
        expect(decodedData, equals(data));
      },
    );
  });

  group('error handling', () {
    test('negative format is rejected', () {
      expect(() => SS58Encoder.encode([1, 2, 3], -1), throwsA(isA<BuError>()));
    });

    test('format above the 14-bit max is rejected', () {
      expect(
        () => SS58Encoder.encode([1, 2, 3], 16384),
        throwsA(isA<BuError>()),
      );
    });

    test('reserved formats (46, 47) are rejected on encode', () {
      expect(() => SS58Encoder.encode([1, 2, 3], 46), throwsA(isA<BuError>()));
      expect(() => SS58Encoder.encode([1, 2, 3], 47), throwsA(isA<BuError>()));
    });

    test('a corrupted checksum throws SS58ChecksumError', () {
      final encoded = SS58Encoder.encode(List<int>.filled(32, 7), 42);
      // Flip the last character to something else Base58-valid, to
      // corrupt the checksum without changing the string's length.
      const alphabet =
          '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
      final lastChar = encoded[encoded.length - 1];
      final replacement =
          alphabet[(alphabet.indexOf(lastChar) + 1) % alphabet.length];
      final corrupted = encoded.substring(0, encoded.length - 1) + replacement;
      expect(() => SS58Decoder.decode(corrupted), throwsA(isA<BuError>()));
    });
  });
  group("test vector", () {
    test("decode", () {
      for (final i in _testVector.shuffleTake()) {
        final dec = SS58Decoder.decode(i["encode"]);
        expect(dec.$1, i["ss58_format"]);
        expect(BytesUtils.toHexString(dec.$2), i["raw"]);
      }
    });
    test("encode", () {
      for (final i in _testVector.shuffleTake()) {
        final dec = SS58Encoder.encode(
          BytesUtils.fromHexString(i["raw"]),
          i["ss58_format"],
        );
        expect(dec, i["encode"]);
      }
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(ss58Test, "Ss58");
}

// void main() {}
