import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/constants.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/fields.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

/// Monero hash-to-point (Elligator2-style map + ×8 cofactor clearing).
///
/// Limb port of the audited `ge_fromfe_frombytes_vartime` map: the formulas
/// are identical, but every operation runs on [Ed25519Fp] limbs.
///
/// Vartime by design: the input is a public hash, so the zero/parity
/// branches below depend only on public data, never on secrets. Secret
/// scalar multiplication still goes through the straight-line
/// [EdwardsLimbPoint] ladder.
class MoneroH2C {
  static const Ed25519Fp _a = Ed25519Fp.unsafe([
    Uint64.unsafe(0, 18493156),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
  ]);
  static const Ed25519Fp _two = Ed25519Fp.unsafe([
    Uint64.unsafe(0, 76),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
  ]);
  static const Ed25519Fp _sqrtM1 = Ed25519Fp.unsafe([
    Uint64.unsafe(995624916, 4264286980),
    Uint64.unsafe(66425085, 3038505453),
    Uint64.unsafe(1835931327, 862061265),
    Uint64.unsafe(1970760459, 3603372968),
  ]);

  static const Ed25519Fp _fffb1 = Ed25519Fp.unsafe([
    Uint64.unsafe(3676723354, 2412655578),
    Uint64.unsafe(3825684212, 2209536268),
    Uint64.unsafe(650951116, 884615214),
    Uint64.unsafe(991205989, 2218261137),
  ]);
  static const Ed25519Fp _fffb2 = Ed25519Fp.unsafe([
    Uint64.unsafe(1292036992, 1384054498),
    Uint64.unsafe(653556836, 2766719801),
    Uint64.unsafe(2776899910, 2203203136),
    Uint64.unsafe(1860728188, 2774707353),
  ]);
  static const Ed25519Fp _fffb3 = Ed25519Fp.unsafe([
    Uint64.unsafe(3958070770, 2396612239),
    Uint64.unsafe(2055346771, 1806839260),
    Uint64.unsafe(2581041782, 2751058120),
    Uint64.unsafe(721516558, 3945966698),
  ]);
  static const Ed25519Fp _fffb4 = Ed25519Fp.unsafe([
    Uint64.unsafe(955140466, 3780666756),
    Uint64.unsafe(2708903608, 278591766),
    Uint64.unsafe(1062974397, 659293960),
    Uint64.unsafe(434761099, 2425706756),
  ]);

  /// (p + 3) / 8 with p = 2^255 - 19, little-endian limbs: 2^252 - 2.
  static const List<Uint64> _expo = [
    Uint64.unsafe(0xFFFFFFFF, 0xFFFFFFFE),
    Uint64.max,
    Uint64.max,
    Uint64.unsafe(0x0FFFFFFF, 0xFFFFFFFF),
  ];

  /// Maps 32 hashed bytes to a curve point (then clears the cofactor, like
  /// `hash_to_ec`: ×8 via three doublings).
  static EdwardsLimbPoint geFromFeFromBytesVartime(List<int> s) {
    final bytes32 = s.sublist(0, 32);
    // Reduce the 256-bit LE input mod p with a single mask-selected
    // subtract (at most one subtract: input < 2^256 < 2p).
    final t = List<Uint64>.generate(
      4,
      (i) => Uint64.fromBytes(bytes32, endian: Endian.little, offset: i * 8),
    );
    var tp = Uint64.sbb(t[0], Ed25519FpConst.modulusLimbs[0], Uint64.zero);
    final d0 = tp.$1;
    var borrow = tp.$2 & Uint64.one;
    tp = Uint64.sbb(t[1], Ed25519FpConst.modulusLimbs[1], borrow);
    final d1 = tp.$1;
    borrow = tp.$2 & Uint64.one;
    tp = Uint64.sbb(t[2], Ed25519FpConst.modulusLimbs[2], borrow);
    final d2 = tp.$1;
    borrow = tp.$2 & Uint64.one;
    tp = Uint64.sbb(t[3], Ed25519FpConst.modulusLimbs[3], borrow);
    final d3 = tp.$1;
    // tp.$2 is a borrow mask (all-ones iff t < p, i.e. no subtract).
    final keepRaw = tp.$2;
    final bit = (~keepRaw) & Uint64.one;
    final u = Ed25519Fp.fromRaw([
      Uint64.selectBit(t[0], d0, bit),
      Uint64.selectBit(t[1], d1, bit),
      Uint64.selectBit(t[2], d2, bit),
      Uint64.selectBit(t[3], d3, bit),
    ]);

    final v = _two * u * u;
    final w = v + Ed25519Fp.one;
    final x = w * w - _a * _a * v;
    var r = x.isZero() ? Ed25519Fp.zero : (w * x.invert()!).pow(_expo);

    final rx = r * r * x;
    var z = -_a;
    int sign;

    if (!(w - rx).isZero()) {
      if (!(w + rx).isZero()) {
        // Negative branch.
        final x2 = rx * _sqrtM1;
        r = (w - x2).isZero() ? r * _fffb4 : r * _fffb3;
        sign = 1; // z stays -A
      } else {
        r = r * _fffb1 * u;
        z = z * v;
        sign = 0;
      }
    } else {
      r = r * _fffb2 * u;
      z = z * v;
      sign = 0;
    }

    if ((r.toBytes()[0] & 1) != sign) r = -r;

    final Z = z + w;
    final Y = z - w;
    final y = Y * Z.invert()!;

    final pt = EdwardsLimbPoint(x: r, y: y, z: Ed25519Fp.one, t: r * y);
    return pt.double().double().double(); // mul8, like hash_to_ec
  }
}
