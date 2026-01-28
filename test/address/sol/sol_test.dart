import 'package:blockchain_utils/bip/address/sol_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("solana address test", () {
    for (final i in testVector) {
      final z = SolAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = SolAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
