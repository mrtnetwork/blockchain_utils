import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';

class JubJubFrConst {
  static const int bits = 252;
  static const int capacity = bits - 1;
  static const int s = 1;
  static final inv = BigInt.parse("0x1ba3a358ef788ef9");
  static final modulus = JubJubFr([
    BigInt.parse("0xd0970e5ed6f72cb7"),
    BigInt.parse("0xa6682093ccc81082"),
    BigInt.parse("0x06673b0101343b00"),
    BigInt.parse("0x0e7db4ea6533afa9"),
  ]);

  static const List<int> frModulusBytes = [
    183,
    44,
    247,
    214,
    94,
    14,
    151,
    208,
    130,
    16,
    200,
    204,
    147,
    32,
    104,
    166,
    0,
    59,
    52,
    1,
    1,
    59,
    103,
    6,
    169,
    175,
    51,
    101,
    234,
    180,
    125,
    14,
  ];
}

class JubJubFqConst {
  static const int bits = 255;
  static const int capacity = bits - 1;
  static const int S = 32;
  static final BigInt inv = BigInt.parse("0xfffffffeffffffff");

  static final modulus = JubJubFq([
    BigInt.parse('0xffffffff00000001'),
    BigInt.parse('0x53bda402fffe5bfe'),
    BigInt.parse('0x3339d80809a1d805'),
    BigInt.parse('0x73eda753299d7d48'),
  ]);
}
