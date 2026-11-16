import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector_256.dart';
import 'test_vector_128.dart';

import '../../utils.dart';

void shakeTest() {
  test("SHAKE state", () {
    final k = QuickCrypto.shake256Instance();
    k.update([0, 0]);
    final r = k.saveState();
    final digest = k.digest();
    expect(BytesUtils.bytesEqual(k.digest(), digest), isFalse);
    k.reset();
    k.update([0, 0]);
    expect(k.digest(), digest);
    k.clean();
    expect(() => k.reset(), buErrorOrCryptoException);

    final g = QuickCrypto.shake256Instance();
    g.restoreState(r);
    expect(g.digest(), digest);
    expect(BytesUtils.bytesEqual(g.digest(), digest), isFalse);
  });
  List<int> xof(BuSerializableHash hash, int length) {
    final bytes = BuBytes.fill(length);
    hash.finish(bytes);
    return bytes;
  }

  test("shake25", () {
    for (final i in testVecotr256.shuffleTake()) {
      final inp = BytesUtils.fromHexString(i["input"]);
      final int out = i["out_size"];
      final h = QuickCrypto.shake256Instance();
      h.update(inp.sublist(0, 1));
      h.update(inp.sublist(1));
      final digest = xof(h, out);
      expect(digest.toHex(), i["out"]);
      h.reset();
      h.update(inp);
      expect(digest.toHex(), i["out"]);
    }
  });
  test("shake128", () {
    for (final i in testVector128.shuffleTake()) {
      final inp = BytesUtils.fromHexString(i["input"]);
      final int out = i["out_size"];
      final h = QuickCrypto.shake128Instance();
      h.update(inp.sublist(0, 1));
      h.update(inp.sublist(1));
      final digest = xof(h, out);
      expect(digest.toHex(), i["out"]);
      h.reset();
      h.update(inp);
      expect(digest.toHex(), i["out"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(shakeTest, "Shake");
}
