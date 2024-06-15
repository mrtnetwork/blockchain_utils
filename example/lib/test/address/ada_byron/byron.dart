import 'package:blockchain_utils/bip/address/ada/ada_byron_addr.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'byron_test_vector.dart' as byron;
import 'lagacy_test_vector.dart' as lagacy;

void adaByronAddrTest() {
  for (final i in lagacy.testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    params["chain_code"] = BytesUtils.fromHexString(params["chain_code"]);
    params["hd_path_key"] = BytesUtils.fromHexString(params["hd_path_key"]);
    final l = AdaByronLegacyAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(l == i["address"]);
    final decode = AdaByronAddrDecoder().decodeAddr(l);
    assert(
        BytesUtils.bytesEqual(decode, BytesUtils.fromHexString(i["decode"])));
  }

  for (final i in byron.testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    params["chain_code"] = BytesUtils.fromHexString(params["chain_code"]);
    final l = AdaByronIcarusAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(l == i["address"]);
    final decode = AdaByronAddrDecoder().decodeAddr(l);
    assert(
        BytesUtils.bytesEqual(decode, BytesUtils.fromHexString(i["decode"])));
  }
}
