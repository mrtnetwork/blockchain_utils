import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart' show testVector;

void bchP2pkhTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    params["net_ver"] = BytesUtils.fromHexString(params["net_ver"]);

    final z = BchP2PKHAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = BchP2PKHAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
