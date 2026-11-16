import 'package:blockchain_utils/crypto/crypto/group/bls12_381/bls12.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

/// Hash-to-curve for BLS12-381 **G1** (RFC 9380 suite
/// `BLS12381G1_XMD:SHA-256_SSWU_RO_`) — the counterpart to [BlsHashToG2]
/// for min-signature-size BLS ciphersuites (G2 public keys, G1 signatures).
///
/// VERIFICATION: this implementation was ported from a from-scratch Python
/// reference that was checked, step by step, against the compiled
/// `zkcrypto/bls12_381` Rust crate's actual runtime output (not just its
/// source), and then validated end-to-end against all 5 official RFC 9380
/// Appendix J.9.1 test vectors for this exact suite. See
/// [BlsG1Constants] for the full provenance notes and the two real bugs
/// that verification caught (both are called out inline below too).
///
/// The algorithm shape mirrors [BlsHashToG2] exactly (same
/// `expandMessageXmd`/`hashToField`/SSWU-map/isogeny-map/cofactor-clear
/// pipeline structure) — the differences are all field-specific: G1 works
/// over 𝔽ₚ (not 𝔽ₚ²), so the SSWU map's square-root step uses the direct
/// `p ≡ 3 (mod 4)` formula (a single candidate) instead of G2's multi-eta
/// branch search, and cofactor clearing is a scalar multiplication instead
/// of G2's endomorphism-based `clearCofactor()`.
class BlsHashToG1 {
  static List<Bls12Fp> hashToField(
    List<int> message,
    List<int> dst, {
    int count = 2,
  }) {
    const L = 64;
    final uniform = BlsHashToG2.expandMessageXmd(message, dst, count * L);
    final res = <Bls12Fp>[];
    for (var i = 0; i < count; i++) {
      final off = i * L;
      res.add(Bls12Fp.fromBytes64(uniform.sublist(off, off + L)));
    }
    return res;
  }

  static G1Projective mapToCurveSimpleSwu(Bls12Fp u) {
    final usq = u.square();
    final xiUsq = BlsG1Constants.sswuXi * usq;
    final xisqU4 = xiUsq.square();
    final ndCommon = xisqU4 + xiUsq;
    final xDen =
        BlsG1Constants.sswuA *
        (ndCommon.isZero()
            ? BlsG1Constants.sswuXi
            : -ndCommon); // B*(1+nd)==0 handled by the isZero() branch
    final x0Num = BlsG1Constants.sswuB * (Bls12Fp.one + ndCommon);

    final xDenSq = xDen.square();
    final gxDen = xDenSq * xDen;
    final gx0Num =
        (x0Num.square() + BlsG1Constants.sswuA * xDenSq) * x0Num +
        BlsG1Constants.sswuB * gxDen;

    // sqrt candidate via p ≡ 3 (mod 4): candidate = uv * (uv * v^2)^((p-3)/4)
    final uV = gx0Num * gxDen;
    final vSq = gxDen.square();
    final sqrtCandidate = uV * (uV * vSq).pow(BlsG1Constants.expPm3div4Limbs);

    final gx0Square = (sqrtCandidate.square() * gxDen) == gx0Num;

    final x1Num = x0Num * xiUsq;
    // y1 = sqrt(-Z^3) * u^3 * sqrtCandidate  (second-branch candidate)
    final y1 = BlsG1Constants.sqrtMXiCubed * (usq * u) * sqrtCandidate;

    final xNum = gx0Square ? x0Num : x1Num;
    var y = gx0Square ? sqrtCandidate : y1;
    if (y.sgn0() != u.sgn0()) {
      y = -y;
    }

    // NOTE (verified bug fix): the projective Y-coordinate is y * xDen, not
    // the bare y candidate -- confirmed against the reference crate's
    // actual `G1Projective { x: x_num, y: y * x_den, z: x_den }` return.
    return G1Projective(x: xNum, y: y * xDen, z: xDen);
  }

  static G1Projective isoMap(G1Projective p) {
    final x = p.x;
    final y = p.y;
    final z = p.z;

    final zPows = <Bls12Fp>[z];
    for (var i = 1; i < 15; i++) {
      zPows.add(zPows.last * z);
    }

    final coeffs = [
      BlsG1Constants.iso11XNum,
      BlsG1Constants.iso11XDen,
      BlsG1Constants.iso11YNum,
      BlsG1Constants.iso11YDen,
    ];
    final mapVals = List<Bls12Fp>.filled(4, Bls12Fp.zero);

    for (var i = 0; i < 4; i++) {
      final c = coeffs[i];
      final last = c.length - 1;
      mapVals[i] = c[last];
      for (var j = 0; j < last; j++) {
        mapVals[i] = mapVals[i] * x + zPows[j] * c[last - 1 - j];
      }
    }

    mapVals[1] = mapVals[1] * z;
    mapVals[2] = mapVals[2] * y;
    mapVals[3] = mapVals[3] * z;

    return G1Projective(
      x: mapVals[0] * mapVals[3],
      y: mapVals[2] * mapVals[1],
      z: mapVals[1] * mapVals[3],
    );
  }

  /// Cofactor clearing via the optimized scalar `1 + BLS_X` -- see
  /// [BlsG1Constants.cofactorClearingScalar] doc for why this (and not the
  /// literal numeric cofactor) is correct here. Plain double-and-add;
  /// clarity over speed, since this runs once per hash.
  static G1Projective _clearCofactor(G1Projective p) {
    var result = G1Projective.identity;
    var addend = p;
    var k = Bls12PairingUtils.blsX + Uint64.one;
    while (k != Uint64.zero) {
      if ((k & Uint64.one) == Uint64.one) {
        result = result + addend;
      }
      addend = addend + addend;
      k = k >> 1;
    }
    return result;
  }

  /// Hash an arbitrary message to a cofactor-cleared point in G1.
  /// Uses suite BLS12381G1_XMD:SHA-256_SSWU_RO_ (RFC 9380).
  /// Null dst defaults to the IETF BLS signing POP suite
  /// (`BLS_SIG_BLS12381G1_XMD:SHA-256_SSWU_RO_POP_`), matching the Rust
  /// `sign_min_sig`/`verify_min_sig` default; pass an explicit DST (e.g.
  /// `BlsG1Constants.defaultDst`, the NUL/basic suite) to override.
  static G1Projective hashToG1(List<int> message, {List<int>? dst}) {
    dst ??= BlsG1Constants.popDst;

    final u = hashToField(message, dst, count: 2);
    final q0 = isoMap(mapToCurveSimpleSwu(u[0]));
    final q1 = isoMap(mapToCurveSimpleSwu(u[1]));
    return _clearCofactor(q0 + q1);
  }
}
