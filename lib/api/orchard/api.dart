import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Orchard Action proving backend interface (Halo2, Pasta curves).
///
/// One packed circuit per Action (little-endian, 1716 B, field level):
/// path[32][32] | pos u32 | gd_old[64] | pkd_old[64] | v_old u64 |
/// rho_old[32] | psi_old[32] | rcm_old[32] | cm_old[64] | alpha[32] |
/// ak[64] | nk[32] | rivk[32] | gd_new[64] | pkd_new[64] | v_new u64 |
/// psi_new[32] | rcm_new[32] | rcv[32].
/// Instances travel separately (10 x 32 LE limbs per action); `seed` carries
/// 32 fresh blinding-seed bytes per prove call.
///
/// Versions: 0 insecure (pre-NU6.2), 1 fixed (post-NU6.2), 2 NU6.3.
/// `disableCrossAddress` applies ONLY to version 2 and must match the key.
/// Proving keys are opaque backend objects: [pkNew] + [pkFree].
abstract interface class OrchardApi {
  /// Insecure pre-NU6.2 circuit.
  static const int versionInsecure = 0;

  /// Fixed post-NU6.2 circuit.
  static const int versionFixed = 1;

  /// NU6.3 circuit.
  static const int versionNu63 = 2;

  /// Packed size of one circuit.
  static const int packedInputLen = 1716;

  /// Build a proving key for [version].
  Object pkNew({required int version});

  /// Release a proving-key handle.
  void pkFree(Object pk);

  /// Prove N actions (`inputs` = n x [packedInputLen] bytes, `instances` =
  /// n x 10 x 32 bytes, `seed` = 32 fresh blinding-seed bytes).
  BuBytes createProof({
    required Object pk,
    required List<int> inputs,
    required List<int> instances,
    required List<int> seed,
    required int version,
    bool disableCrossAddress = false,
  });

  /// Verify [proof] against n×10×32 instance limbs. Throws on failure.
  void verifyProof({
    required Object pk,
    required List<int> proof,
    required List<int> instances,
    required int version,
    bool disableCrossAddress = false,
  });
}
