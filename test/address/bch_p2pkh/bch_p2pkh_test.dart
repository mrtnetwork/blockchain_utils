import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("bch p2pkh test", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      final z = BchP2PKHAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        netVersion: BytesUtils.fromHexString(params["net_ver"]),
        hrp: params["hrp"],
      );
      expect(z, i["address"]);
      final decode = BchP2PKHAddrDecoder().decodeAddr(
        z,
        netVersion: BytesUtils.fromHexString(params["net_ver"]),
        hrp: params["hrp"],
      );
      expect(decode.toHex(), i["decode"]);
    }
  });
}
