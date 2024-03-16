import 'package:blockchain_utils/bip/address/p2wpkh_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart' show testVector;

void p2wpkhAddressTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);

    final z = P2WPKHAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = P2WPKHAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
