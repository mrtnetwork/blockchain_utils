import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/constants/constants.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/g2.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// RFC 9380 hash-to-curve for BLS12-381 G2 (SSWU map + isogeny).
class BlsHashToG2 {
  static BuBytes expandMessageXmd(
    List<int> msg,
    List<int> dst,
    int lenInBytes,
  ) {
    const bInBytes = 32;
    const sInBytes = 64;
    final ell = (lenInBytes + bInBytes - 1) ~/ bInBytes;
    if (ell > 255) {
      throw CoreErrors.cryptoFailed(
        "expandMessageXmd",
        reason: 'expand_message_xmd: ell > 255',
      );
    }

    final dstPrime = [...dst, dst.length];
    final zPad = List<int>.filled(sInBytes, 0);
    final libStr = [(lenInBytes >> 8) & 0xff, lenInBytes & 0xff];

    final b0 = QuickCrypto.sha256Hash([
      ...zPad,
      ...msg,
      ...libStr,
      0x00,
      ...dstPrime,
    ]);
    var bi = QuickCrypto.sha256Hash([...b0, 0x01, ...dstPrime]);
    final out = <int>[...bi];

    for (var i = 2; i <= ell; i++) {
      final t = List<int>.generate(b0.length, (j) => b0[j] ^ bi[j]);
      bi = QuickCrypto.sha256Hash([...t, i, ...dstPrime]);
      out.addAll(bi);
    }
    return BuBytes(out.sublist(0, lenInBytes));
  }

  static List<Bls12Fp2> hashToField(
    List<int> msg,
    List<int> dst, {
    int count = 2,
  }) {
    const L = 64;
    final uniform = expandMessageXmd(msg, dst, count * 2 * L);
    final res = <Bls12Fp2>[];
    for (var i = 0; i < count; i++) {
      final off = i * 2 * L;
      final e0 = Bls12Fp.fromBytes64(uniform.sublist(off, off + L));
      final e1 = Bls12Fp.fromBytes64(uniform.sublist(off + L, off + 2 * L));
      res.add(Bls12Fp2(c0: e0, c1: e1));
    }
    return res;
  }

  static G2Projective mapToCurveSimpleSwu(Bls12Fp2 u) {
    final usq = u.square();
    final xiUsq = BlsG2Constants.sswuXi * usq;
    final xisqU4 = xiUsq.square();
    final nd = xisqU4 + xiUsq;
    final xDen =
        BlsG2Constants.sswuA *
        Bls12Fp2.conditionalSelect(-nd, BlsG2Constants.sswuXi, nd.isZero());
    final x0Num = BlsG2Constants.sswuB * (Bls12Fp2.one + nd);
    final xDenSq = xDen.square();
    final gxDen = xDenSq * xDen;
    final gx0Num =
        (x0Num.square() + BlsG2Constants.sswuA * xDenSq) * x0Num +
        BlsG2Constants.sswuB * gxDen;

    final vSq = gxDen.square();
    final v3 = vSq * gxDen;
    final v4 = vSq.square();
    final uv7 = gx0Num * v3 * v4;
    final uv15 = uv7 * v4.square();

    var sqrtCand = uv7 * uv15.powVarTime(BlsG2Constants.expP2m9div16);

    var y = sqrtCand;

    // candidate 1: i * sqrtCand
    var tmp = Bls12Fp2(c0: -sqrtCand.c1, c1: sqrtCand.c0);
    y = Bls12Fp2.conditionalSelect(y, tmp, (tmp.square() * gxDen) == gx0Num);

    // candidate 2: RV1 * sqrtCand
    tmp = sqrtCand * BlsG2Constants.sswuRv1;
    y = Bls12Fp2.conditionalSelect(y, tmp, (tmp.square() * gxDen) == gx0Num);

    // candidate 3: RV1 * i * sqrtCand
    tmp = Bls12Fp2(c0: tmp.c1, c1: -tmp.c0);
    y = Bls12Fp2.conditionalSelect(y, tmp, (tmp.square() * gxDen) == gx0Num);

    // second branch
    final gx1Num = gx0Num * xiUsq * xisqU4;
    sqrtCand = sqrtCand * usq * u;

    var etaFound = false;
    for (final eta in BlsG2Constants.sswuEtas) {
      tmp = sqrtCand * eta;
      final found = (tmp.square() * gxDen) == gx1Num;
      y = Bls12Fp2.conditionalSelect(y, tmp, found);
      etaFound = etaFound || found;
    }

    final xNum = Bls12Fp2.conditionalSelect(x0Num, x0Num * xiUsq, etaFound);

    final mismatch =
        u.sgn0() !=
        y.sgn0(); // was: u.lexicographicallyLargest() != y.lexicographicallyLargest()
    y = Bls12Fp2.conditionalSelect(y, -y, mismatch);

    return G2Projective(x: xNum, y: y * xDen, z: xDen);
  }

  static G2Projective isoMap(G2Projective p) {
    final x = p.x;
    final y = p.y;
    final z = p.z;

    final zSq = z.square();
    final zCub = zSq * z;
    final zPows = [z, zSq, zCub];

    final coeffs = [
      BlsG2Constants.iso3XNum,
      BlsG2Constants.iso3XDen,
      BlsG2Constants.iso3YNum,
      BlsG2Constants.iso3YDen,
    ];
    final mapVals = List<Bls12Fp2>.filled(4, Bls12Fp2.zero);

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

    return G2Projective(
      x: mapVals[0] * mapVals[3],
      y: mapVals[2] * mapVals[1],
      z: mapVals[1] * mapVals[3],
    );
  }

  /// Hash an arbitrary message to a cofactor-cleared point in G2.
  /// Uses suite BLS12381G2_XMD:SHA-256_SSWU_RO_ (RFC 9380).
  /// Null dst defaults to the IETF BLS signing POP suite
  /// (`BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_`), matching the Rust
  /// `sign_min_pk`/`verify_min_pk` default; pass an explicit DST (e.g.
  /// `BlsG2Constants.defaultBlsDst`, the NUL/basic suite) to override.
  static G2Projective hashToG2(List<int> message, {List<int>? dst}) {
    final d = dst ?? BlsG2Constants.popDst;
    final u = hashToField(message, d, count: 2);
    final mg = mapToCurveSimpleSwu(u[0]);
    final q0 = isoMap(mg);
    final q1 = isoMap(mapToCurveSimpleSwu(u[1]));
    // Add on the real curve, then clear cofactor
    return (q0 + q1).clearCofactor();
  }
}
