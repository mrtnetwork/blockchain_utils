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
      final z = AdaShelleyAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        pubSkey: BytesUtils.fromHexString(params["pub_skey"]),
      );
      expect(z, i["address"]);
      final decode = AdaShelleyAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
  test("ada shelly stacking address test", () {
    for (final i in t.testVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      final netTag = ADANetwork.values.firstWhere(
        (element) =>
            element.name.toLowerCase() ==
            (params["net_tag"] as String).toLowerCase(),
      );
      final z = AdaShelleyStakingAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        network: netTag,
      );
      expect(z, i["address"]);
      final decode = AdaShelleyStakingAddrDecoder().decodeAddr(
        z,
        network: netTag,
      );
      expect(decode.toHex(), i["decode"]);
    }
  });
}
