import 'package:blockchain_utils/crypto/crypto/crc32/crc32.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import '../../quick_hex.dart';
import 'test_vector.dart';

void main() {
  test("crc test", () {
    final crc = Crc32();
    for (final i in testVector.shuffleTake()) {
      final result = crc.quickIntDigest(BytesUtils.fromHexString(i["message"]));
      expect(result, i["crc32"]);
    }
  });
}
