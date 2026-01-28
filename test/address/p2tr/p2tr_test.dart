import 'package:blockchain_utils/bip/address/p2tr_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("p2tr address test", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from(i["params"]);

      final z = P2TRAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        hrp: params["hrp"],
      );
      expect(z, i["address"]);
      final decode = P2TRAddrDecoder().decodeAddr(z, hrp: params["hrp"]);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
