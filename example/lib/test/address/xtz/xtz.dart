import 'package:blockchain_utils/bip/address/xtz_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart' show testVector;

void xtzAddressTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from({"prefix": XtzAddrPrefixes.tz1});
    final z = XtzAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);

    assert(z == i["address"]);
    final decode = XtzAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
