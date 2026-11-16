import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/crypto/crypto/monero/api/src/proof.dart';

export 'package:blockchain_utils/crypto/crypto/monero/api/src/proof.dart';

/// Backend interface for Monero RingCT operations (Bulletproofs+) and
/// native batch output scanning (fast unlock).
abstract interface class MoneroApi {
  bool get supported => false;

  /// Batch-verify Bulletproofs+ proofs. Returns `true` iff every proof
  /// is valid; throws on malformed input.
  bool bpPlusVerify(List<MoneroBpPlusProof> proofs);

  /// Prove a Bulletproofs+ for `amounts` (piconero values, each `< 2^64`)
  /// with `gamma` masks (each 32 bytes) and a caller-supplied 32-byte
  /// `seed` driving the prover RNG (deterministic per seed; pass fresh
  /// randomness per proof).
  MoneroBpPlusProof bpPlusProveAmounts({
    required List<BigInt> amounts,
    required List<List<int>> gamma,
    required List<int> seed,
  });

  /// Prove a Bulletproofs+ for raw bit-scalar vectors (`sv`, each 32 bytes
  /// canonical scalars) with `gamma` masks.
  MoneroBpPlusProof bpPlusProveScalars({
    required List<List<int>> sv,
    required List<List<int>> gamma,
    required List<int> seed,
  });

  /// Batch output scan (fast unlock). Ports
  /// `onchain_crypto_c:monero_unlock_outputs_batch_compact`: per
  /// (account, output) derives `D = 8·v·R`, prefilters the view tag, and
  /// recomputes `P = B + Hs(D‖i)·G` for every subaddress spend key.
  ///
  /// Returns matches with derivation + derived key (amount decode and key
  /// images stay caller-side). Native-only: the pure-Dart backend throws
  /// [UnsupportedError] (the Dart scan lives in `monero_dart` itself).
  List<BuMoneroUnlockMatch> unlockBatch({
    required List<BuMoneroScanAccount> accounts,
    required List<BuMoneroScanOutput> outputs,
  });
}
