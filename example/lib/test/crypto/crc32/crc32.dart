import 'package:blockchain_utils/crypto/crypto/crc32/crc32.dart';

import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart';

void crcTest() {
  for (final i in testVector) {
    final result = Crc32.quickIntDigest(BytesUtils.fromHexString(i["message"]));
    assert(result == i["crc32"]);
  }
}
