import 'package:blockchain_utils/bip/address/avax_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_p_vector.dart' as p;
import 'test_x_vector.dart' as x;

void avaxAddrTest() {
  for (final i in p.testVector) {
    final params = Map<String, dynamic>.from(i["params"]);

    final z = AvaxPChainAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = AvaxPChainAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
  for (final i in x.testVector) {
    final params = Map<String, dynamic>.from(i["params"]);

    final z = AvaxXChainAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = AvaxXChainAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
