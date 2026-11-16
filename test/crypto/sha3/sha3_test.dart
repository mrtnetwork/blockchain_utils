import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void sha3Test() {
  test("SHA3 state", () {
    final k = QuickCrypto.sha3Instance();
    k.update([0, 0]);
    final r = k.saveState();
    final digest = k.digest();
    expect(k.digest(), digest);
    k.reset();
    k.update([0, 0]);
    expect(k.digest(), digest);
    k.clean();
    expect(() => k.reset(), buErrorOrCryptoException);

    final g = QuickCrypto.sha3Instance();
    g.restoreState(r);
    expect(g.digest(), digest);
    {
      final g = QuickCrypto.keccakInstance();
      expect(() => g.restoreState(r), buErrorOrCryptoException);
    }
  });
  test("sha3-512", () {
    for (final i in testVector.shuffleTake()) {
      final k = QuickCrypto.sha3Instance(digestLength: 64);
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.reset();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });

  test("sha3-256", () {
    for (final i in testVectorSha332) {
      final k = QuickCrypto.sha3Instance(digestLength: 32);
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.reset();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });

  test("Update state", () {
    final b = QuickCrypto.sha3Instance();
    List<int> buffer = List.generate(300, (i) => i & BinaryOps.mask8);
    for (int i in buffer) {
      b.update([i]);
    }
    final hash = b.digest();
    b.reset();
    b.update(buffer);
    expect(hash, b.digest());
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(sha3Test, "Sha3");
}
