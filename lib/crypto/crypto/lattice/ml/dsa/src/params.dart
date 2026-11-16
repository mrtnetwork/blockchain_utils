import 'package:blockchain_utils/exception/exception/core_errors.dart';

/// Parameters for one ML-DSA parameter set.
class MLDSAParams {
  /// ML-DSA-44 (Category 2)
  static const mldsa44Params = MLDSAParams(
    k: 4,
    l: 4,
    eta: 2,
    tau: 39,
    beta: 78,
    gamma1: 1 << 17,
    gamma2: (8380417 - 1) ~/ 88,
    omega: 80,
    d: 13,
    lambda: 128,
    level: 44,
  );

  /// ML-DSA-65 (Category 3) – recommended default
  static const mldsa65Params = MLDSAParams(
    k: 6,
    l: 5,
    eta: 4,
    tau: 49,
    beta: 196,
    gamma1: 1 << 19,
    gamma2: (8380417 - 1) ~/ 32,
    omega: 55,
    d: 13,
    lambda: 192,
    level: 65,
  );

  /// ML-DSA-87 (Category 5)
  static const mldsa87Params = MLDSAParams(
    k: 8,
    l: 7,
    eta: 2,
    tau: 60,
    beta: 120,
    gamma1: 1 << 19,
    gamma2: (8380417 - 1) ~/ 32,
    omega: 75,
    d: 13,
    lambda: 256,
    level: 87,
  );

  /// Module rank for public key (k).
  final int k;

  /// Module rank for secret key / signature (ℓ).
  final int l;

  /// Noise bound η for secret key coefficients.
  final int eta;

  /// Number of ±1 coefficients in the challenge polynomial c.
  final int tau;

  /// Bound β = τ · η.
  final int beta;

  /// Masking range γ₁.
  final int gamma1;

  /// Rounding parameter γ₂.
  final int gamma2;

  /// Maximum number of 1's in the hint h.
  final int omega;

  /// Number of dropped low-order bits (d).
  final int d;

  /// Challenge hash output length in bits (λ).
  final int lambda;

  /// Polynomial degree (always 256).
  static const int n = 256;

  /// Modulus q = 8380417.
  static const int q = 8380417;

  final int level;

  const MLDSAParams({
    required this.k,
    required this.l,
    required this.eta,
    required this.tau,
    required this.beta,
    required this.gamma1,
    required this.gamma2,
    required this.omega,
    required this.d,
    required this.lambda,
    required this.level,
  });

  /// Size of a single polynomial when packed with 10 bits (for t1).
  int get polyT1PackedBytes => 320; // 256 * 10 / 8

  /// Size of a single polynomial when packed with η-bits (for s1/s2).
  int get polyEtaPackedBytes {
    // bitlen(2*eta) = 3 for eta=2, 4 for eta=4
    final bits = eta == 2 ? 3 : 4;
    return (n * bits) ~/ 8;
  }

  /// Size of a single polynomial packed for z (γ₁ bits).
  int get polyZPackedBytes {
    // bitlen(2*gamma1 - 1) ≈ gamma1Bits + 1, but FIPS uses specific packing
    // For γ1 = 2^17 → 576 bytes, γ1 = 2^19 → 640 bytes
    if (gamma1 == (1 << 17)) return 576;
    if (gamma1 == (1 << 19)) return 640;
    throw CoreErrors.cryptoFailed(
      "polyZPackedBytes",
      reason: "Unsupported gamma1",
    );
  }

  /// Size of a single polynomial packed for w1.
  int get polyW1PackedBytes {
    // For γ2 = (q-1)/88 → 192 bytes, γ2 = (q-1)/32 → 128 bytes
    if (gamma2 == (q - 1) ~/ 88) return 192;
    if (gamma2 == (q - 1) ~/ 32) return 128;
    throw CoreErrors.cryptoFailed(
      "polyW1PackedBytes",
      reason: "Unsupported gamma2",
    );
  }

  /// Public key size: ρ (32) + t1 (k * 320)
  int get publicKeyBytes => 32 + k * polyT1PackedBytes;

  /// Secret key size (expanded form used by FIPS):
  /// ρ (32) + K (32) + tr (64) + s1 (l * polyEtaPacked) + s2 (k * polyEtaPacked) + t0 (k * 416)
  int get secretKeyBytes {
    final etaBytes = polyEtaPackedBytes;
    final t0Bytes = 416; // 256 * 13 / 8
    return 32 + 32 + 64 + l * etaBytes + k * etaBytes + k * t0Bytes;
  }

  /// Signature size: c̃ (lambda/4) + z (l * polyZPacked) + h (omega + k)
  int get signatureBytes {
    final cTildeBytes = lambda ~/ 4;
    return cTildeBytes + l * polyZPackedBytes + omega + k;
  }

  /// Seed size for key generation (ξ) = 32 bytes.
  int get keygenSeedBytes => 32;

  /// Randomness size for signing (rnd) = 32 bytes.
  int get signRndBytes => 32;

  static MLDSAParams fromPublicKey(List<int> pkBytes) {
    final length = pkBytes.length;
    return [mldsa44Params, mldsa65Params, mldsa87Params].firstWhere(
      (e) => e.publicKeyBytes == length,
      orElse:
          () =>
              throw CoreErrors.cryptoFailed(
                "MLDSAParams.fromPublicKey",
                reason: "Invalid or unsupported public key bytes length.",
              ),
    );
  }

  static bool isValidPublicKeyBytesLength(List<int> pkBytes) {
    final length = pkBytes.length;
    return [
      mldsa44Params,
      mldsa65Params,
      mldsa87Params,
    ].any((e) => e.publicKeyBytes == length);
  }

  static MLDSAParams fromLevel(int level) {
    const Map<int, MLDSAParams> params = {
      44: MLDSAParams.mldsa44Params,
      65: MLDSAParams.mldsa65Params,
      87: MLDSAParams.mldsa87Params,
    };

    final param = params[level];
    if (param == null) {
      throw CoreErrors.cryptoFailed(
        "MLDSAParams.fromLevel",
        reason: "Unsupported ML-DSA level $level.",
      );
    }
    return param;
  }

  static MLDSAParams fromSecretKey(List<int> skBytes) {
    final length = skBytes.length;
    return [mldsa44Params, mldsa65Params, mldsa87Params].firstWhere(
      (e) => e.secretKeyBytes == length,
      orElse:
          () =>
              throw CoreErrors.cryptoFailed(
                "MLDSAParams.fromPublicKey",
                reason: "Invalid or unsupported public key bytes length.",
              ),
    );
  }
}
