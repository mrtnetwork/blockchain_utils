import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void sha1Test() {
  test("SHA-1 state", () {
    final k = QuickCrypto.sha1Instance();
    k.update([0, 0]);
    final r = k.saveState();
    final digest = k.digest();
    expect(k.digest(), digest);
    k.reset();
    k.update([0, 0]);
    expect(k.digest(), digest);
    k.clean();
    expect(() => k.reset(), buErrorOrCryptoException);
    final g = QuickCrypto.sha1Instance();
    g.restoreState(r);
    expect(g.digest(), digest);
  });
  test("sh1", () {
    for (final i in testVector.shuffleTake()) {
      final k = QuickCrypto.sha1Instance();
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
    final b = QuickCrypto.sha1Instance();
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
  BlockchainUtilsTestApi.runTest(sha1Test, "Sha1");
}
