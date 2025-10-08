import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  test("Prng", () {
    for (int i = 0; i < 100; i++) {
      final entropy = QuickCrypto.generateRandom();
      final prngA = FortunaPRNG.fromEntropy(entropy);
      final prngB = FortunaPRNG.fromEntropy(entropy);
      final bytesA = prngA.nextBytes(i + 10);
      final bytesB = prngB.nextBytes(i + 10);
      expect(bytesA, bytesB);
      expect(bytesA.length, i + 10);
      expect(prngA.nextUint32, prngB.nextUint32);
      final intA = prngA.nextInt(100);
      final intB = prngB.nextInt(100);
      expect(intA, intB);
      expect((intA < 100 && intA >= 0), true);
    }
  });
}
