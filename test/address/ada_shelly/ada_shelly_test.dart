import 'package:blockchain_utils/bip/address/ada/ada_shelley_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/address/encoders.dart';
import 'package:test/test.dart';
import '../../quick_hex.dart';
import 'test_vector.dart';
import 'stacking_test_vector.dart' as t;

void main() {
  test("adda shelly address test", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      params["pub_skey"] = BytesUtils.fromHexString(params["pub_skey"]);
      final z = AdaShelleyAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(z, i["address"]);
      final decode = AdaShelleyAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
  test("ada shelly stacking address test", () {
    for (final i in t.testVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      final netTag = ADANetwork.values.firstWhere((element) =>
          element.name.toLowerCase() ==
          (params["net_tag"] as String).toLowerCase());

      params["net_tag"] = netTag;
      final z = AdaShelleyStakingAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(z, i["address"]);
      final decode = AdaShelleyStakingAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
