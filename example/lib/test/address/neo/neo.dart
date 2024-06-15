import 'package:blockchain_utils/bip/address/neo_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart' show testVecotr;

void neoAddressTest() {
  for (final i in testVecotr) {
    final params = Map<String, dynamic>.from(i["params"]);
    params["ver"] = BytesUtils.fromHexString(params["ver"]);
    final z = NeoAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = NeoAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
