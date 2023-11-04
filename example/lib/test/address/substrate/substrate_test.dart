import 'package:blockchain_utils/bip/address/substrate_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart' show testVector;

void substrateAddressTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);

    final z = SubstrateEd25519AddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = SubstrateEd25519AddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);

    final z = SubstrateSr25519AddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = SubstrateSr25519AddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
