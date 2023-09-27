import 'package:blockchain_utils/formating/bytes_num_formating.dart';
import 'package:blockchain_utils/bech32/bech32.dart' as bech32;
import 'package:test/test.dart';

// This main function contains tests for encoding and decoding Bech32 addresses
// using the 'bech32' package. Two Bech32 addresses are tested: one for the 'tb'
// (testnet) network and one for the 'ltc' (Litecoin) network. The tests verify
// that the addresses can be correctly encoded from hexadecimal data and decoded
// back to their components, including the version, data, and human-readable part (HRP).
void main() {
  // Hexadecimal data and Bech32 address for 'tb' (testnet) network.
  const String decode1Hex =
      "7a712853f4301a463734e7b8bf406f40ba60d484e9f6c7e9aa222d9e1d5fd50d";
  const String address1 =
      "tb1p0fcjs5l5xqdyvde5u7ut7sr0gzaxp4yya8mv06d2ygkeu82l65xs6k4uqr";

  // Hexadecimal data and Bech32 address for 'ltc' (Litecoin) network.
  const String decodedHex = "20c7b72622ffb2ab9f8a0cac6c542e26ce37b38a";
  const String address2 = "ltc1qyrrmwf3zl7e2h8u2pjkxc4pwym8r0vu26yczn9";

  // The 'Encode Bech32 Address' test verifies that the hexadecimal data can be
  // correctly encoded into Bech32 addresses for both 'tb' and 'ltc' networks.
  test('Encode Bech32 Address', () {
    final encoded = bech32.encodeBech32("tb", hexToBytes(decode1Hex), 1);
    expect(encoded, address1);
    final encode2 = bech32.encodeBech32("ltc", hexToBytes(decodedHex), 0);
    expect(encode2, address2);
  });

  // The 'Decode Bech32 Address' test verifies that Bech32 addresses can be
  // correctly decoded into their version, data, and human-readable part (HRP)
  // components for both 'tb' and 'ltc' networks.
  test('Decode Bech32 Address', () {
    final decoded = bech32.decodeBech32(address1);
    expect(decoded?.version, 1);
    expect(bytesToHex(decoded!.data), decode1Hex);
    expect(decoded.hrp, "tb");

    final decodedx = bech32.decodeBech32(address2);
    expect(decodedx!.version, 0);
    expect(bytesToHex(decodedx.data), decodedHex);
    expect(decodedx.hrp, "ltc");
  });
  test('Decode Bech32 Address', () {
    final decoded = bech32.decodeBech32(address1);
    expect(decoded?.version, 1);
    expect(bytesToHex(decoded!.data), decode1Hex);
    expect(decoded.hrp, "tb");

    final decodedx = bech32.decodeBech32(address2);
    expect(decodedx!.version, 0);
    expect(bytesToHex(decodedx.data), decodedHex);
    expect(decodedx.hrp, "ltc");
  });
}
