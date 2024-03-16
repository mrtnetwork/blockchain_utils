import 'package:blockchain_utils/bip/address/one_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart' show testVector;

void oneAddressTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    final z = OneAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = OneAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
