import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'comperesed_test_vector.dart' show compresedTestVector;
import 'uncompresed_test_vector.dart' show uncompressedTestVector;

void p2pkhAddressTest() {
  for (final i in compresedTestVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    params["pub_key_mode"] = PubKeyModes.compressed;
    params["net_ver"] = BytesUtils.fromHexString(params["net_ver"]);
    final z = P2PKHAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = P2PKHAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
  for (final i in uncompressedTestVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    params["pub_key_mode"] = PubKeyModes.uncompressed;
    params["net_ver"] = BytesUtils.fromHexString(params["net_ver"]);
    final z = P2PKHAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = P2PKHAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
