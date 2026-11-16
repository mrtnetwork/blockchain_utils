import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/field.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/ntt.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/params.dart';

/// Polynomial and polynomial-vector/matrix operations for ML-DSA.
class PolyUtils {
  static BuBytes _xofDigest(BuSerializableHash hash, int length) {
    final data = BuBytes.fill(length);
    hash.finish(data);
    return data;
  }

  /// Sample a polynomial with coefficients in {-η … η} (Algorithm 31 / RejBoundedPoly).
  static Poly sampleBounded(List<int> seed, int eta) {
    return QuickCrypto.shake256((xof) {
      final p = Poly();
      xof.update(seed);
      var idx = 0;
      final stream = <int>[];

      while (idx < MLDSAParams.n) {
        if (stream.isEmpty) {
          stream.addAll(_xofDigest(xof, 136));
        }
        final byte = stream.removeAt(0);

        if (eta == 2) {
          // FIPS 204 Algorithm 15: CoeffFromHalfByte for η=2
          // Correct mapping: 2 - (b mod 5)  →  {-2,-1,0,1,2}
          for (var shift = 0; shift < 8 && idx < MLDSAParams.n; shift += 4) {
            final b = (byte >> shift) & 0x0f;
            if (b < 15) {
              p.coeffs[idx++] = 2 - (b % 5);
            }
          }
        } else {
          // η == 4
          for (var shift = 0; shift < 8 && idx < MLDSAParams.n; shift += 4) {
            final b = (byte >> shift) & 0x0f;
            if (b < 9) {
              p.coeffs[idx++] = 4 - b;
            }
          }
        }
      }
      return p;
    });
  }

  /// Sample polynomial uniformly from R_q (Algorithm 30 – RejNTTPoly).
  static Poly sampleUniform(List<int> seed) {
    return QuickCrypto.shake128((xof) {
      final p = Poly();
      xof.update(seed);

      var idx = 0;

      while (idx < 256) {
        final b = _xofDigest(xof, 3);

        final t = (b[0] | (b[1] << 8) | (b[2] << 16)) & 0x7FFFFF;

        if (t < 8380417) {
          p.coeffs[idx++] = t;
        }
      }
      return p;
    });
  }

  /// Expand matrix Â from ρ (Algorithm 32). Returns k×ℓ matrix already in NTT.
  static PolyMat expandA(List<int> rho, int k, int l) {
    final mat = PolyMat(k, l);
    for (var i = 0; i < k; i++) {
      for (var j = 0; j < l; j++) {
        final seed = [...rho, j & 0xff, i & 0xff];
        mat.rows[i].polys[j] = sampleUniform(seed);
      }
    }
    return mat;
  }

  /// Expand secret vectors s₁ (ℓ), s₂ (k) from ρ′ (Algorithm 33).
  static (PolyVec, PolyVec) expandS(List<int> rhoPrime, int k, int l, int eta) {
    final s1 = PolyVec(l);
    final s2 = PolyVec(k);
    var nonce = 0;
    rhoPrime.exc(
      length: 64,
      operation: "expandS",
      reason: "Invalid rhoPrime bytes length.",
    );
    for (var i = 0; i < l; i++) {
      final seed = [...rhoPrime, nonce & 0xff, (nonce >> 8) & 0xff];
      s1.polys[i] = sampleBounded(seed, eta);
      nonce++;
    }
    for (var i = 0; i < k; i++) {
      final seed = [...rhoPrime, nonce & 0xff, (nonce >> 8) & 0xff];
      s2.polys[i] = sampleBounded(seed, eta);
      nonce++;
    }
    return (s1, s2);
  }

  /// Expand masking vector y from ρ″ and κ (Algorithm 34).
  static PolyVec expandMask(
    List<int> rhoDoublePrime,
    int kappa,
    int l,
    int gamma1,
  ) {
    final y = PolyVec(l);
    rhoDoublePrime.exc(
      length: 64,
      operation: "expandMask",
      reason: "Invalid rhoDoublePrime bytes length.",
    );
    for (var i = 0; i < l; i++) {
      final nonce = kappa + i;
      final seed = [...rhoDoublePrime, nonce & 0xff, (nonce >> 8) & 0xff];
      y.polys[i] = _sampleMaskN(seed, gamma1);
    }
    return y;
  }

  static Poly _sampleMaskN(List<int> seed, int gamma1) {
    return QuickCrypto.shake256((xof) {
      final p = Poly();
      xof.update(seed);
      final bits = gamma1 == (1 << 17) ? 18 : 20;
      final bytesNeeded = (MLDSAParams.n * bits + 7) ~/ 8;
      final buf = _xofDigest(xof, bytesNeeded);
      var bitPos = 0;
      for (var i = 0; i < MLDSAParams.n; i++) {
        var t = 0;
        for (var b = 0; b < bits; b++) {
          if (((buf[bitPos >> 3] >> (bitPos & 7)) & 1) == 1) {
            t = t | (1 << b);
          }
          bitPos++;
        }
        // coefficients in [-(γ₁-1), γ₁]
        p.coeffs[i] = gamma1 - t;
      }
      return p;
    });
  }

  static Poly sampleInBall(List<int> seed, int tau) {
    return QuickCrypto.shake256((xof) {
      final p = Poly();
      xof.update(seed);

      final signs = _xofDigest(xof, 8);

      final stream = <int>[];

      for (var i = MLDSAParams.n - tau; i < MLDSAParams.n; i++) {
        int j;

        do {
          if (stream.isEmpty) {
            stream.addAll(_xofDigest(xof, 136));
          }

          j = stream.removeAt(0);
        } while (j > i);

        p.coeffs[i] = p.coeffs[j];

        final signIndex = i - (MLDSAParams.n - tau);

        final signBit = (signs[signIndex >> 3] >> (signIndex & 7)) & 1;

        p.coeffs[j] = 1 - 2 * signBit;
      }

      return p;
    });
  }
}

/// A degree-255 polynomial over Z_q. Coefficients stored in [0, q).
class Poly {
  final List<int> coeffs;

  Poly([List<int>? coeffs])
    : coeffs = coeffs?.clone() ?? List<int>.filled(MLDSAParams.n, 0) {
    assert(this.coeffs.length == MLDSAParams.n);
  }

  Poly copy() => Poly(coeffs);

  void zero() {
    for (var i = 0; i < coeffs.length; i++) {
      coeffs[i] = 0;
    }
  }

  void add(Poly other) {
    for (var i = 0; i < coeffs.length; i++) {
      coeffs[i] = MLDSAOperator.fieldAdd(coeffs[i], other.coeffs[i]);
    }
  }

  void sub(Poly other) {
    for (var i = 0; i < coeffs.length; i++) {
      coeffs[i] = MLDSAOperator.fieldSub(coeffs[i], other.coeffs[i]);
    }
  }

  void toNtt() => MLDSANtt.ntt(coeffs);

  void fromNtt() => MLDSANtt.invNtt(coeffs);

  /// Pointwise product in NTT domain (this *= other).
  void pointwiseMul(Poly other) => MLDSANtt.multiplyNtt(coeffs, other.coeffs);

  /// Reduce all coefficients mod q into [0, q).
  void reduce() {
    for (var i = 0; i < coeffs.length; i++) {
      coeffs[i] = MLDSAOperator.fieldReduce(coeffs[i]);
    }
  }

  /// Freeze coefficients into [0, q).
  void freeze() {
    for (var i = 0; i < coeffs.length; i++) {
      coeffs[i] = MLDSAOperator.fieldFreeze(coeffs[i]);
    }
  }

  /// Check infinity norm bound (centered).
  bool checkNorm(int bound) {
    for (final c in coeffs) {
      final t = MLDSAOperator.fieldCenter(c).abs();
      if (t >= bound) return false;
    }
    return true;
  }
}

/// Vector of [k] polynomials.
class PolyVec {
  final List<Poly> polys;
  final int k;

  PolyVec(this.k) : polys = List.generate(k, (_) => Poly());

  PolyVec.from(List<Poly> list) : k = list.length, polys = list;

  PolyVec copy() => PolyVec.from(polys.map((p) => p.copy()).toList());

  void zero() {
    for (final p in polys) {
      p.zero();
    }
  }

  void add(PolyVec other) {
    for (var i = 0; i < k; i++) {
      polys[i].add(other.polys[i]);
    }
  }

  void sub(PolyVec other) {
    for (var i = 0; i < k; i++) {
      polys[i].sub(other.polys[i]);
    }
  }

  void toNtt() {
    for (final p in polys) {
      p.toNtt();
    }
  }

  void fromNtt() {
    for (final p in polys) {
      p.fromNtt();
    }
  }

  void reduce() {
    for (final p in polys) {
      p.reduce();
    }
  }

  bool checkNorm(int bound) {
    for (final p in polys) {
      if (!p.checkNorm(bound)) return false;
    }
    return true;
  }
}

/// Matrix of k rows × l columns of polynomials (stored row-wise).
class PolyMat {
  final List<PolyVec> rows;
  final int k;
  final int l;

  PolyMat(this.k, this.l) : rows = List.generate(k, (_) => PolyVec(l));

  /// Compute Â · ŝ (NTT domain) into [out] (also NTT domain).
  void mulVecNtt(PolyVec out, PolyVec s) {
    assert(out.k == k && s.k == l);
    for (var i = 0; i < k; i++) {
      out.polys[i].zero();
      for (var j = 0; j < l; j++) {
        final tmp = rows[i].polys[j].copy();
        tmp.pointwiseMul(s.polys[j]);
        out.polys[i].add(tmp);
      }
    }
  }
}
