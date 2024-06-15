import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/address/substrate_addr.dart';
import '../../quick_hex.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("substrate ED25519 test", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from(i["params"]);

      final z = SubstrateEd25519AddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(z, i["address"]);
      final decode = SubstrateEd25519AddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
  test("substrate sr25519 test", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from(i["params"]);

      final z = SubstrateGenericAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(z, i["address"]);
      final decode = SubstrateGenericAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
