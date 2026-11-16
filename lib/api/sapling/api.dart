import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Sapling Groth16 proving backend interface.
///
/// Packed little-endian witnesses (mirror Rust `ffi::sapling` docs):
/// spend (1288 B): value u64 | randomness | ak | nsk | g_d |
/// commitment_randomness | ar | auth_path[32][32] | pos[32] (bytes 0/1) |
/// anchor; output (168 B): value u64 | randomness | g_d | pk_d |
/// commitment_randomness | esk.
///
/// Parameter handles are opaque backend objects: obtain from
/// [setSpendParams]/[setOutputParams], release with [paramsFree].
abstract interface class SaplingApi {
  /// Circuit kind: Spend.
  static const int spend = 0;

  /// Circuit kind: Output.
  static const int output = 1;

  /// Packed spend witness size.
  static const int spendWitnessLen = 1288;

  /// Packed output witness size.
  static const int outputWitnessLen = 168;

  /// Groth16 proof size.
  static const int proofLen = 192;

  /// Load Spend ceremony parameters.
  Object setSpendParams(List<int> params);

  /// Load Output ceremony parameters.
  Object setOutputParams(List<int> params);

  /// Release a params handle.
  void paramsFree(Object handle);

  /// Prove under [handle]. Returns the 192-byte proof + public inputs.
  BuSaplingProof prove({
    required Object handle,
    required int kind,
    required List<int> witness,
  });

  /// Verify under [handle]. Throws on failure.
  void verify({
    required Object handle,
    required int kind,
    required List<int> proof,
    required List<int> inputs,
  });
}
