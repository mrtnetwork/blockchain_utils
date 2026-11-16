import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/ml_dsa.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/encode.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/field.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/poly.dart';

/// Result of key generation.
class MLDSAKeyPair with SecretState {
  final BuBytes publicKey;
  final SecretBytes secretKey;
  final BuBytes? seed;

  MLDSAKeyPair({
    required List<int> publicKey,
    required this.secretKey,
    List<int>? seed,
  }) : publicKey = publicKey.asImmutableBytes,
       seed = seed?.asImmutableBytes;

  @override
  void dispose() {
    secretKey.zero();
    seed?.forceZero();
  }
}

/// ML-DSA instance for a given parameter set.
class MLDSA {
  final MLDSAParams params;

  const MLDSA(this.params);

  /// Pre-instantiated parameter sets.
  static const mldsa44 = MLDSA(MLDSAParams.mldsa44Params);
  static const mldsa65 = MLDSA(MLDSAParams.mldsa65Params);
  static const mldsa87 = MLDSA(MLDSAParams.mldsa87Params);

  /// Generate a key pair.
  /// [seed] must be 32 bytes (ξ) or null for random. The pair copies [seed];
  /// a caller-supplied seed buffer is retained by the caller (wipe after use).
  MLDSAKeyPair keygen([List<int>? seed]) {
    final ownSeed = seed == null;
    seed ??= QuickCrypto.generateRandom(length: params.keygenSeedBytes);
    if (seed.length != params.keygenSeedBytes) {
      throw CoreErrors.invalidOperationArguments(
        "keygen",
        reason: "Invalid seed bytes length.",
      );
    }
    final (pk, sk) = _keygen(seed.asImmutableBytes);
    try {
      return MLDSAKeyPair(
        publicKey: pk,
        secretKey: SecretBytes.take(sk),
        seed: seed,
      );
    } finally {
      if (ownSeed) {
        BinaryOps.tryZero(seed);
      }
    }
  }

  /// Sign a message (hedged by default).
  /// Pass 32 zero bytes as [rnd] for deterministic signing (useful for KATs).
  BuBytes sign(
    List<int> sk,
    List<int> message, {
    List<int>? rnd,
    List<int> context = const [],
  }) {
    if (sk.length != params.secretKeyBytes) {
      throw CoreErrors.invalidOperationArguments(
        "sign",
        reason: "Invalid secret key bytes length.",
      );
    }
    rnd ??= QuickCrypto.generateRandom(length: 32);
    if (rnd.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "sign",
        reason: "Invalid random bytes length.",
      );
    }
    if (context.length > 255) {
      throw CoreErrors.invalidOperationArguments(
        "sign",
        reason: "Invalid context bytes length.",
      );
    }
    return _sign(
      sk,
      [0, context.length, ...context, ...message].asImmutableBytes,
      rnd,
    );
  }

  List<int> signExternal(List<int> sk, List<int> message, {List<int>? rnd}) {
    if (sk.length != params.secretKeyBytes) {
      throw CoreErrors.invalidOperationArguments(
        "sign",
        reason: "Invalid secret key bytes length.",
      );
    }
    rnd ??= QuickCrypto.generateRandom(length: 32);
    if (rnd.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "sign",
        reason: "Invalid random bytes length.",
      );
    }
    if (message.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        "signExternal",
        reason: "Invalid message bytes length.",
      );
    }
    return _sign(sk, message.asImmutableBytes, rnd, external: true);
  }

  /// Verify a signature. Returns true if valid.
  bool verify(
    List<int> pk,
    List<int> message,
    List<int> signature, {
    List<int> context = const [],
  }) {
    if (pk.length != params.publicKeyBytes) return false;
    if (signature.length != params.signatureBytes) return false;
    if (context.length > 255) {
      throw CoreErrors.invalidOperationArguments(
        "verify",
        reason: "Invalid context bytes length.",
      );
    }
    return _verify(
      pk,
      [0, context.length, ...context, ...message].asImmutableBytes,
      signature.asImmutableBytes,
    );
  }

  /// Verify a signature. Returns true if valid.
  bool verifyExternal(List<int> pk, List<int> message, List<int> signature) {
    if (pk.length != params.publicKeyBytes) return false;
    if (signature.length != params.signatureBytes) return false;
    if (message.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        "verify",
        reason: "Invalid message bytes length.",
      );
    }
    return _verify(
      pk,
      message.asImmutableBytes,
      signature.asImmutableBytes,
      external: true,
    );
  }

  BuBytes publicKeyFromSecretKey(List<int> sk) {
    if (sk.length != params.secretKeyBytes) {
      throw CoreErrors.invalidOperationArguments(
        "sign",
        reason: "Invalid secret key bytes length.",
      );
    }
    final k = params.k;
    final l = params.l;
    final eta = params.eta;

    // ---- Decode SK ----

    final rho = sk.sublist(0, 32);

    var off = 128; // skip rho + K + tr

    final etaBits = eta == 2 ? 3 : 4;
    final etaBytes = (MLDSAParams.n * etaBits) ~/ 8;

    final t0Bytes = 416;

    final s1 = PolyVec(l);

    for (var i = 0; i < l; i++) {
      s1.polys[i] = MLDSAEncoding.bitUnpack(
        sk.sublist(off, off + etaBytes),
        eta,
        eta,
      );
      off += etaBytes;
    }

    final s2 = PolyVec(k);

    for (var i = 0; i < k; i++) {
      s2.polys[i] = MLDSAEncoding.bitUnpack(
        sk.sublist(off, off + etaBytes),
        eta,
        eta,
      );
      off += etaBytes;
    }

    // skip t0
    off += k * t0Bytes;

    // ---- Recompute t ----

    final aHat = PolyUtils.expandA(rho, k, l);

    final s1Ntt = s1.copy()..toNtt();

    final t = PolyVec(k);

    aHat.mulVecNtt(t, s1Ntt);

    t.fromNtt();

    t.add(s2);
    t.reduce();

    // ---- Power2Round ----

    final t1 = PolyVec(k);

    for (var i = 0; i < k; i++) {
      for (var j = 0; j < MLDSAParams.n; j++) {
        final (r1, _) = MLDSAEncoding.power2Round(t.polys[i].coeffs[j]);

        t1.polys[i].coeffs[j] = r1;
      }
    }

    return MLDSAEncoding.pkEncode(rho, t1);
  }

  // ------------------------------------------------------------------
  // Key generation (FIPS 204 Algorithm 6)
  // ------------------------------------------------------------------

  (BuBytes, BuBytes) _keygen(List<int> seed) {
    final k = params.k;
    final l = params.l;
    final eta = params.eta;
    final xi = [...seed, k & BinaryOps.mask8, l & BinaryOps.mask8];

    // (ρ, ρ′, K) ← H(ξ)
    final hOut = QuickCrypto.shake256Hash(xi, 128);
    final rho = hOut.sublist(0, 32);
    final rhoPrime = hOut.sublist(32, 96);
    final K = hOut.sublist(96, 128);
    // Expand Â ∈ R_q^{k×ℓ}, s₁ ∈ S_η^ℓ, s₂ ∈ S_η^k
    final aHat = PolyUtils.expandA(rho, k, l);

    final (s1, s2) = PolyUtils.expandS(rhoPrime, k, l, eta);
    // // after expandS

    final s1Ntt = s1.copy();
    s1Ntt.toNtt();
    final t = PolyVec(k);
    aHat.mulVecNtt(t, s1Ntt);
    t.fromNtt();
    t.add(s2);
    t.reduce();
    // (t₁, t₀) = Power2Round(t)
    final t1 = PolyVec(k);
    final t0 = PolyVec(k);
    for (var i = 0; i < k; i++) {
      for (var j = 0; j < MLDSAParams.n; j++) {
        final (r1, r0) = MLDSAEncoding.power2Round(t.polys[i].coeffs[j]);
        t1.polys[i].coeffs[j] = r1;
        t0.polys[i].coeffs[j] = r0;
      }
    }

    final pk = MLDSAEncoding.pkEncode(rho, t1);

    final tr = QuickCrypto.shake256Hash(pk, 64);

    // Note: s1 is still in ordinary domain for packing
    final sk = MLDSAEncoding.skEncode(rho, K, tr, s1, s2, t0, eta);
    return (pk, sk);
  }

  BuBytes _sign(
    List<int> sk,
    List<int> message,
    List<int> rnd, {
    bool external = false,
  }) {
    final k = params.k;
    final l = params.l;
    final eta = params.eta;
    final gamma1 = params.gamma1;
    final gamma2 = params.gamma2;
    final beta = params.beta;
    final tau = params.tau;
    final omega = params.omega;
    final lambda = params.lambda;

    // ---- Decode secret key ----
    final rho = sk.sublist(0, 32).asImmutableBytes;
    final K = sk.sublist(32, 64).asImmutableBytes;
    final tr = sk.sublist(64, 128).asImmutableBytes;

    // Unpack s1, s2, t0 from the packed secret key
    final etaBits = eta == 2 ? 3 : 4;
    final etaBytes = (MLDSAParams.n * etaBits) ~/ 8;
    final t0Bytes = 416;
    var off = 128;
    final s1 = PolyVec(l);
    for (var i = 0; i < l; i++) {
      s1.polys[i] = MLDSAEncoding.bitUnpack(
        sk.sublist(off, off + etaBytes),
        eta,
        eta,
      );
      off += etaBytes;
    }
    final s2 = PolyVec(k);
    for (var i = 0; i < k; i++) {
      s2.polys[i] = MLDSAEncoding.bitUnpack(
        sk.sublist(off, off + etaBytes),
        eta,
        eta,
      );
      off += etaBytes;
    }
    final t0 = PolyVec(k);
    for (var i = 0; i < k; i++) {
      t0.polys[i] = MLDSAEncoding.bitUnpack(
        sk.sublist(off, off + t0Bytes),
        1 << 12,
        1 << 12,
      );
      off += t0Bytes;
    }

    // μ = H(tr || M)
    final mu = switch (external) {
      false => QuickCrypto.shake256Hash([...tr, ...message], 64),
      true => message,
    };

    // ρ″ = H(K || rnd || μ)
    final rhoDp = QuickCrypto.shake256Hash([...K, ...rnd, ...mu], 64);

    final aHat = PolyUtils.expandA(rho, k, l);
    final s1Ntt = s1.copy()..toNtt();
    final s2Ntt = s2.copy()..toNtt();
    final t0Ntt = t0.copy()..toNtt();

    var kappa = 0;
    // FIPS 204 Alg 7: unbounded rejection loop; `kappa` advances by `l`
    // per attempt. Never cap: retry until all norm / hint checks pass.
    while (true) {
      // y ← ExpandMask(ρ″, κ)
      final y = PolyUtils.expandMask(rhoDp, kappa, l, gamma1);
      kappa += l;

      // w = A·y
      final yNtt = y.copy()..toNtt();
      final w = PolyVec(k);
      aHat.mulVecNtt(w, yNtt);
      w.fromNtt();
      w.reduce();

      // w₁ = HighBits(w)
      final w1 = PolyVec(k);
      for (var i = 0; i < k; i++) {
        for (var j = 0; j < MLDSAParams.n; j++) {
          w1.polys[i].coeffs[j] = MLDSAEncoding.highBits(
            w.polys[i].coeffs[j],
            gamma2,
          );
        }
      }

      // ĉ = H(μ || w₁Encode(w₁))
      final w1Enc = _w1Encode(w1, gamma2);

      final cTilde = QuickCrypto.shake256Hash([...mu, ...w1Enc], lambda ~/ 4);
      // c ← SampleInBall(ĉ)
      final c = PolyUtils.sampleInBall(cTilde, tau);
      final cNtt = c.copy()..toNtt();

      // z = y + c·s₁
      final cs1 = PolyVec(l);
      for (var i = 0; i < l; i++) {
        cs1.polys[i] = cNtt.copy();
        cs1.polys[i].pointwiseMul(s1Ntt.polys[i]);
      }
      cs1.fromNtt();
      final z = y.copy();
      z.add(cs1);
      z.reduce();

      // Rejection: ||z||∞ ≥ γ₁ − β
      if (!z.checkNorm(gamma1 - beta)) continue;
      final cs2 = PolyVec(k);
      for (var i = 0; i < k; i++) {
        cs2.polys[i] = cNtt.copy();
        cs2.polys[i].pointwiseMul(s2Ntt.polys[i]);
      }

      cs2.fromNtt();
      final wMinusCs2 = w.copy();
      wMinusCs2.sub(cs2);
      wMinusCs2.reduce();
      final r0 = PolyVec(k);
      for (var i = 0; i < k; i++) {
        for (var j = 0; j < MLDSAParams.n; j++) {
          r0.polys[i].coeffs[j] = MLDSAEncoding.lowBits(
            wMinusCs2.polys[i].coeffs[j],
            gamma2,
          );
        }
      }
      if (!r0.checkNorm(gamma2 - beta)) continue;

      final ct0 = PolyVec(k);
      for (var i = 0; i < k; i++) {
        ct0.polys[i] = cNtt.copy();
        ct0.polys[i].pointwiseMul(t0Ntt.polys[i]);
      }
      ct0.fromNtt();
      ct0.reduce();
      if (!ct0.checkNorm(gamma2)) continue;
      final h = List.generate(k, (_) => <int>[]);
      var ones = 0;

      for (var i = 0; i < k; i++) {
        for (var j = 0; j < MLDSAParams.n; j++) {
          // r0 was already computed earlier as LowBits(w − cs2)
          // now form the transformed value that the optimised MakeHint expects
          final zVal = MLDSAOperator.fieldAdd(
            r0.polys[i].coeffs[j],
            ct0.polys[i].coeffs[j],
          );

          // the second argument is HighBits(w)  (or simply 0 – the optimised form only needs the special case)
          final rVal = MLDSAEncoding.highBits(w.polys[i].coeffs[j], gamma2);
          if (MLDSAEncoding.makeHint(zVal, rVal, gamma2) == 1) {
            h[i].add(j);
            ones++;
          }
        }
      }
      if (ones > omega) continue;

      return MLDSAEncoding.sigEncode(cTilde, z, h, gamma1, omega, k);
    }
  }

  bool _verify(
    List<int> pk,
    List<int> message,
    List<int> signature, {
    bool external = false,
  }) {
    final k = params.k;
    final l = params.l;
    final gamma1 = params.gamma1;
    final gamma2 = params.gamma2;
    final beta = params.beta;
    final tau = params.tau;
    final omega = params.omega;
    final lambda = params.lambda;
    final d = params.d;

    // Decode public key
    final (rho, t1) = MLDSAEncoding.pkDecode(pk, k);
    final tr = QuickCrypto.shake256Hash(pk, 64);

    // Decode signature
    final cTildeLen = lambda ~/ 4;
    final zBytes = gamma1 == (1 << 17) ? 576 : 640;
    final cTilde = signature.sublist(0, cTildeLen);
    var off = cTildeLen;
    final z = PolyVec(l);
    for (var i = 0; i < l; i++) {
      z.polys[i] = MLDSAEncoding.bitUnpack(
        signature.sublist(off, off + zBytes),
        gamma1 - 1,
        gamma1,
      );
      off += zBytes;
    }
    // Hint unpack (FIPS 204 Alg 8 strict): cumulative offsets must be
    // non-decreasing and bounded by `omega`; each index must be `< n`,
    // strictly increasing within its polynomial, and trailing
    // `hintRaw[pos..omega]` bytes must be zero (canonical form).
    final hintRaw = signature.sublist(off);
    final h = List.generate(k, (_) => <int>[]);
    var prev = 0;
    for (var i = 0; i < k; i++) {
      final end = hintRaw[omega + i];
      if (end < prev || end > omega) {
        return false;
      }
      for (var j = prev; j < end; j++) {
        final idx = hintRaw[j];
        if (idx >= MLDSAParams.n) {
          return false;
        }
        if (j > prev && idx <= hintRaw[j - 1]) {
          return false;
        }
        h[i].add(idx);
      }
      prev = end;
    }
    for (var j = prev; j < omega; j++) {
      if (hintRaw[j] != 0) {
        return false;
      }
    }

    if (prev > omega) {
      return false;
    }

    // Norm check on z
    if (!z.checkNorm(gamma1 - beta)) {
      return false;
    }
    // μ = H(tr || M)
    final mu = switch (external) {
      false => QuickCrypto.shake256Hash([...tr, ...message], 64),
      true => message,
    };

    // c ← SampleInBall(ĉ)
    final c = PolyUtils.sampleInBall(cTilde, tau);
    final cNtt = c.copy()..toNtt();

    // Â
    final aHat = PolyUtils.expandA(rho, k, l);

    // w′ ≈ A·z − c·t₁·2^d
    final zNtt = z.copy()..toNtt();
    final az = PolyVec(k);
    aHat.mulVecNtt(az, zNtt);
    az.fromNtt();

    final t1Scaled = PolyVec(k);
    for (var i = 0; i < k; i++) {
      for (var j = 0; j < MLDSAParams.n; j++) {
        t1Scaled.polys[i].coeffs[j] = MLDSAOperator.fieldMul(
          t1.polys[i].coeffs[j],
          1 << d,
        );
      }
    }
    t1Scaled.toNtt();
    final ct1 = PolyVec(k);
    for (var i = 0; i < k; i++) {
      ct1.polys[i] = cNtt.copy();
      ct1.polys[i].pointwiseMul(t1Scaled.polys[i]);
    }
    ct1.fromNtt();

    final wApprox = az.copy();
    wApprox.sub(ct1);
    wApprox.reduce();

    // Reconstruct w₁′ with UseHint
    final w1Prime = PolyVec(k);
    for (var i = 0; i < k; i++) {
      final hintSet = h[i].toSet();
      for (var j = 0; j < MLDSAParams.n; j++) {
        final hintBit = hintSet.contains(j) ? 1 : 0;
        w1Prime.polys[i].coeffs[j] = MLDSAEncoding.useHint(
          hintBit,
          wApprox.polys[i].coeffs[j],
          gamma2,
        );
      }
    }

    // ĉ′ = H(μ || w₁Encode(w₁′))
    final w1Enc = _w1Encode(w1Prime, gamma2);
    final cTildePrime = QuickCrypto.shake256Hash([
      ...mu,
      ...w1Enc,
    ], lambda ~/ 4);
    return BytesUtils.bytesEqualConst(cTilde, cTildePrime);
  }

  List<int> _w1Encode(PolyVec w1, int gamma2) {
    final bits = gamma2 == (MLDSAOperator.q - 1) ~/ 88 ? 6 : 4;
    final parts = <int>[];
    for (final p in w1.polys) {
      parts.addAll(MLDSAEncoding.simpleBitPack(p, bits));
    }
    return parts;
  }
}
