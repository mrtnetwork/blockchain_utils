import 'package:blockchain_utils/bip/address/ada/ada_byron_addr.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';
import 'byron_test_vector.dart' as byron;
import 'lagacy_test_vector.dart' as lagacy;

void main() {
  test("ada byron legacy test", () {
    for (final i in lagacy.testVector) {
      final params = Map<String, dynamic>.from(i["params"]);

      final l = AdaByronLegacyAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        path: params["hd_path"],
        chainCode: BytesUtils.fromHexString(params["chain_code"]),
        hdPathKey: BytesUtils.fromHexString(params["hd_path_key"]),
      );
      expect(l, i["address"]);
      final decode = AdaByronAddrDecoder().decodeAddr(l);
      expect(
        BytesUtils.bytesEqual(decode, BytesUtils.fromHexString(i["decode"])),
        true,
      );
    }
  });

  test("ada byron icarus test", () {
    for (final i in byron.testVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      final l = AdaByronIcarusAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        chainCode: BytesUtils.fromHexString(params["chain_code"]),
      );
      expect(l, i["address"]);
      final decode = AdaByronAddrDecoder().decodeAddr(l);
      expect(
        BytesUtils.bytesEqual(decode, BytesUtils.fromHexString(i["decode"])),
        true,
      );
    }
  });
}
