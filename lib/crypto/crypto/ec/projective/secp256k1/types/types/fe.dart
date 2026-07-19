import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';

abstract class BaseSecp256k1Fe extends Iterable<Uint64> {
  const BaseSecp256k1Fe();
  abstract final List<Uint64> limbs;
  @override
  Iterator<Uint64> get iterator => limbs.iterator;
  Uint64 operator [](int index) => limbs[index];
  Secp256k1Fe clone() => Secp256k1Fe._(limbs: limbs);
}

class Secp256k1FeConst extends BaseSecp256k1Fe {
  @override
  final List<Uint64> limbs;
  const Secp256k1FeConst.unsafe(this.limbs);
}

class Secp256k1Fe extends BaseSecp256k1Fe {
  List<Uint64> _limbs;
  factory Secp256k1Fe() {
    return Secp256k1Fe._();
  }
  Secp256k1Fe._({List<Uint64>? limbs})
    : _limbs = limbs?.clone() ?? List<Uint64>.filled(5, Uint64.zero);

  void fillZero() {
    for (int i = 0; i < 5; i++) {
      _limbs[i] = Uint64.zero;
    }
  }

  // You can add methods or constructors to initialize this class more effectively
  // For example, constructor to initialize n with specific values
  factory Secp256k1Fe._inner(
    BigInt d7,
    BigInt d6,
    BigInt d5,
    BigInt d4,
    BigInt d3,
    BigInt d2,
    BigInt d1,
    BigInt d0, {
    bool immutable = false,
  }) {
    final r =
        [
          (d0) | (((d1) & 0xFFFFF.toBigInt) << 32),
          ((d1.toU64) >> 20) |
              (((d2.toU64)) << 12) |
              (((d3.toU64) & 0xFF.toBigInt) << 44),
          ((d3.toU64) >> 8) | (((d4.toU64) & 0xFFFFFFF.toBigInt) << 24),
          ((d4.toU64) >> 28) |
              (((d5.toU64)) << 4) |
              (((d6.toU64) & 0xFFFF.toBigInt) << 36),
          ((d6.toU64) >> 16) | (((d7.toU64)) << 16),
        ].map((e) => Uint64.fromBigInt(e)).toList();
    return Secp256k1Fe._(limbs: immutable ? r.toImutableList : r);
  }
  factory Secp256k1Fe.constants(
    BigInt d7,
    BigInt d6,
    BigInt d5,
    BigInt d4,
    BigInt d3,
    BigInt d2,
    BigInt d1,
    BigInt d0,
  ) {
    return Secp256k1Fe._inner(d7, d6, d5, d4, d3, d2, d1, d0, immutable: false);
  }

  void operator []=(int index, Uint64 value) {
    _limbs[index] = value;
  }

  void fill(BaseSecp256k1Fe other) {
    for (int i = 0; i < 5; i++) {
      _limbs[i] = other.limbs[i];
    }
  }

  @override
  List<Uint64> get limbs => _limbs;
}
