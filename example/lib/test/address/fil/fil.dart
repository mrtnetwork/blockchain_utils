import 'package:blockchain_utils/bip/address/fil_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart' show testVector;

void filAddressTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    final z = FilSecp256k1AddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = FilSecp256k1AddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
