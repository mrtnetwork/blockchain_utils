import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/crypto/crypto/solana_zk/twisted_elgamal.dart';

/// High-level Solana ZK API (dalek Bulletproofs + Sigma
/// protocols). Lengths follow the on-chain `zk-elgamal-proof` encodings.
/// Amounts are full-range Dart ints (validated to u64 at the boundary).
abstract interface class SolanaZkApi {
  bool get supported;
  SolanaElGamalPubkey pubkeyFromSecret(List<int> secret);
  SolanaElGamalCiphertext encryptWith({
    required SolanaElGamalPubkey pubkey,
    required BigInt amount,
    required List<int> opening,
  });
  int decryptU32({
    required List<int> secret,
    required SolanaElGamalCiphertext ciphertext,
  });
  SolanaAeCiphertext aeEncrypt({
    required List<int> key16,
    required BigInt amount,
    required List<int> nonce12,
  });
  BigInt aeDecrypt({required List<int> key16, required List<int> ae});
  SolanaZkProofBytes proveBatchedRange({
    required List<BigInt> amounts,
    required List<List<int>> openings,
    required List<int> seed,
  });

  bool verifyBatchedRange({
    required List<int> proof,
    required List<List<int>> commitments,
  });

  SolanaZkProofBytes proveWithdraw({
    required List<int> sourceSecret,
    required List<int> sourcePubkey,
    required List<int> currentCiphertext,
    required BigInt currentBalance,
    required BigInt withdrawAmount,
    required List<int> seed,
  });

  SolanaZkProofBytes proveTransfer({
    required List<int> sourceSecret,
    required List<int> sourcePubkey,
    required List<int> destPubkey,
    required List<int> auditorPubkey,
    required List<int> currentCiphertext,
    required BigInt currentBalance,
    required BigInt transferAmount,
    required List<int> seed,
  });

  SolanaZkProofBytes proveTransferWithFee({
    required List<int> sourceSecret,
    required List<int> sourcePubkey,
    required List<int> destPubkey,
    required List<int> auditorPubkey,
    required List<int> authorityPubkey,
    required List<int> currentCiphertext,
    required BigInt currentBalance,
    required BigInt transferAmount,
    required int feeRateBasisPoints,
    required BigInt maximumFee,
    required List<int> seed,
  });

  bool isWellFormed(SolanaZkProofBytes proof);

  BuSolanaZkApi get raw;
}
