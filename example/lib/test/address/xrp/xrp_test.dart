import 'package:blockchain_utils/bip/address/xrp_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart' show testVector;

void xrpAddressTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    final z = XrpAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = XrpAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
