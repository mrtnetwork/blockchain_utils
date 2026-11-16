import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void keccackTest() {
  test("kechack 256 bit", () {
    for (final i in testVector.shuffleTake()) {
      final k = QuickCrypto.keccakInstance(digestLength: 32);

      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.reset();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });
  test("test keccak 512 bit", () {
    for (final i in keccack512TestVector.shuffleTake()) {
      final k = QuickCrypto.keccakInstance(digestLength: 64);
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      final result = k.digest();
      expect(result.toHex(), i["hash"]);
      k.reset();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });

  test("keccak state", () {
    final k = QuickCrypto.keccakInstance(digestLength: 64);
    k.update([0, 0]);
    final r = k.saveState();
    final digest = k.digest();
    expect(k.digest(), digest);
    k.reset();
    k.update([0, 0]);
    expect(k.digest(), digest);
    k.clean();
    expect(() => k.reset(), buErrorOrCryptoException);

    final g = QuickCrypto.keccakInstance(digestLength: 64);
    g.restoreState(r);
    expect(g.digest(), digest);
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(keccackTest, "Keccak");
}
