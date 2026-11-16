import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../utils.dart';

String _segwitEmptyPayloadAddress(String hrp) {
  // Empty payload with a *valid* checksum: decodeBech32 strips the checksum
  // and hands back empty data, which is what crashes the witness parsing.
  // The segwit checksum path is picked from data[0], so use whichever
  // encoding is self-consistent for this hrp (encodes empty with E and
  // verifies empty under E's own data[0]-selected path).
  for (final enc in [Bech32Encodings.bech32, Bech32Encodings.bech32m]) {
    final c = Bech32Utils.computeChecksum(hrp, [], enc);
    final takesBech32Path = c[0] == 0;
    if ((enc == Bech32Encodings.bech32) == takesBech32Path) {
      return '${hrp}1${c.map((v) => Bech32BaseConst.charset[v]).join()}';
    }
  }
  throw StateError('no self-consistent empty-payload encoding for $hrp');
}

void guardsTest() {
  group('Base58Check guards', () {
    test('too-short payload throws checksum error, not RangeError', () {
      expect(
        () => Base58Decoder.decodeWithChecksum('a'),
        throwsA(isA<BuError>()),
      );
      expect(
        () => Base58Decoder.decodeWithChecksum(''),
        throwsA(isA<BuError>()),
      );
      expect(
        () => Base58Decoder.decodeWithChecksum('111'),
        throwsA(isA<BuError>()),
      );
    });

    test('roundtrip still works', () {
      const raw = [0, 1, 2, 3, 250];
      final enc = Base58Encoder.encodeWithChecksum(raw);
      expect(Base58Decoder.decodeWithChecksum(enc).toList(), raw);
    });

    test('corrupted checksum throws', () {
      final enc = Base58Encoder.encodeWithChecksum([1, 2, 3]);
      final bad =
          enc.substring(0, enc.length - 1) + (enc.endsWith('1') ? '2' : '1');
      expect(
        () => Base58Decoder.decodeWithChecksum(bad),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('SS58 guards', () {
    test('empty string throws format error, not RangeError', () {
      expect(() => SS58Decoder.decode(''), throwsA(isA<BuError>()));
    });

    test('single byte with two-byte marker throws format error', () {
      final addr = Base58Encoder.encode([0x40]);
      expect(() => SS58Decoder.decode(addr), throwsA(isA<BuError>()));
    });

    test('invalid alphabet still surfaces Base58FormatError', () {
      expect(() => SS58Decoder.decode('0'), throwsA(isA<BuError>()));
    });

    test('roundtrip still works', () {
      final addr = SS58Encoder.encode(List<int>.filled(32, 7), 42);
      final (format, data) = SS58Decoder.decode(addr);
      expect(format, 42);
      expect(data.toList(), List<int>.filled(32, 7));
    });
  });

  group('Monero Base58 guards', () {
    test('bad final-block residue throws format error, not RangeError', () {
      // Length % 11 == 1 is not a valid Monero block residue (valid: 0,2,3,5,6,7,9,10).
      expect(() => Base58XmrDecoder.decode('a'), throwsA(isA<BuError>()));
      expect(
        () => Base58XmrDecoder.decode('abcdefghijklm'),
        throwsA(isA<BuError>()),
      );
    });

    test('roundtrip still works', () {
      final raw = List<int>.generate(69, (i) => i & 0xFF);
      expect(
        Base58XmrDecoder.decode(Base58XmrEncoder.encode(raw)).toList(),
        raw,
      );
      expect(
        Base58XmrDecoder.decode(Base58XmrEncoder.encode([])).toList(),
        isEmpty,
      );
    });
  });

  group('DER guards', () {
    test('empty SEQUENCE SPKI throws CryptoException', () {
      expect(
        () => DerCodec.decodeSecp256k1PublicKeySpki([0x30, 0x00]),
        throwsA(isA<BuError>()),
      );
      expect(
        () => DerCodec.decodeSecp256r1PublicKeySpki([0x30, 0x00]),
        throwsA(isA<BuError>()),
      );
      expect(
        () => DerCodec.decodeEd25519PublicKeySpki([0x30, 0x00]),
        throwsA(isA<BuError>()),
      );
      expect(
        () => DerCodec.decodeBls12381PublicKeySpki([0x30, 0x00]),
        throwsA(isA<BuError>()),
      );
    });

    test('empty AlgorithmIdentifier throws CryptoException', () {
      // SEQUENCE { SEQUENCE {} , OCTET STRING {} }
      final der = [
        ...DerUtils.derSequence([
          ...DerUtils.derSequence([]),
          ...DerUtils.derOctetString([]),
        ]),
      ];
      expect(
        () => DerCodec.decodeSecp256k1PrivateKeyPkcs8(der),
        throwsA(isA<BuError>()),
      );
    });

    test('empty BIT STRING value throws CryptoException', () {
      // SEQUENCE { SEQUENCE { OID ecPublicKey } , BIT STRING (empty value) }
      final der = [
        ...DerUtils.derSequence([
          ...DerUtils.derSequence([...DerUtils.derOid(Oids.ecPublicKey)]),
          ...DerUtils.derTlv(DerTag.bitString, []),
        ]),
      ];
      expect(
        () => DerCodec.decodeSecp256k1PublicKeySpki(der),
        throwsA(isA<BuError>()),
      );
    });

    test('empty OID throws CryptoException', () {
      expect(() => DerUtils.decodeOid([]), throwsA(isA<BuError>()));
    });

    test('non-numeric OID throws CryptoException, not FormatException', () {
      expect(() => DerUtils.encodeOid('abc'), throwsA(isA<BuError>()));
      expect(() => DerUtils.encodeOid('1.2.abc'), throwsA(isA<BuError>()));
    });

    test('empty INTEGER encode throws CryptoException', () {
      expect(
        () => DerCodec.toDer([
          [],
          [1],
        ]),
        throwsA(isA<BuError>()),
      );
    });

    test('valid key roundtrips still work', () {
      final sec1 = DerCodec.encodeSecp256k1PrivateKeySec1(
        List<int>.filled(32, 3),
      );
      final key = DerCodec.decodeSecp256k1PrivateKeySec1(sec1);
      expect(key.privateKey.toList(), List<int>.filled(32, 3));
      final sig = DerCodec.encodeEcdsaSignatureDer([1, 2, 3], [4, 5]);
      final (r, s) = DerCodec.decodeEcdsaSignatureDer(sig);
      expect(r.toList().last, 3);
      expect(s.toList().last, 5);
    });
  });

  group('Bech32 empty-payload guards', () {
    test('cashaddr empty payload throws Bech32Error', () {
      // The public encoder accepts an empty payload and produces a valid
      // checksum for it; the decoder must reject it, not crash on convData[0].
      final addr = BchBech32Encoder.encode('bitcoincash', [], []);
      expect(
        () => BchBech32Decoder.decode('bitcoincash', addr),
        throwsA(isA<BuError>()),
      );
    });

    test('segwit empty payload throws Bech32Error', () {
      for (final hrp in ['bc', 'tb', 'bcrt']) {
        final addr = _segwitEmptyPayloadAddress(hrp);
        expect(
          () => SegwitBech32Decoder.decode(hrp, addr),
          throwsA(isA<BuError>()),
          reason: 'hrp $hrp',
        );
      }
    });

    test('segwit rejects out-of-range witness version on encode', () {
      expect(
        () => SegwitBech32Encoder.encode('bc', 99, [1, 2, 3]),
        throwsA(isA<BuError>()),
      );
      expect(
        () => SegwitBech32Encoder.encode('bc', -1, [1, 2, 3]),
        throwsA(isA<BuError>()),
      );
    });

    test('segwit roundtrip still works', () {
      final addr = SegwitBech32Encoder.encode('bc', 0, List<int>.filled(20, 7));
      final (ver, prog) = SegwitBech32Decoder.decode('bc', addr);
      expect(ver, 0);
      expect(prog.toList(), List<int>.filled(20, 7));
    });
  });

  group('CBOR date guards', () {
    test('invalid tag-0 date string throws CborException', () {
      // tag 0 (date string) + text(10) "not-a-date"
      final bytes = [0xC0, 0x6A, ...'not-a-date'.codeUnits];
      expect(() => CborObject.fromCbor(bytes), throwsA(isA<BuError>()));
    });

    test('valid tag-0 date still decodes', () {
      final text = '2024-01-02T03:04:05Z';
      final bytes = [0xC0, 0x74, ...text.codeUnits];
      final obj = CborObject.fromCbor(bytes);
      expect(obj, isA<CborStringDateValue>());
    });
  });

  group('Proto timestamp guards', () {
    test('out-of-range fields normalize, garbage shape throws', () {
      // Dart normalizes month 13 into January of the next year; the parser
      // only rejects shape violations (the try/catch around DateTime.parse
      // stays as defense-in-depth for platform behavior differences).
      final r = ProtoUtils.timestampFromRfc3339('2024-13-01T00:00:00Z');
      expect(
        ProtoUtils.timestampToRfc3339(r.seconds, r.nanos),
        '2025-01-01T00:00:00Z',
      );
      expect(
        () => ProtoUtils.timestampFromRfc3339('not-a-timestamp'),
        throwsA(isA<BuError>()),
      );
    });

    test('valid timestamps roundtrip', () {
      final r = ProtoUtils.timestampFromRfc3339('2024-01-02T03:04:05Z');
      expect(
        ProtoUtils.timestampToRfc3339(r.seconds, r.nanos),
        '2024-01-02T03:04:05Z',
      );
    });

    test('invalid duration throws ArgumentException', () {
      expect(
        () => ProtoUtils.googleDurationFromJson('nope'),
        throwsA(isA<BuError>()),
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(guardsTest, "EncodingGuards");
}
