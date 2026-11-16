import 'package:blockchain_utils/crypto/crypto/group/ristretto/point/ristretto.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Solana Twisted ElGamal byte types (dalek Bulletproofs stack,
/// NOT Monero Bulletproofs+). Pure-Dart codecs only; proving lives in Rust.
class SolanaZkConstants {
  /// ElGamal pubkey length (compressed Ristretto, 32 bytes).
  static const int elGamalPubkeyLen = 32;

  /// ElGamal ciphertext length (2 x compressed Ristretto).
  static const int elGamalCiphertextLen = 64;

  /// AES decryptable balance length.
  static const int aeCiphertextLen = 36;

  /// Range proof covers 64-bit amounts (split lo/hi 32-bit).
  static const int rangeBits = 64;
}

/// Validated Solana ElGamal pubkey (32-byte Ristretto point).
class SolanaElGamalPubkey {
  /// Raw compressed Ristretto bytes.
  final BuBytes bytes;
  const SolanaElGamalPubkey._(this.bytes);

  /// Validate length + Ristretto decoding.
  factory SolanaElGamalPubkey.fromBytes(List<int> bytes) {
    if (bytes.length != SolanaZkConstants.elGamalPubkeyLen) {
      throw CoreErrors.invalidOperationArguments(
        'SolanaElGamalPubkey',
        name: 'bytes',
        reason: 'Invalid ElGamal pubkey length.',
      );
    }
    RistrettoPoint.fromBytes(bytes);
    return SolanaElGamalPubkey._(
      bytes is BuBytes ? bytes : BuBytes.from(bytes),
    );
  }

  /// Serialize to 32 bytes.
  BuBytes toBytes() => bytes;
}

/// Solana ElGamal ciphertext (commitment || handle, 64 bytes).
class SolanaElGamalCiphertext {
  /// Commitment part (first 32 bytes).
  final BuBytes commitment;

  /// Handle part (last 32 bytes).
  final BuBytes handle;
  const SolanaElGamalCiphertext._(this.commitment, this.handle);

  /// Split + validate both Ristretto halves.
  factory SolanaElGamalCiphertext.fromBytes(List<int> bytes) {
    if (bytes.length != SolanaZkConstants.elGamalCiphertextLen) {
      throw CoreErrors.invalidOperationArguments(
        'SolanaElGamalCiphertext',
        name: 'bytes',
        reason: 'Invalid ElGamal ciphertext length.',
      );
    }
    RistrettoPoint.fromBytes(bytes.sublist(0, 32));
    RistrettoPoint.fromBytes(bytes.sublist(32, 64));
    return SolanaElGamalCiphertext._(
      BuBytes.from(bytes.sublist(0, 32)),
      BuBytes.from(bytes.sublist(32, 64)),
    );
  }

  /// Concatenate commitment || handle.
  BuBytes toBytes() => BuBytes.concat([commitment, handle]);
}

/// AES decryptable balance (32 bytes, symmetric sidecar).
class SolanaAeCiphertext {
  /// Raw 32 bytes.
  final BuBytes bytes;
  const SolanaAeCiphertext._(this.bytes);

  /// Length-check only (no curve math on AES sidecar).
  factory SolanaAeCiphertext.fromBytes(List<int> bytes) {
    if (bytes.length != SolanaZkConstants.aeCiphertextLen) {
      throw CoreErrors.invalidOperationArguments(
        'SolanaAeCiphertext',
        name: 'bytes',
        reason: 'Invalid AeCiphertext length.',
      );
    }
    return SolanaAeCiphertext._(bytes is BuBytes ? bytes : BuBytes.from(bytes));
  }

  /// Serialize to 32 bytes.
  BuBytes toBytes() => bytes;
}

/// zk-token-proof kinds. Solana uses dalek Bulletproofs +
/// Sigma protocols; none of these verify against Monero Bulletproofs+.
enum SolanaZkProofKind {
  /// ElGamal pubkey-validity proof (ConfigureAccount).
  pubkeyValidity,

  /// Zero-balance proof (EmptyAccount).
  zeroBalance,

  /// Withdraw equality + range bundle.
  withdraw,

  /// Transfer bundle (equality + validity + range).
  transfer,

  /// Transfer-with-fee bundle (adds fee sigma + validity).
  transferWithFee,

  /// Grouped/batched ciphertext-validity proof.
  ciphertextValidity,

  /// Fee sigma + percentage-with-cap proof.
  feeSigma,

  /// Batched dalek Bulletproof range proof.
  batchedRange,
}

/// Opaque proof bytes with kind tag (proving is native-only).
class SolanaZkProofBytes {
  /// Which circuit this blob belongs to.
  final SolanaZkProofKind kind;

  /// Raw proof bytes (zk-token-proof program encoding).
  final BuBytes bytes;
  const SolanaZkProofBytes._(this.kind, this.bytes);

  /// Wrap pre-built proof bytes (e.g. from Rust or RPC).
  factory SolanaZkProofBytes.fromBytes(
    SolanaZkProofKind kind,
    List<int> bytes,
  ) {
    if (bytes.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        'SolanaZkProofBytes',
        name: 'bytes',
        reason: 'Empty proof bytes.',
      );
    }
    return SolanaZkProofBytes._(kind, BuBytes.from(bytes));
  }
}
