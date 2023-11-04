import 'package:blockchain_utils/bip/address/eth_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart' show testVector;

void ethereumAddressTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    final z = EthAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = EthAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
