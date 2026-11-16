import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

List<int> _packBits(List<bool> bits) {
  return List<int>.generate((bits.length + 7) ~/ 8, (i) {
    var b = 0;
    for (var k = 0; k < 8; k++) {
      final idx = i * 8 + k;
      if (idx < bits.length && bits[idx]) b |= 1 << k;
    }
    return b;
  });
}

void pedersenApiTest() {
  group('Pedersen api routing', () {
    test('api matches direct PedersenHash (note commitment)', () {
      final bits = List<bool>.generate(408, (i) => i % 3 == 0);
      final packed = _packBits(bits);
      final viaApi = blockchainUtils.api.hash.pedersenHash(
        personal: 0,
        packedBits: BuBytes(packed),
        bitLen: bits.length,
      );
      final direct =
          PedersenHash()
              .hash(
                personalization: const PersonalizationNoteCommitment(),
                inputBits: bits,
              )
              .toBytes();
      expect(viaApi.toList(), direct.toList());
    });

    test('bitstring variant matches packed variant', () {
      const bits01 = '10110011';
      final bits = [for (final c in bits01.codeUnits) c == 0x31];
      final viaBits = blockchainUtils.api.hash.pedersenHashBitstring(
        personal: 0,
        bits: bits,
      );
      final packed = _packBits(bits);
      final viaPacked = blockchainUtils.api.hash.pedersenHash(
        personal: 0,
        packedBits: BuBytes(packed),
        bitLen: bits01.length,
      );
      expect(viaBits.toList(), viaPacked.toList());
    });

    test('output is a valid compressed Jubjub point', () {
      final out = blockchainUtils.api.hash.pedersenHash(
        personal: 0,
        packedBits: BuBytes(List<int>.filled(51, 7)),
        bitLen: 408,
      );
      expect(out.length, 32);
      // Decompresses without throwing.
      expect(JubJubPoint.fromBytes(out).toBytes().length, 32);
    });

    test('truncated packed input throws', () {
      expect(
        () => blockchainUtils.api.hash.pedersenHash(
          personal: 0,
          packedBits: BuBytes(List<int>.filled(50, 0)),
          bitLen: 408,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => blockchainUtils.api.hash.pedersenHashBitstring(
          personal: 99,
          bits: [true, false, true],
        ),
        throwsA(isA<BuError>()),
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(pedersenApiTest, "PedersenApi");
}
