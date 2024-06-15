import 'package:blockchain_utils/bip/address/ergo.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart' show testVector;

void ergoAddressTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    params["net_type"] = ErgoNetworkTypes.values.firstWhere((element) =>
        element.name.toLowerCase() ==
        (params["net_type"] as String).toLowerCase());
    final z = ErgoP2PKHAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = ErgoP2PKHAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
