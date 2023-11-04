import 'package:blockchain_utils/crypto/crypto/x_modem_crc/x_modem_crc.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart';

void testModemCrc() {
  for (final i in testVector) {
    final result =
        XModemCrc.quickDigest(BytesUtils.fromHexString(i["message"]));
    assert(result.toHex() == i["crc"]);
  }
}
