import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/point/extended.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

void _ensureScalarLen(List<int> by, String op) {
  if (by.length != 32) {
    throw CoreErrors.cryptoFailed(op, reason: 'Invalid scalar bytes length.');
  }
}

/// A projective JubJub point precomputed in "Niels" form `(v+u, v-u, z, 2d*t)`,
/// the addend form used for fast mixed addition.
class JubJubNielsPoint extends BaseJubJubNielsPoint<JubJubFr> with Equality {
  final JubJubFq vPlusU;
  final JubJubFq vMinusU;
  final JubJubFq z;
  final JubJubFq t2d;

  JubJubNielsPoint({
    required this.vPlusU,
    required this.z,
    required this.vMinusU,
    required this.t2d,
  });
  factory JubJubNielsPoint.identity() {
    return JubJubNielsPoint(
      vPlusU: JubJubFq.one,
      vMinusU: JubJubFq.one,
      z: JubJubFq.one,
      t2d: JubJubFq.zero,
    );
  }
  factory JubJubNielsPoint.conditionalSelect(
    JubJubNielsPoint a,
    JubJubNielsPoint b,
    bool choice,
  ) {
    return JubJubNielsPoint(
      vPlusU: JubJubFq.conditionalSelect(a.vPlusU, b.vPlusU, choice),
      vMinusU: JubJubFq.conditionalSelect(a.vMinusU, b.vMinusU, choice),
      z: JubJubFq.conditionalSelect(a.z, b.z, choice),
      t2d: JubJubFq.conditionalSelect(a.t2d, b.t2d, choice),
    );
  }

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so scalar-multiplication selects stay straight-line.
  factory JubJubNielsPoint.conditionalSelectMask(
    JubJubNielsPoint a,
    JubJubNielsPoint b,
    Uint64 bit,
  ) {
    return JubJubNielsPoint(
      vPlusU: JubJubFq.conditionalSelectMask(a.vPlusU, b.vPlusU, bit),
      vMinusU: JubJubFq.conditionalSelectMask(a.vMinusU, b.vMinusU, bit),
      z: JubJubFq.conditionalSelectMask(a.z, b.z, bit),
      t2d: JubJubFq.conditionalSelectMask(a.t2d, b.t2d, bit),
    );
  }
  @override
  JubJubPoint operator *(JubJubFr rhs) {
    return multiply(rhs.toBytes());
  }

  @override
  JubJubNielsPoint operator +(BaseRedJubJubPoint rhs) {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  BuBytes toBytes() {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  JubJubNielsPoint toNiels() {
    return this;
  }

  @override
  JubJubPoint multiply(List<int> by) {
    _ensureScalarLen(by, 'JubJubNielsPoint.multiply');
    final zero = JubJubNielsPoint.identity();
    JubJubPoint acc = JubJubPoint.identity();
    // Same bit sequence as before (`bytesToBits` LE, top 4 bits skipped for
    // the 252-bit order), but the per-bit select is a Uint64 mask blend —
    // no `bool` on the secret scalar.
    for (int i = 251; i >= 0; i--) {
      acc = acc.double();
      final bit = Uint64((by[i >> 3] >> (i & 7)) & 1);
      acc += JubJubNielsPoint.conditionalSelectMask(zero, this, bit);
    }
    return acc;
  }

  @override
  JubJubNielsPoint operator -(BaseRedJubJubPoint rhs) {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  JubJubNielsPoint operator -() {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  List<dynamic> get variables => [vMinusU, vPlusU, z, t2d];
}

/// An affine JubJub point precomputed in Niels form `(v+u, v-u, 2d*t)`.
class JubJubAffineNielsPoint extends BaseJubJubNielsPoint<JubJubFr>
    with Equality {
  final JubJubFq vPlusU;
  final JubJubFq vMinusU;
  final JubJubFq t2d;

  JubJubAffineNielsPoint({
    required this.vPlusU,
    required this.vMinusU,
    required this.t2d,
  });
  factory JubJubAffineNielsPoint.conditionalSelect(
    JubJubAffineNielsPoint a,
    JubJubAffineNielsPoint b,
    bool choice,
  ) {
    return JubJubAffineNielsPoint(
      vMinusU: JubJubFq.conditionalSelect(a.vMinusU, b.vMinusU, choice),
      vPlusU: JubJubFq.conditionalSelect(a.vPlusU, b.vPlusU, choice),
      t2d: JubJubFq.conditionalSelect(a.t2d, b.t2d, choice),
    );
  }

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so scalar-multiplication selects stay straight-line.
  factory JubJubAffineNielsPoint.conditionalSelectMask(
    JubJubAffineNielsPoint a,
    JubJubAffineNielsPoint b,
    Uint64 bit,
  ) {
    return JubJubAffineNielsPoint(
      vMinusU: JubJubFq.conditionalSelectMask(a.vMinusU, b.vMinusU, bit),
      vPlusU: JubJubFq.conditionalSelectMask(a.vPlusU, b.vPlusU, bit),
      t2d: JubJubFq.conditionalSelectMask(a.t2d, b.t2d, bit),
    );
  }
  factory JubJubAffineNielsPoint.identity() {
    return JubJubAffineNielsPoint(
      vPlusU: JubJubFq.one,
      vMinusU: JubJubFq.one,
      t2d: JubJubFq.zero,
    );
  }
  @override
  JubJubPoint operator *(JubJubFr rhs) {
    return multiply(rhs.toBytes());
  }

  @override
  JubJubAffineNielsPoint operator +(BaseRedJubJubPoint rhs) {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  JubJubAffineNielsPoint operator -(BaseRedJubJubPoint rhs) {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  BuBytes toBytes() {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  JubJubAffineNielsPoint toNiels() {
    return this;
  }

  @override
  JubJubAffineNielsPoint operator -() {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  JubJubPoint multiply(List<int> by) {
    _ensureScalarLen(by, 'JubJubAffineNielsPoint.multiply');
    final zero = JubJubAffineNielsPoint.identity();
    JubJubPoint acc = JubJubPoint.identity();
    // Same bit sequence as before (`bytesToBits` LE, top 4 bits skipped for
    // the 252-bit order), but the per-bit select is a Uint64 mask blend —
    // no `bool` on the secret scalar.
    for (int i = 251; i >= 0; i--) {
      acc = acc.double();
      final bit = Uint64((by[i >> 3] >> (i & 7)) & 1);
      acc += JubJubAffineNielsPoint.conditionalSelectMask(zero, this, bit);
    }
    return acc;
  }

  @override
  List<dynamic> get variables => [vMinusU, vPlusU, t2d];
}
