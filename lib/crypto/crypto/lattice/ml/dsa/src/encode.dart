import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/field.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/params.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/poly.dart';

/// Bit-packing/unpacking of ML-DSA keys, signatures, and polynomials
/// (FIPS 204 Algorithms 16-25).
class MLDSAEncoding {
  // const int _q = q;
  static const int _d = 13;

  static (int, int) power2Round(int r) {
    r = MLDSAOperator.fieldReduce(r); // [0, q)
    var r0 = r % (1 << _d); // low 13 bits
    if (r0 > (1 << (_d - 1))) {
      r0 -= (1 << _d); // centre into (-2^12, 2^12]
    }
    final r1 = (r - r0) >> _d;
    return (r1, r0);
  }

  /// Decompose(r) with respect to α = 2·γ2 → (r1, r0).
  static (int, int) decompose(int r, int gamma2) {
    r = MLDSAOperator.fieldReduce(r);
    final alpha = 2 * gamma2;
    var r0 = r % alpha;
    if (r0 > gamma2) r0 -= alpha;
    var r1 = (r - r0) ~/ alpha;
    if (r - r0 == MLDSAOperator.q - 1) {
      r1 = 0;
      r0 = r0 - 1;
    }
    return (r1, r0);
  }

  static int highBits(int r, int gamma2) => decompose(r, gamma2).$1;

  static int lowBits(int r, int gamma2) => decompose(r, gamma2).$2;

  /// MakeHint – optimised form used by the reference implementation / noble / KATs.
  /// This is the version that appears after the sign-side transformation r0 += ct0.
  static int makeHint(int z, int r, int gamma2) {
    // z = the transformed low-bits value, r = HighBits(w)  (or 0 in the special case)
    if (z <= gamma2 ||
        z > MLDSAOperator.q - gamma2 ||
        (z == MLDSAOperator.q - gamma2 && r == 0)) {
      return 0;
    }
    return 1;
  }

  /// UseHint(h, r) – recovers high bits using the hint.
  static int useHint(int h, int r, int gamma2) {
    final (r1, r0) = decompose(r, gamma2);

    if (h == 0) {
      return r1;
    }

    final m = (MLDSAOperator.q - 1) ~/ (2 * gamma2);

    if (r0 > 0) {
      return (r1 + 1) % m;
    } else {
      return (r1 - 1 + m) % m;
    }
  }

  /// Pack polynomial coefficients that lie in [0, 2^b - 1] into bytes.
  static List<int> simpleBitPack(Poly p, int b) {
    final outLen = (MLDSAParams.n * b) ~/ 8;
    final out = List<int>.filled(outLen, 0);
    var bitPos = 0;
    for (var i = 0; i < MLDSAParams.n; i++) {
      final t = p.coeffs[i] & ((1 << b) - 1); // already in [0, 2^b-1]
      for (var j = 0; j < b; j++) {
        if (((t >> j) & 1) == 1) {
          out[bitPos >> 3] |= (1 << (bitPos & 7)) & BinaryOps.mask8;
        }
        bitPos++;
      }
    }
    return out;
  }

  /// Unpack into coefficients in [0, 2^b - 1].
  static Poly simpleBitUnpack(List<int> bytes, int b) {
    final p = Poly();
    var bitPos = 0;
    for (var i = 0; i < MLDSAParams.n; i++) {
      var t = 0;
      for (var j = 0; j < b; j++) {
        if ((bytes[bitPos >> 3] >> (bitPos & 7)) & 1 == 1) {
          t |= 1 << j;
        }
        bitPos++;
      }
      p.coeffs[i] = t;
    }
    return p;
  }

  /// BitPack for coefficients in [-a, b].
  static List<int> bitPack(Poly p, int a, int b, {int? bits}) {
    bits ??= _bitLen(a + b);
    if (a == (1 << 12) && b == (1 << 12)) bits = 13;

    final outLen = (MLDSAParams.n * bits) ~/ 8;
    final out = List<int>.filled(outLen, 0);
    var bitPos = 0;
    for (var i = 0; i < MLDSAParams.n; i++) {
      // force centred representative before mapping
      var c = MLDSAOperator.fieldCenter(p.coeffs[i]);
      var t = b - c;
      if (bits == 13) t &= 0x1fff;
      for (var j = 0; j < bits; j++) {
        if ((t >> j) & 1 == 1) {
          out[bitPos >> 3] |= (1 << (bitPos & 7)) & BinaryOps.mask8;
        }
        bitPos++;
      }
    }
    return out;
  }

  /// skEncode – expanded secret key.
  static BuBytes skEncode(
    List<int> rho,
    List<int> K,
    List<int> tr,
    PolyVec s1,
    PolyVec s2,
    PolyVec t0,
    int eta,
  ) {
    final l = s1.k;
    final k = s2.k;
    final etaBits = eta == 2 ? 3 : 4;
    final etaBytes = (MLDSAParams.n * etaBits) ~/ 8;
    final t0Bytes = 416; // 13 bits
    final out = BuBytes.fill(
      32 + 32 + 64 + l * etaBytes + k * etaBytes + k * t0Bytes,
      0,
    );
    var off = 0;
    out.setRange(off, off + 32, rho);
    off += 32;
    out.setRange(off, off + 32, K);
    off += 32;
    out.setRange(off, off + 64, tr);
    off += 64;
    for (var i = 0; i < l; i++) {
      final packed = bitPack(s1.polys[i], eta, eta);
      out.setRange(off, off + etaBytes, packed);
      off += etaBytes;
    }
    for (var i = 0; i < k; i++) {
      final packed = bitPack(s2.polys[i], eta, eta);
      out.setRange(off, off + etaBytes, packed);
      off += etaBytes;
    }
    for (var i = 0; i < k; i++) {
      final packed = bitPack(
        t0.polys[i],
        1 << 12,
        1 << 12,
        bits: 13,
      ); // [-2^{12}, 2^{12}]
      out.setRange(off, off + t0Bytes, packed);
      off += t0Bytes;
    }
    return out;
  }

  static Poly bitUnpack(List<int> bytes, int a, int b, {int? bits}) {
    bits ??= _bitLen(a + b);
    if (a == (1 << 12) && b == (1 << 12)) bits = 13;

    final p = Poly();
    var bitPos = 0;
    for (var i = 0; i < MLDSAParams.n; i++) {
      var t = 0;
      for (var j = 0; j < bits; j++) {
        if ((bytes[bitPos >> 3] >> (bitPos & 7)) & 1 == 1) {
          t |= 1 << j;
        }
        bitPos++;
      }
      p.coeffs[i] = b - t;
    }
    return p;
  }

  static int _bitLen(int x) {
    if (x <= 0) return 0;
    var n = 0;
    while (x > 0) {
      x >>= 1;
      n++;
    }
    return n;
  }

  /// pkEncode(ρ, t1) – public key encoding.
  static BuBytes pkEncode(List<int> rho, PolyVec t1) {
    final k = t1.k;
    final out = BuBytes.fill(32 + k * 320, 0);
    out.setRange(0, 32, rho);
    var off = 32;
    for (var i = 0; i < k; i++) {
      final packed = simpleBitPack(t1.polys[i], 10);
      out.setRange(off, off + 320, packed);
      off += 320;
    }
    return out;
  }

  static (List<int>, PolyVec) pkDecode(List<int> pk, int k) {
    final rho = pk.sublist(0, 32);
    final t1 = PolyVec(k);
    var off = 32;
    for (var i = 0; i < k; i++) {
      t1.polys[i] = simpleBitUnpack(pk.sublist(off, off + 320), 10);
      off += 320;
    }
    return (rho, t1);
  }

  /// sigEncode(c̃, z, h)
  static BuBytes sigEncode(
    List<int> cTilde,
    PolyVec z,
    List<List<int>> h, // list of positions of 1's per polynomial
    int gamma1,
    int omega,
    int k,
  ) {
    final l = z.k;
    final zBytes = gamma1 == (1 << 17) ? 576 : 640;
    final out = BuBytes.fill(cTilde.length + l * zBytes + omega + k, 0);
    var off = 0;
    out.setRange(off, off + cTilde.length, cTilde);
    off += cTilde.length;
    for (var i = 0; i < l; i++) {
      final packed = bitPack(z.polys[i], gamma1 - 1, gamma1);
      out.setRange(off, off + zBytes, packed);
      off += zBytes;
    }
    final hint = List<int>.filled(omega + k, 0);
    var idx = 0;
    for (var i = 0; i < k; i++) {
      for (final pos in h[i]) {
        hint[idx++] = pos;
        assert(pos < 256);
      }
      assert(idx < 256);
      hint[omega + i] = idx;
    }
    out.setRange(off, off + hint.length, hint);
    return out;
  }
}
