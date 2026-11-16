import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/core.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A Cardano/Khalow-derivation-scheme ed25519 public key.
class ED25519KholawPublicKey extends BaseEd25519PublicKey {
  ED25519KholawPublicKey._(super.keyBytes);
  factory ED25519KholawPublicKey.fromBytes(List<int> bytes) {
    final normalized = BaseEd25519PublicKey.normalizePublicKey(bytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519KholawPublicKey.fromBytes",
        reason: "Invalid ED25519 public key bytes.",
      );
    }
    return ED25519KholawPublicKey._(normalized);
  }

  @override
  CryptoKeyType get type => CryptoKeyType.ed25519Kholaw;

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

/// A Cardano/Khalow-derivation-scheme ed25519 private key (64-byte
/// extended form: 32-byte scalar + 32-byte iv/chain-code material).
class ED25519KholawPrivateKey
    extends BaseEd25519PrivateKey<ED25519KholawPublicKey> {
  ED25519KholawPrivateKey._({required super.sk, required super.publicKey});

  factory ED25519KholawPrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != Ed25519KeysConst.kholawPrivKeyLen) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519KholawPrivateKey",
        name: "keyBytes",
        reason: "Invalid secret key bytes length.",
      );
    }
    final publicKey = ED25519KeyUtils.derivePublicKey(
      secretKey: keyBytes,
      type: CryptoKeyType.ed25519Kholaw,
    );
    return ED25519KholawPrivateKey._(
      sk: SecretBytes(keyBytes),
      publicKey: ED25519KholawPublicKey.fromBytes(publicKey.toBytes()),
    );
  }

  @override
  CryptoKeyType get type => CryptoKeyType.ed25519Kholaw;

  static bool isValidBytes(List<int> bytes) {
    try {
      ED25519KholawPrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }
}
