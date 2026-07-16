import 'package:blockchain_utils/bip/address/xlm_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("xml address test", () {
    for (final i in testVector.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);
      final addrType = XlmAddrTypes.values.firstWhere(
        (element) => element.value == params["addr_type"],
      );

      final z = XlmAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        addrType: addrType,
      );
      expect(z, i["address"]);
      final decode = XlmAddrDecoder().decodeAddr(z, addrType: addrType);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
