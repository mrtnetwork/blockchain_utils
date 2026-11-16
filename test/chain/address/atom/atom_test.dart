import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:test/test.dart';
import 'test_vector.dart';

import '../../../utils.dart';

void atomTest() {
  test("atom address test", () {
    for (final i in testVector.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);

      final z = AtomAddrEncoder().encodeKey(
        i.valueAsBytes("public"),
        hrp: params["hrp"],
      );
      expect(z, i.valueAs("address"));
      final decode = AtomAddrDecoder().decodeAddr(z, hrp: params["hrp"]);
      expect(decode.toHex(), i.valueAs("decode"));
    }
    for (final i in cosmosTestVectors) {
      final String typeStr = i.valueAs("publicKeyType");

      final type = CryptoKeyType.fromName(typeStr);
      final addr = AtomAddrEncoder().encodeKey(
        i.valueAsBytes("publicKey"),
        hrp: "cosmos",
        type: type,
      );
      expect(addr, i.valueAs("address"));
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(atomTest, "Atom");
}
