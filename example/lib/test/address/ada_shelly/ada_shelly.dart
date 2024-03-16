import 'package:blockchain_utils/bip/address/decoders.dart';
import 'package:blockchain_utils/bip/address/encoders.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'test_vector.dart';
import 'stacking_test_vector.dart' as t;

void adaShellyAddrTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    params["pub_skey"] = BytesUtils.fromHexString(params["pub_skey"]);
    final z = AdaShelleyAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = AdaShelleyAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
  for (final i in t.testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    final netTag = ADANetwork.values.firstWhere((element) =>
        element.name.toLowerCase() ==
        (params["net_tag"] as String).toLowerCase());

    params["net_tag"] = netTag;
    final z = AdaShelleyStakingAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = AdaShelleyStakingAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
