import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:test/test.dart';
import 'test_vector.dart';

void main() {
  test("xxhash64", () {
    for (final i in testVector) {
      final data = BytesUtils.fromHexString(i["hex"]);
      final int bitLength = i["bitlength"];
      if (data.length.isEven) {
        final half = data.length ~/ 2;
        final first = data.sublist(0, half);
        final secound = data.sublist(half);
        final hasher = XXHash64(bitLength: bitLength);
        hasher.update(first);
        hasher.update(secound);
        expect(
            BytesUtils.toHexString(hasher.digest(), prefix: "0x"), i["hash"]);
        continue;
      }
      final hash = XXHash64.hash(data, bitlength: bitLength);
      expect(BytesUtils.toHexString(hash, prefix: "0x"), i["hash"]);
    }
  });
}
