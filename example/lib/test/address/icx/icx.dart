import 'package:blockchain_utils/bip/address/icx_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart' show testVecotr;

void icxAddressTest() {
  for (final i in testVecotr) {
    final params = Map<String, dynamic>.from(i["params"]);
    final z = IcxAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = IcxAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
