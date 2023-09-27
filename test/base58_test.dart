import 'package:blockchain_utils/formating/bytes_num_formating.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_utils/base58/base58.dart' as base58;

// This main function contains tests for Base58 encoding and decoding.
// It defines four Base58-encoded strings (t1, t2, t3, t4) and their corresponding
// hexadecimal representations (decodeHex1, decodeHex2, decodeHex3, decodeHex4).
// The 'Base58 Decoding' test checks if the Base58-encoded strings can be correctly
// decoded into hexadecimal representations, and the 'Base58 Encoding' test verifies
// if the hexadecimal representations can be correctly encoded back to Base58 strings.
void main() {
  const t1 = "Vr7RY7xKg9p2DveTGK9wdmt3hF7ZL1Dv9RZhMkzg";
  const t2 = "4j3d1LQWwz4WUD7FWM9zQW6tQZ74G41UGueXhEfq3";
  const t3 = "K2EawqLkz9T7VdQYfUhK6t3LZwWM9K7Q7vuF1jpF";
  const t4 = "3f64DM2pZUE7hA9pKRzHwtGw4m8CfGLMkXQz7nZKR";
  const decodeHex1 =
      "027b6eb76c60909f75e67542491ea985c1f67c3c38018af38cda09d8babd";
  const decodeHex2 =
      "129704839210baee4aba7fc7abbc914d88926f400f0420044741284d43c2";
  const decodeHex3 =
      "018cf8799dc5b96f6ddc9d38c78c9a89c352e505e0b5408158bb8f07733c";
  const decodeHex4 =
      "0d4236b22ce2293fe49a6c360821ea3f31128896fa852af79a5cff7a2274";

  // The 'Base58 Decoding' test verifies the correctness of decoding Base58 strings
  // into hexadecimal representations.
  test('Base58 Decoding', () {
    final decode = base58.decode(t1);
    expect(bytesToHex(decode), decodeHex1);
    final decode2 = base58.decode(t2);
    expect(bytesToHex(decode2), decodeHex2);
    final decode3 = base58.decode(t3);
    expect(bytesToHex(decode3), decodeHex3);
    final decode4 = base58.decode(t4);
    expect(bytesToHex(decode4), decodeHex4);
  });

  // The 'Base58 Encoding' test verifies the correctness of encoding hexadecimal
  // representations back to Base58 strings.
  test('Base58 Encoding', () {
    final decode = base58.encode(hexToBytes(decodeHex1));
    expect(decode, t1);
    final decode2 = base58.encode(hexToBytes(decodeHex2));
    expect(decode2, t2);
    final decode3 = base58.encode(hexToBytes(decodeHex3));
    expect(decode3, t3);
    final decode4 = base58.encode(hexToBytes(decodeHex4));
    expect(decode4, t4);
  });
}
