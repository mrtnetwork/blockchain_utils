import 'package:blockchain_utils/crypto/crypto/solana_zk/api.dart';
import 'package:blockchain_utils/crypto/crypto/solana_zk/twisted_elgamal.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

Never _unsupported(String op) =>
    throw BuError(
      DefaultErrorType.unsupported,
      'SolanaZk.$op is not implemented in pure Dart; use the Rust native API.',
    );

class DartSolanaZkApi implements SolanaZkApi {
  const DartSolanaZkApi(this._raw);
  final BuSolanaZkApi _raw;
  @override
  bool get supported => false;
  @override
  SolanaElGamalPubkey pubkeyFromSecret(List<int> secret) =>
      _unsupported('pubkeyFromSecret');

  @override
  SolanaElGamalCiphertext encryptWith({
    required SolanaElGamalPubkey pubkey,
    required BigInt amount,
    required List<int> opening,
  }) => _unsupported('encryptWith');

  @override
  int decryptU32({
    required List<int> secret,
    required SolanaElGamalCiphertext ciphertext,
  }) => _unsupported('decryptU32');

  @override
  SolanaAeCiphertext aeEncrypt({
    required List<int> key16,
    required BigInt amount,
    required List<int> nonce12,
  }) => _unsupported('aeEncrypt');

  @override
  BigInt aeDecrypt({required List<int> key16, required List<int> ae}) =>
      _unsupported('aeDecrypt');

  @override
  SolanaZkProofBytes proveBatchedRange({
    required List<BigInt> amounts,
    required List<List<int>> openings,
    required List<int> seed,
  }) => _unsupported('proveBatchedRange');

  @override
  bool verifyBatchedRange({
    required List<int> proof,
    required List<List<int>> commitments,
  }) => _unsupported('verifyBatchedRange');

  @override
  SolanaZkProofBytes proveWithdraw({
    required List<int> sourceSecret,
    required List<int> sourcePubkey,
    required List<int> currentCiphertext,
    required BigInt currentBalance,
    required BigInt withdrawAmount,
    required List<int> seed,
  }) => _unsupported('proveWithdraw');

  @override
  SolanaZkProofBytes proveTransfer({
    required List<int> sourceSecret,
    required List<int> sourcePubkey,
    required List<int> destPubkey,
    required List<int> auditorPubkey,
    required List<int> currentCiphertext,
    required BigInt currentBalance,
    required BigInt transferAmount,
    required List<int> seed,
  }) => _unsupported('proveTransfer');

  @override
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
  }) => _unsupported('proveTransferWithFee');

  @override
  bool isWellFormed(SolanaZkProofBytes proof) => proof.bytes.isNotEmpty;

  @override
  BuSolanaZkApi get raw => _raw;
}
