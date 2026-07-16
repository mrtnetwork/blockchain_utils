import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';

class JubJubFrConst {
  static const int bits = 252;
  static const int capacity = bits - 1;
  static const int s = 1;
  static const Uint64 inv = Uint64.unsafe(463709016, 4017655545);
  static const modulus = JubJubFr.unsafe([
    Uint64.unsafe(3499560542, 3606523063),
    Uint64.unsafe(2791841939, 3435663490),
    Uint64.unsafe(107428609, 20200192),
    Uint64.unsafe(243119338, 1697886121),
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
  static const Uint64 inv = Uint64.unsafe(4294967294, 4294967295);

  static const modulus = JubJubFq.unsafe([
    Uint64.unsafe(4294967295, 1),
    Uint64.unsafe(1404937218, 4294859774),
    Uint64.unsafe(859428872, 161601541),
    Uint64.unsafe(1944954707, 698187080),
  ]);
}
