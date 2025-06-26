import 'package:blockchain_utils/bech32/bech32.dart';
import 'package:blockchain_utils/bip/address/address_conversion.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("address conversion test", () {
    for (final i in testVector) {
      final bech32Address = i["bech32"]!;
      final hexAddress = i["hex"]!;

      final prefix = bech32Address.split(Bech32Const.separator)[0];

      // Convert Bech32 to Hex
      final convertedHex = AddressConversion.bech32ToHex(bech32Address, prefix);
      expect(
          convertedHex,
          hexAddress.toLowerCase(),
          reason: "Converting $bech32Address, Expected: $hexAddress, but got: $convertedHex"
      );

      // Convert Hex to Bech32
      final convertedBech32 = AddressConversion.hexToBech32(hexAddress, prefix);
      expect(
          convertedBech32,
          bech32Address,
          reason: "Converting $hexAddress, Expected: $bech32Address, but got: $convertedBech32"
      );
    }
  });
}
