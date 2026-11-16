// BN254 scalar field Fr, order
// r = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
// Same 4-limb Montgomery machinery as Fp; used for subgroup checks and
// scalar arithmetic. Secret selects stay mask-based.
import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class Bn254FrConst {
  static const Uint64 inv = Uint64.unsafe(3269588371, 4026531839);
  static const modulus = Bn254Fr.unsafe([
    Uint64.unsafe(1138881939, 4026531841),
    Uint64.unsafe(674490440, 2042196113),
    Uint64.unsafe(3092268470, 2172737629),
    Uint64.unsafe(811880050, 3778125865),
  ]);
}

class Bn254Fr with ConstantEquality<Bn254Fr> {
  final List<Uint64> limbs;
  const Bn254Fr.unsafe(this.limbs);
  Bn254Fr(List<Uint64> limbs)
      : limbs = limbs.exc(length: 4, operation: 'Bn254Fr').immutable;

  static const zero = Bn254Fr.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);

  static const one = Bn254Fr.unsafe([
    Uint64.unsafe(2895524892, 1342177275),
    Uint64.unsafe(922515093, 2673921321),
    Uint64.unsafe(1718526831, 2021213742),
    Uint64.unsafe(235567041, 2584207151),
  ]);

  static const r2 = Bn254Fr.unsafe([
    Uint64.unsafe(465102405, 2921426343),
    Uint64.unsafe(1409170097, 3814480355),
    Uint64.unsafe(2353627965, 1404797061),
    Uint64.unsafe(35049649, 2135835813),
  ]);

  factory Bn254Fr.montgomeryReduce(List<Uint64> t) {
    assert(t.length == 8);
    final a = List<Uint64>.from(t);
    final inv = Bn254FrConst.inv;
    final mod = Bn254FrConst.modulus.limbs;
    for (int i = 0; i < 4; i++) {
      final k = a[i] * inv;
      var carry = Uint64.zero;
      for (int j = 0; j < 4; j++) {
        final res = Uint64.mac(a[i + j], k, mod[j], carry);
        a[i + j] = res.$1;
        carry = res.$2;
      }
      for (int j = i + 4; j < 8; j++) {
        final res = Uint64.adc(a[j], Uint64.zero, carry);
        a[j] = res.$1;
        carry = res.$2;
      }
    }
    return Bn254Fr([a[4], a[5], a[6], a[7]])._subtractP();
  }

  factory Bn254Fr.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        'Bn254Fr',
        reason: 'Invalid scalar bytes length.',
      );
    }
    final tmp = Bn254Fr([
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 24),
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 16),
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 8),
      Uint64.fromBytes(bytes, endian: Endian.big),
    ]);
    Uint64 borrow = Uint64.zero;
    var temp = Uint64.sbb(tmp.limbs[0], Bn254FrConst.modulus.limbs[0], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[1], Bn254FrConst.modulus.limbs[1], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[2], Bn254FrConst.modulus.limbs[2], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[3], Bn254FrConst.modulus.limbs[3], borrow);
    borrow = temp.$2;
    if ((borrow & Uint64.one) != Uint64.one) {
      throw CoreErrors.invalidOperationArguments(
        'Bn254Fr',
        reason: 'Invalid scalar encoding bytes.',
      );
    }
    return tmp * Bn254Fr.r2;
  }

  /// Raw BE bytes -> Fr mod r (for EIP-196 scalars which may be >= r).
  factory Bn254Fr.fromBytesReduced(List<int> bytes) {
    if (bytes.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        'Bn254Fr.fromBytesReduced',
        reason: 'Invalid scalar bytes length.',
      );
    }
    // The input scalar encoding is public data, not a secret timing input
    // for the field reduction itself (secret handling happens in point mul),
    // so a BigInt mod here is acceptable.
    BigInt v = BigInt.zero;
    for (final b in bytes) {
      v = (v << 8) | BigInt.from(b);
    }
    const rHex =
        '30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001';
    final r = BigInt.parse(rHex, radix: 16);
    v = v % r;
    final out = List<int>.filled(32, 0);
    for (int i = 31; i >= 0; i--) {
      out[i] = (v & BigInt.from(0xff)).toInt();
      v >>= 8;
    }
    return Bn254Fr.fromBytes(out);
  }

  factory Bn254Fr.conditionalSelect(Bn254Fr a, Bn254Fr b, bool choice) {
    return Bn254Fr([
      Uint64.ctSelect(a.limbs[0], b.limbs[0], choice),
      Uint64.ctSelect(a.limbs[1], b.limbs[1], choice),
      Uint64.ctSelect(a.limbs[2], b.limbs[2], choice),
      Uint64.ctSelect(a.limbs[3], b.limbs[3], choice),
    ]);
  }

  Bn254Fr _subtractP() {
    var tmp = Uint64.sbb(limbs[0], Bn254FrConst.modulus.limbs[0], Uint64.zero);
    Uint64 r0 = tmp.$1;
    Uint64 borrow = tmp.$2;
    tmp = Uint64.sbb(limbs[1], Bn254FrConst.modulus.limbs[1], borrow);
    Uint64 r1 = tmp.$1;
    borrow = tmp.$2;
    tmp = Uint64.sbb(limbs[2], Bn254FrConst.modulus.limbs[2], borrow);
    Uint64 r2 = tmp.$1;
    borrow = tmp.$2;
    tmp = Uint64.sbb(limbs[3], Bn254FrConst.modulus.limbs[3], borrow);
    Uint64 r3 = tmp.$1;
    borrow = tmp.$2;
    r0 = ((limbs[0] & borrow) | (r0 & ~borrow));
    r1 = ((limbs[1] & borrow) | (r1 & ~borrow));
    r2 = ((limbs[2] & borrow) | (r2 & ~borrow));
    r3 = ((limbs[3] & borrow) | (r3 & ~borrow));
    return Bn254Fr([r0, r1, r2, r3]);
  }

  Bn254Fr _add(Bn254Fr rhs) {
    var tmp = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    final d0 = tmp.$1;
    var carry = tmp.$2;
    tmp = Uint64.adc(limbs[1], rhs.limbs[1], carry);
    final d1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(limbs[2], rhs.limbs[2], carry);
    final d2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(limbs[3], rhs.limbs[3], carry);
    final d3 = tmp.$1;
    return Bn254Fr([d0, d1, d2, d3])._subtractP();
  }

  Bn254Fr _neg() {
    var tmp = Uint64.sbb(Bn254FrConst.modulus.limbs[0], limbs[0], Uint64.zero);
    final d0 = tmp.$1;
    var borrow = tmp.$2;
    tmp = Uint64.sbb(Bn254FrConst.modulus.limbs[1], limbs[1], borrow);
    final d1 = tmp.$1;
    borrow = tmp.$2;
    tmp = Uint64.sbb(Bn254FrConst.modulus.limbs[2], limbs[2], borrow);
    final d2 = tmp.$1;
    borrow = tmp.$2;
    tmp = Uint64.sbb(Bn254FrConst.modulus.limbs[3], limbs[3], borrow);
    final d3 = tmp.$1;
    final x = limbs[0] | limbs[1] | limbs[2] | limbs[3];
    final mask = (x == Uint64.zero) ? Uint64.zero : Uint64.max;
    return Bn254Fr([d0 & mask, d1 & mask, d2 & mask, d3 & mask]);
  }

  Bn254Fr _mul(Bn254Fr rhs) {
    final t = List<Uint64>.filled(8, Uint64.zero);
    for (int i = 0; i < 4; i++) {
      var carry = Uint64.zero;
      for (int j = 0; j < 4; j++) {
        final res = Uint64.mac(t[i + j], limbs[i], rhs.limbs[j], carry);
        t[i + j] = res.$1;
        carry = res.$2;
      }
      int k = i + 4;
      while (carry != Uint64.zero && k < 8) {
        final res = Uint64.adc(t[k], Uint64.zero, carry);
        t[k] = res.$1;
        carry = res.$2;
        k++;
      }
    }
    return Bn254Fr.montgomeryReduce(t);
  }

  bool isZero() => this == Bn254Fr.zero;
  Bn254Fr operator +(Bn254Fr rhs) => _add(rhs);
  Bn254Fr operator -(Bn254Fr rhs) => rhs._neg()._add(this);
  Bn254Fr operator *(Bn254Fr rhs) => _mul(rhs);
  Bn254Fr operator -() => _neg();

  BuBytes toBytes() {
    final tmp = Bn254Fr.montgomeryReduce([
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    ]);
    return BuBytes(
      tmp.limbs.reversed.expand((e) => e.toBytes(Endian.big)).toList(),
    );
  }

  @override
  bool constantEquality(Bn254Fr other) =>
      Uint64.ctEquals(limbs, other.limbs);
}
