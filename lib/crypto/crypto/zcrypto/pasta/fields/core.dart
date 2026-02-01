import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Abstract base class for elements of a Pasta prime field, supporting arithmetic, comparison, and byte/bit conversions.
abstract class PastaFieldElement<F extends PastaFieldElement<F>>
    extends CryptoPrimeFieldElement<F>
    implements Comparable<F> {
  const PastaFieldElement();

  /// Returns the lowest 32 bits of the field element.
  int getLower32();

  /// Computes (self)^((t - 1)/2), used in curve-specific operations.
  F powByTMinus1Over2();

  /// Squares the element.
  @override
  F square();

  /// Doubles the element.
  @override
  F double();

  /// Returns true if the element is zero.
  @override
  bool isZero();

  /// Computes the square root of the element.
  @override
  FieldSqrtResult<F> sqrt();

  /// Computes the multiplicative inverse.
  @override
  F? invert();

  /// Returns true if the element is odd (least significant bit = 1)
  bool isOdd() => (toBytes()[0] & 1) == 1;

  /// Serializes the field element to bytes.
  @override
  List<int> toBytes();

  /// Conditional selection: returns [b] if choice is true, [a] otherwise.
  F conditionalSelect(F a, F b, bool choice);
  FieldSqrtResult<F> sRatio(F a, F b);

  /// Lexicographic comparison of field elements.
  @override
  int compareTo(F other) {
    final left = toBytes();
    final right = other.toBytes();
    assert(left.length == right.length, 'Byte arrays must be same length');
    for (int i = left.length - 1; i >= 0; i--) {
      if (left[i] != right[i]) {
        return left[i] - right[i];
      }
    }
    return 0;
  }

  /// Returns the field element as a list of bits (little-endian per limb).
  List<bool> toBits() {
    final toBytes = this.toBytes();
    final tmpLimbs = List<BigInt>.generate(4, (i) {
      return BigintUtils.fromBytes(
        toBytes.sublist(i * 8, (i * 8) + 8),
        byteOrder: Endian.little,
      );
    });
    return tmpLimbs
        .map((e) => BigintUtils.toBinaryBool(e, bitLength: 64))
        .expand((e) => e)
        .toList();
  }
}
