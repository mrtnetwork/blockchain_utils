import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:test/test.dart';
import 'test_vector.dart';
import '../../utils.dart';

void blake2bTest() {
  test("blake2b state", () {
    {
      final k = QuickCrypto.blake2bInstance(
        digestLength: 64,
        config: Blake2Config.blake2b(
          salt: QuickCrypto.generateRandom(length: 16),
          personalization: QuickCrypto.generateRandom(length: 16),
          fanout: 2,
          leafSize: 1,
          maxDepth: 3,
          nodeDepth: 4,
          nodeOffset: 1,
        ),
      );
      k.update([0, 0]);
      final r = k.saveState();
      final digest = k.digest();
      expect(k.digest(), digest);
      k.reset();
      k.update([0, 0]);
      expect(k.digest(), digest);
      k.clean();
      expect(() => k.reset(), buErrorOrCryptoException);
      final g = QuickCrypto.blake2bInstance(digestLength: 64);
      g.restoreState(r);
      expect(g.digest(), digest);
    }
  });
  test("blake2b test", () {
    for (final i in testVector64.shuffleTake()) {
      final k = QuickCrypto.blake2bInstance(digestLength: 64);
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.reset();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });
  test("blake2b with key and nonce test", () {
    for (final i in testVectorWithKeyAndSalt) {
      final key = BytesUtils.fromHexString(i["key"]);
      final salt = BytesUtils.fromHexString(i["salt"]);
      BuSerializableHash k = QuickCrypto.blake2bInstance(
        digestLength: 64,
        config: Blake2Config.blake2b(key: key, salt: salt),
      );
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);

      // k =k.reset()
    }
  });

  test("Update state", () {
    BuHash b = QuickCrypto.blake2bInstance(
      config: Blake2Config.blake2b(
        salt: QuickCrypto.generateRandom(length: 16),
        personalization: QuickCrypto.generateRandom(length: 16),
        key: QuickCrypto.generateRandom(length: 32),
      ),
    );
    List<int> buffer = List.generate(300, (i) => i & BinaryOps.mask8);
    for (int i in buffer) {
      b.update([i]);
    }
    final hash = b.digest();
    b = b.reset();
    b.update(buffer);
    expect(hash, b.digest());
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(blake2bTest, "Blake2b");
}
