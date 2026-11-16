import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void xxhash64Test() {
  test("XXHash state", () {
    final k = QuickCrypto.xxHashInstance();
    k.update([0, 0]);
    final digest = k.digest();
    expect(k.digest(), digest);
    k.reset();
    k.update([0, 0]);
    expect(k.digest(), digest);
    k.clean();
    expect(() => k.reset(), buErrorOrCryptoException);
  });
  test("xxHash", () {
    for (final i in testVector.shuffleTake()) {
      final data = BytesUtils.fromHexString(i["hex"]);
      final int bitLength = i["bitlength"];
      if (![64, 128, 256].contains(bitLength)) continue;
      if (data.length.isEven) {
        final half = data.length ~/ 2;
        final first = data.sublist(0, half);
        final secound = data.sublist(half);
        final hasher = QuickCrypto.xxHashInstance(bitLength: bitLength);
        hasher.update(first);
        hasher.update(secound);
        expect(
          BytesUtils.toHexString(hasher.digest(), prefix: "0x"),
          i["hash"],
        );
        continue;
      }
      final hash = XXHash.hash(data, bitLength: bitLength);
      expect(BytesUtils.toHexString(hash, prefix: "0x"), i["hash"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(xxhash64Test, "Xxhash64");
}
