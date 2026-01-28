import 'package:blockchain_utils/bip/address/avax_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_p_vector.dart' as p;
import 'test_x_vector.dart' as x;

void main() {
  test("avax P-address test", () {
    for (final i in p.testVector) {
      final z = AvaxPChainAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = AvaxPChainAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
  test("avax x-address test", () {
    for (final i in x.testVector) {
      final z = AvaxXChainAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = AvaxXChainAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
