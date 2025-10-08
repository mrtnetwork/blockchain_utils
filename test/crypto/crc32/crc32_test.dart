import 'package:blockchain_utils/crypto/crypto/crc32/crc32.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  test("crc test", () {
    for (final i in testVector) {
      final result =
          Crc32.quickIntDigest(BytesUtils.fromHexString(i["message"]));
      expect(result, i["crc32"]);
    }
  });
}
