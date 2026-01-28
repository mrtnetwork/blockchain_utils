import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

abstract class PastaFieldElement<F extends PastaFieldElement<F>>
    extends CryptoPrimeFieldElement<F>
    implements Comparable<F> {
  const PastaFieldElement();
  int getLower32();
  F powByTMinus1Over2();
  @override
  F square();
  @override
  F double();
  @override
  bool isZero();
  @override
  FieldSqrtResult<F> sqrt();
  @override
  F? invert();
  bool isOdd() => (toBytes()[0] & 1) == 1;
  @override
  List<int> toBytes();
  F conditionalSelect(F a, F b, bool choice);
  FieldSqrtResult<F> sRatio(F a, F b);

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
