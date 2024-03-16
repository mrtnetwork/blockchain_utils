import 'package:blockchain_utils/bip/address/ada/ada_byron_addr.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/compare/compare.dart';
import 'package:test/test.dart';
import 'byron_test_vector.dart' as byron;
import 'lagacy_test_vector.dart' as lagacy;

void main() {
  test("ada byron legacy test", () {
    for (final i in lagacy.testVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      params["chain_code"] = BytesUtils.fromHexString(params["chain_code"]);
      params["hd_path_key"] = BytesUtils.fromHexString(params["hd_path_key"]);
      final l = AdaByronLegacyAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(l, i["address"]);
      final decode = AdaByronAddrDecoder().decodeAddr(l);
      expect(bytesEqual(decode, BytesUtils.fromHexString(i["decode"])), true);
    }
  });

  test("ada byron icarus test", () {
    for (final i in byron.testVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      params["chain_code"] = BytesUtils.fromHexString(params["chain_code"]);
      final l = AdaByronIcarusAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(l, i["address"]);
      final decode = AdaByronAddrDecoder().decodeAddr(l);
      expect(bytesEqual(decode, BytesUtils.fromHexString(i["decode"])), true);
    }
  });
}
