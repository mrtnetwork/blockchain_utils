import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/utils/utils.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

/// Abstract base class for elements of a Pasta prime field, supporting arithmetic, comparison, and byte/bit conversions.
abstract class PastaFieldElement<F extends PastaFieldElement<F>>
    extends CryptoPrimeFieldElement<F>
    implements Comparable<F> {
  const PastaFieldElement();

  /// Montgomery limbs backing this element (all Pasta fields are 4-limb).
  /// Exposed so point arithmetic can fold comparisons into 0/1 masks
  /// without `bool` branches on secret data.
  List<Uint64> get limbs;

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
  /// Plain int ops, no BigInt: byte-major with LSB-first bits per byte,
  /// matching the previous limb-chunked conversion exactly.
  List<bool> toBits() {
    final bytes = toBytes();
    final bits = List<bool>.filled(bytes.length * 8, false);
    for (var i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      for (var k = 0; k < 8; k++) {
        bits[i * 8 + k] = ((b >> k) & 1) != 0;
      }
    }
    return bits;
  }
}
