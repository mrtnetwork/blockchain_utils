import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/solana_zk/api.dart';
import 'package:blockchain_utils/crypto/crypto/solana_zk/twisted_elgamal.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [SolanaZkApi] backed by the Rust `solana_zk` backend
/// (FFI/platform). All proofs use on-chain instruction transcripts.
class NativeSolanaZkApi implements SolanaZkApi {
  final BuSolanaZkApi api;
  const NativeSolanaZkApi(this.api);

  static final BigInt _u64max = BigInt.parse('18446744073709551615');

  static int _u64(BigInt v, String op, String name) {
    if (v < BigInt.zero || v > _u64max) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: name,
        reason: 'amount out of u64 range: $v',
      );
    }
    return v.toInt();
  }

  static List<int> _u64Le(BigInt v, String op, String name) =>
      _u64ToLe(_u64(v, op, name));

  static List<int> _u64ToLe(int v) {
    final out = List<int>.filled(8, 0);
    for (var i = 0; i < 8; i++) {
      out[i] = (v >> (8 * i)) & 0xff;
    }
    return out;
  }

  static List<int> _req(List<int> x, int n, String op, String name) {
    ApiValidate.length(x, n, operation: op, name: name);
    return x;
  }

  @override
  bool get supported => true;

  @override
  SolanaElGamalPubkey pubkeyFromSecret(List<int> secret) {
    const op = 'SolanaZk.pubkeyFromSecret';
    final bytes = ApiValidate.call(
      op,
      () =>
          api
              .pubkeyFromSecret(_req(secret, 32, op, 'secret'))
              .unwrapOrThrowCryptoError(),
    );
    return SolanaElGamalPubkey.fromBytes(bytes);
  }

  @override
  SolanaElGamalCiphertext encryptWith({
    required SolanaElGamalPubkey pubkey,
    required BigInt amount,
    required List<int> opening,
  }) {
    const op = 'SolanaZk.encryptWith';
    final bytes = ApiValidate.call(
      op,
      () =>
          api
              .encryptWith(
                pubkey: pubkey.toBytes(),
                amount: _u64(amount, op, 'amount'),
                opening: _req(opening, 32, op, 'opening'),
              )
              .unwrapOrThrowCryptoError(),
    );
    return SolanaElGamalCiphertext.fromBytes(bytes);
  }

  @override
  int decryptU32({
    required List<int> secret,
    required SolanaElGamalCiphertext ciphertext,
  }) {
    const op = 'SolanaZk.decryptU32';
    return ApiValidate.call(
      op,
      () =>
          api
              .decryptU32(
                secret: _req(secret, 32, op, 'secret'),
                ciphertext: ciphertext.toBytes(),
              )
              .unwrapOrThrowCryptoError(),
    );
  }

  @override
  SolanaAeCiphertext aeEncrypt({
    required List<int> key16,
    required BigInt amount,
    required List<int> nonce12,
  }) {
    const op = 'SolanaZk.aeEncrypt';
    final bytes = ApiValidate.call(
      op,
      () =>
          api
              .aeEncrypt(
                key16: _req(key16, 16, op, 'key16'),
                amount: _u64(amount, op, 'amount'),
                nonce12: _req(nonce12, 12, op, 'nonce12'),
              )
              .unwrapOrThrowCryptoError(),
    );
    return SolanaAeCiphertext.fromBytes(bytes);
  }

  @override
  BigInt aeDecrypt({required List<int> key16, required List<int> ae}) {
    const op = 'SolanaZk.aeDecrypt';
    final v = ApiValidate.call(
      op,
      () =>
          api
              .aeDecrypt(
                key16: _req(key16, 16, op, 'key16'),
                ae: _req(ae, 36, op, 'ae'),
              )
              .unwrapOrThrowCryptoError(),
    );
    return BigInt.from(v);
  }

  @override
  SolanaZkProofBytes proveBatchedRange({
    required List<BigInt> amounts,
    required List<List<int>> openings,
    required List<int> seed,
  }) {
    const op = 'SolanaZk.proveBatchedRange';
    if (amounts.isEmpty || amounts.length > 16) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'amounts',
        reason: 'need 1..16 amounts, got ${amounts.length}',
      );
    }
    if (openings.length != amounts.length) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'openings',
        reason: 'need ${amounts.length} openings, got ${openings.length}',
      );
    }
    ApiValidate.length(seed, 32, operation: op, name: 'seed');
    final blob = ApiValidate.call(
      op,
      () =>
          api
              .proveBatchedRange(
                amountsLe: [for (final a in amounts) _u64Le(a, op, 'amounts')],
                openings: [
                  for (final o in openings) _req(o, 32, op, 'openings'),
                ],
                seed32: seed,
              )
              .unwrapOrThrowCryptoError(),
    );
    return SolanaZkProofBytes.fromBytes(SolanaZkProofKind.batchedRange, blob);
  }

  @override
  bool verifyBatchedRange({
    required List<int> proof,
    required List<List<int>> commitments,
  }) {
    const op = 'SolanaZk.verifyBatchedRange';
    if (commitments.isEmpty || commitments.length > 16) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'commitments',
        reason: 'need 1..16 commitments, got ${commitments.length}',
      );
    }
    for (final c in commitments) {
      ApiValidate.length(c, 32, operation: op, name: 'commitments');
    }
    return ApiValidate.call(
      op,
      () =>
          api
              .verifyBatchedRange(
                proof: proof,
                commitments: [for (final c in commitments) ...c],
                n: commitments.length,
              )
              .unwrapOrThrowCryptoError(),
    );
  }

  @override
  SolanaZkProofBytes proveWithdraw({
    required List<int> sourceSecret,
    required List<int> sourcePubkey,
    required List<int> currentCiphertext,
    required BigInt currentBalance,
    required BigInt withdrawAmount,
    required List<int> seed,
  }) {
    const op = 'SolanaZk.proveWithdraw';
    final blob = ApiValidate.call(
      op,
      () =>
          api
              .proveWithdraw(
                sourceSecret: _req(sourceSecret, 32, op, 'sourceSecret'),
                sourcePubkey: _req(sourcePubkey, 32, op, 'sourcePubkey'),
                currentCiphertext: _req(
                  currentCiphertext,
                  64,
                  op,
                  'currentCiphertext',
                ),
                currentBalance: _u64(currentBalance, op, 'currentBalance'),
                withdrawAmount: _u64(withdrawAmount, op, 'withdrawAmount'),
                seed32: _req(seed, 32, op, 'seed'),
              )
              .unwrapOrThrowCryptoError(),
    );
    return SolanaZkProofBytes.fromBytes(SolanaZkProofKind.withdraw, blob);
  }

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
  }) {
    const op = 'SolanaZk.proveTransfer';
    final blob = ApiValidate.call(
      op,
      () =>
          api
              .proveTransfer(
                sourceSecret: _req(sourceSecret, 32, op, 'sourceSecret'),
                sourcePubkey: _req(sourcePubkey, 32, op, 'sourcePubkey'),
                destPubkey: _req(destPubkey, 32, op, 'destPubkey'),
                auditorPubkey: _req(auditorPubkey, 32, op, 'auditorPubkey'),
                currentCiphertext: _req(
                  currentCiphertext,
                  64,
                  op,
                  'currentCiphertext',
                ),
                currentBalance: _u64(currentBalance, op, 'currentBalance'),
                transferAmount: _u64(transferAmount, op, 'transferAmount'),
                seed32: _req(seed, 32, op, 'seed'),
              )
              .unwrapOrThrowCryptoError(),
    );
    return SolanaZkProofBytes.fromBytes(SolanaZkProofKind.transfer, blob);
  }

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
  }) {
    const op = 'SolanaZk.proveTransferWithFee';
    if (feeRateBasisPoints < 0 || feeRateBasisPoints > 10000) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'feeRateBasisPoints',
        reason: 'must be 0..10000, got $feeRateBasisPoints',
      );
    }
    final blob = ApiValidate.call(
      op,
      () =>
          api
              .proveTransferWithFee(
                sourceSecret: _req(sourceSecret, 32, op, 'sourceSecret'),
                sourcePubkey: _req(sourcePubkey, 32, op, 'sourcePubkey'),
                destPubkey: _req(destPubkey, 32, op, 'destPubkey'),
                auditorPubkey: _req(auditorPubkey, 32, op, 'auditorPubkey'),
                authorityPubkey: _req(
                  authorityPubkey,
                  32,
                  op,
                  'authorityPubkey',
                ),
                currentCiphertext: _req(
                  currentCiphertext,
                  64,
                  op,
                  'currentCiphertext',
                ),
                currentBalance: _u64(currentBalance, op, 'currentBalance'),
                transferAmount: _u64(transferAmount, op, 'transferAmount'),
                feeRateBasisPoints: feeRateBasisPoints,
                maximumFee: _u64(maximumFee, op, 'maximumFee'),
                seed32: _req(seed, 32, op, 'seed'),
              )
              .unwrapOrThrowCryptoError(),
    );
    return SolanaZkProofBytes.fromBytes(
      SolanaZkProofKind.transferWithFee,
      blob,
    );
  }

  @override
  bool isWellFormed(SolanaZkProofBytes proof) => proof.bytes.isNotEmpty;

  @override
  BuSolanaZkApi get raw => api;
}
