import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/core.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A Monero ed25519 public key (zero/identity point is allowed, e.g. for
/// certain view-key derivations).
class ED25519MoneroPublicKey extends BaseEd25519PublicKey {
  ED25519MoneroPublicKey._(super.keyBytes);
  factory ED25519MoneroPublicKey.fromBytes(List<int> bytes) {
    final normalized = BaseEd25519PublicKey.normalizePublicKey(bytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519MoneroPublicKey.fromBytes",
        reason: "Invalid ED25519 public key bytes.",
      );
    }
    return ED25519MoneroPublicKey._(normalized);
  }

  @override
  CryptoKeyType get type => CryptoKeyType.ed25519Monero;

  static bool isValidBytes(List<int> bytes) =>
      BaseEd25519PublicKey.isValidBytes(bytes);

  /// Checks whether [keyBytes] has a valid length for the given [encoding].
  ///
  /// This check validates only the key length and does not verify whether
  /// [keyBytes] represents a valid public key.
  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    return switch (encoding) {
      CryptoKeyEncoding.base
          when keyBytes.length == Ed25519KeysConst.pubKeyByteLen =>
        true,
      _ => false,
    };
  }
}

/// A Monero ed25519 private key.
class ED25519MoneroPrivateKey
    extends BaseEd25519PrivateKey<ED25519MoneroPublicKey> {
  ED25519MoneroPrivateKey._({required super.sk, required super.publicKey});

  /// Creates a zero secret key (only valid where the identity point is
  /// acceptable, e.g. certain internal derivations).
  factory ED25519MoneroPrivateKey.zero() => ED25519MoneroPrivateKey.fromBytes(
    BuBytes.zero(Ed25519KeysConst.privKeyByteLen),
    allowInfinity: true,
  );

  factory ED25519MoneroPrivateKey.fromBytes(
    List<int> keyBytes, {
    bool allowInfinity = false,
  }) {
    if (keyBytes.length != Ed25519KeysConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519MoneroPrivateKey",
        name: "keyBytes",
        reason: "Invalid secret key bytes length.",
      );
    }
    if (!blockchainUtils.api.ed25519.scCheck(keyBytes)) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519MoneroPrivateKey",
        name: "keyBytes",
        reason: "Invalid secret key bytes.",
      );
    }
    final publicKey = ED25519KeyUtils.derivePublicKey(
      secretKey: keyBytes,
      type: CryptoKeyType.ed25519Monero,
    );
    if (!allowInfinity && publicKey.isIdentity()) {
      throw CoreErrors.cryptoFailed(
        "ED25519MoneroPublicKey",
        reason: "Identity point.",
      );
    }
    return ED25519MoneroPrivateKey._(
      sk: SecretBytes(keyBytes),
      publicKey: ED25519MoneroPublicKey._(
        BuBytes.immutable(publicKey.toBytes()),
      ),
    );
  }

  factory ED25519MoneroPrivateKey.fromBip44(List<int> keyBytes) {
    final privateKey = ED25519PrivateKey.fromBytes(keyBytes);
    final reduce = blockchainUtils.api.ed25519.scReduce(
      QuickCrypto.keccak256Hash(privateKey.takeSecretKey().takeBytes()),
    );
    return ED25519MoneroPrivateKey.fromBytes(reduce);
  }
  static bool isValidBytes(List<int> bytes) {
    try {
      ED25519MoneroPrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  CryptoKeyType get type => CryptoKeyType.ed25519Monero;
}
