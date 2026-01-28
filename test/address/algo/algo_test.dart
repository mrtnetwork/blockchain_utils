import 'package:blockchain_utils/bip/address/algo_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  test("algo address tes", () {
    for (final i in testVector) {
      final z = AlgoAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = AlgoAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
