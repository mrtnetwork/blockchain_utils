//
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

class PastaSqrtTables<F extends PastaFieldElement<F>> {
  final List<F> g0;
  final List<F> g1;
  final List<F> g2;
  final List<F> g3;
  final List<int> inv;
  final F rootOfUnity;
  final int hashXor;
  final int hashMod;
  PastaSqrtTables._({
    required List<F> g0,
    required List<F> g1,
    required List<F> g2,
    required List<F> g3,
    required List<int> inv,
    required this.rootOfUnity,
    required this.hashXor,
    required this.hashMod,
  }) : g0 = g0.exc(length: 256, operation: "PastaSqrtTables").immutable,
       g1 = g1.exc(length: 256, operation: "PastaSqrtTables").immutable,
       g2 = g2.exc(length: 256, operation: "PastaSqrtTables").immutable,
       g3 = g3.exc(length: 129, operation: "PastaSqrtTables").immutable,
       inv = inv.immutable;
  int getHash(F x) {
    final lower32 = x.getLower32();
    final hashed = (lower32 ^ hashXor);
    return hashed % hashMod;
  }

  factory PastaSqrtTables({
    required int hashXor,
    required int hashMod,
    required F rootOfUnity,
    required F one,
  }) {
    int getHash(F x) {
      final lower32 = x.getLower32(); // returns int (0..2^32-1)
      final hashed = (lower32 ^ hashXor); // xor salt
      return hashed % hashMod; // mod table size
    }

    F gi = rootOfUnity;

    List<List<F>> gtab = [];

    for (int k = 0; k < 4; k++) {
      // Compute the 256-element table for this level.
      List<F> table = [];
      F acc = one;

      for (int i = 0; i < 256; i++) {
        table.add(acc);
        acc = acc * gi;
      }

      // Update gi = table[255] * gi
      gi = table[255] * gi;

      gtab.add(table);
    }

    List<F> gtab0 = gtab[0];
    List<F> gtab1 = gtab[1];
    List<F> gtab2 = gtab[2];
    List<F> gtab3 = gtab[3];

    //
    // Build inverse table for g3
    //
    List<int> inv = List.filled(hashMod, 1);

    for (int j = 0; j < gtab3.length; j++) {
      int hash = getHash(gtab3[j]);

      if (inv[hash] != 1) {
        throw CryptoException.failed(
          "PastaSqrtTables",
          reason: "hash collision in sqrt table",
        );
      }

      inv[hash] = (256 - j) & 0xFF;
    }
    gtab3 = gtab3.sublist(0, 129);
    return PastaSqrtTables<F>._(
      inv: inv,
      rootOfUnity: rootOfUnity,
      hashMod: hashMod,
      hashXor: hashXor,
      g0: gtab0,
      g1: gtab1,
      g2: gtab2,
      g3: gtab3,
    );
  }

  F sqrtCommon(F uv, F v) {
    // Helper: repeat squaring
    F sqr(F x, int i) {
      F result = x;
      for (int j = 0; j < i; j++) {
        result = result.square();
      }
      return result;
    }

    // Helper: perfect-hash inverse lookup
    int inv(F x) {
      return this.inv[getHash(x)];
    }

    final x3 = uv * v;
    final x2 = sqr(x3, 8);
    final x1 = sqr(x2, 8);
    final x0 = sqr(x1, 8);

    // i = 0, 1
    int t = inv(x0); // t >> 16
    assert(t < 0x100);
    F alpha = x1 * g2[t];
    // i = 2
    t += inv(alpha) << 8; // t >> 8
    assert(t < 0x10000);
    alpha = x2 * g1[t & 0xFF] * g2[t >> 8];
    // i = 3
    t += inv(alpha) << 16; // t
    assert(t < 0x1000000);
    alpha = x3 * g0[t & 0xFF] * g1[(t >> 8) & 0xFF] * g2[t >> 16];
    t += inv(alpha) << 24; // t << 1
    t = ((t + 1) >> 1); // final t
    assert(t <= 0x80000000);

    return uv *
        g0[t & 0xFF] *
        g1[(t >> 8) & 0xFF] *
        g2[(t >> 16) & 0xFF] *
        g3[t >> 24];
  }

  /// Returns (isSquare, sqrtValue)
  FieldSqrtResult<F> sqrtAlt(F u) {
    final v = u.powByTMinus1Over2();
    final uv = u * v;
    final res = sqrtCommon(uv, v);
    final sq = res.square();
    final isSquare = (sq - u).isZero();
    final isNonSquare = (sq - rootOfUnity * u).isZero();
    // Sanity check (optional, only for debug)
    assert(u.isZero() || (isSquare ^ isNonSquare));
    return FieldSqrtResult(res, isSquare);
  }

  FieldSqrtResult<F> sqrtRatio(F num, F div) {
    // Helper for repeated squaring
    F sqr(F x, int i) {
      var res = x;
      for (var j = 0; j < i; j++) {
        res = res.square();
      }
      return res;
    }

    // s = div^(2^S - 1) using an addition chain
    F s = div;
    for (var i = 0; i < 5; i++) {
      s = sqr(s, 1 << i) * s;
    }

    // t = div^(2^(S+1) - 1)
    final t = s.square() * div;

    // w = (num * t)^((T-1)/2) * s
    final w = (t * num).powByTMinus1Over2() * s;

    // v = u^((T-1)/2)
    final v = w * div;

    // uv = u * v
    final uv = w * num;

    // Compute sqrt_common
    final res = sqrtCommon(uv, v);

    // Check square vs nonsquare
    final sqdiv = res.square() * div;
    final isSquare = (sqdiv - num).isZero();
    final isNonSquare = (sqdiv - rootOfUnity * num).isZero();

    assert(num.isZero() || div.isZero() || (isSquare ^ isNonSquare));

    return FieldSqrtResult(res, isSquare);
  }
}
