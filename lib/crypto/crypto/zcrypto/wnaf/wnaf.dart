import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class WnafUtils {
  static List<int> wnafForm(List<int> c, int window) {
    assert(window >= 2);
    assert(window <= 64);

    final bitLen = c.length * 8;
    final List<int> wnaf = [];

    // Initialize limb buffer
    final limbs = LimbBuffer(c);

    final BigInt width = BigInt.one << window; // 2^window
    final BigInt windowMask = width - BigInt.one;

    int pos = 0;
    BigInt carry = BigInt.zero;

    while (pos < bitLen) {
      final int u64Idx = pos ~/ 64;
      final int bitIdx = pos % 64;

      final (curU64, nextU64) = limbs.get(u64Idx);

      // Extract window bits
      BigInt bitBuf;
      if (bitIdx + window < 64) {
        bitBuf = (curU64 >> bitIdx).toU64;
      } else {
        bitBuf = ((curU64 >> bitIdx).toU64 | (nextU64 << (64 - bitIdx))).toU64;
      }

      final windowVal = carry + (bitBuf & windowMask);

      if ((windowVal & BigInt.one) == BigInt.zero) {
        // Even → output zero, carry stays same
        wnaf.add(0);
        pos += 1;
      } else {
        // Odd → compute signed digit
        if (windowVal < width ~/ BigInt.two) {
          carry = BigInt.zero;
          wnaf.add(windowVal.toInt());
        } else {
          carry = BigInt.one;
          wnaf.add((windowVal - width).toInt());
        }

        // Fill next window-1 digits with 0
        for (int i = 0; i < window - 1; i++) {
          wnaf.add(0);
        }

        pos += window;
      }
    }
    return wnaf;
  }

  static G wnafExp<
    SCALAR extends CryptoField<SCALAR>,
    G extends CryptoGroupElement<G, SCALAR>
  >(List<G> table, List<int> wnaf, G identity) {
    G result = identity;

    bool foundOne = false;

    // Iterate in reverse over wnaf
    for (final n in wnaf.reversed) {
      if (foundOne) {
        result = result.double();
      }

      if (n != 0) {
        foundOne = true;

        if (n > 0) {
          result = result + table[(n ~/ 2)];
        } else {
          result = result - table[(-n) ~/ 2];
        }
      }
    }

    return result;
  }

  static List<G> wnafTable<
    SCALAR extends CryptoField<SCALAR>,
    G extends CryptoGroupElement<G, SCALAR>
  >(G base, int window) {
    final List<G> table = [];
    final int size = 1 << (window - 1); // 2^(w-1)

    final G dbl = base.double();

    for (int i = 0; i < size; i++) {
      table.add(base);
      base = base + dbl; // base.addAssign(dbl) equivalent
    }
    return table;
  }
}

class LimbBuffer {
  List<int> buf;
  int curIdx = 0;
  BigInt curLimb = BigInt.zero;
  BigInt nextLimb = BigInt.zero;

  LimbBuffer(List<int> buffer) : buf = buffer.clone() {
    // Initialize limb buffers
    incrementLimb();
    incrementLimb();
    curIdx = 0;
  }

  void incrementLimb() {
    curIdx += 1;
    curLimb = nextLimb;

    if (buf.isEmpty) {
      // No more bytes → zero-extend
      nextLimb = BigInt.zero;
    } else if (buf.length <= 7) {
      // Fewer than 8 bytes → zero-extend
      final padded = List<int>.filled(8, 0);
      for (int i = 0; i < buf.length; i++) {
        padded[i] = buf[i];
      }
      nextLimb = BigintUtils.fromBytes(padded, byteOrder: Endian.little);
      buf = const [];
    } else {
      // At least 8 bytes → read next u64
      final next = buf.sublist(0, 8);
      nextLimb = BigintUtils.fromBytes(next, byteOrder: Endian.little);
      buf = buf.sublist(8);
    }
  }

  /// Returns (curLimb, nextLimb). Only valid if idx is curIdx or curIdx+1.
  (BigInt, BigInt) get(int idx) {
    assert(idx == curIdx || idx == curIdx + 1);
    if (idx > curIdx) {
      incrementLimb();
    }
    return (curLimb, nextLimb);
  }
}

class WnafBase<
  SCALAR extends CryptoPrimeFieldElement<SCALAR>,
  G extends CryptoGroupElement<G, SCALAR>
> {
  final G base;
  final List<G> table;
  final int windowSize;
  WnafBase._({
    required this.base,
    required List<G> table,
    required this.windowSize,
  }) : table = table.immutable;
  factory WnafBase(G base, {int windowSize = 4}) {
    final table = WnafUtils.wnafTable<SCALAR, G>(base, windowSize);
    return WnafBase._(base: base, table: table, windowSize: windowSize);
  }

  G mult(SCALAR scalar) {
    final sc = WnafUtils.wnafForm(scalar.toBytes(), windowSize);
    return WnafUtils.wnafExp<SCALAR, G>(table, sc, base.identity());
  }

  G operator *(WnafScalar<SCALAR, G> scalar) {
    return WnafUtils.wnafExp<SCALAR, G>(table, scalar._scalar, base.identity());
  }
}

class WnafScalar<
  SCALAR extends CryptoPrimeFieldElement<SCALAR>,
  G extends CryptoGroupElement<G, SCALAR>
> {
  final List<int> _scalar;
  final SCALAR scalar;
  final int windowSize;
  WnafScalar._({
    required List<int> wScalar,
    required this.scalar,
    required this.windowSize,
  }) : _scalar = wScalar.immutable;
  factory WnafScalar(SCALAR scalar, {int windowSize = 4}) {
    final wScalar = WnafUtils.wnafForm(scalar.toBytes(), windowSize);
    return WnafScalar._(
      wScalar: wScalar,
      scalar: scalar,
      windowSize: windowSize,
    );
  }
  G mult(G base) {
    final table = WnafUtils.wnafTable<SCALAR, G>(base, windowSize);
    return WnafUtils.wnafExp<SCALAR, G>(table, _scalar, base.identity());
  }

  G operator *(WnafBase<SCALAR, G> base) {
    return WnafUtils.wnafExp<SCALAR, G>(
      base.table,
      _scalar,
      base.base.identity(),
    );
  }
}
