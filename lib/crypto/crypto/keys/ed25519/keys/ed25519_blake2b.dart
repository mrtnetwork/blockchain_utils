import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/encoding/der/src/codec.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/core.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// An ed25519 public key that hashes with Blake2b (used e.g. by Nano).
class ED25519Blake2bPublicKey extends BaseEd25519PublicKey {
  ED25519Blake2bPublicKey._(super.keyBytes);
  factory ED25519Blake2bPublicKey.fromBytes(List<int> bytes) {
    final normalized = BaseEd25519PublicKey.normalizePublicKey(bytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519Blake2bPublicKey.fromBytes",
        reason: "Invalid ED25519 public key bytes.",
      );
    }
    return ED25519Blake2bPublicKey._(normalized);
  }

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

  @override
  CryptoKeyType get type => CryptoKeyType.ed25519Blake2b;
}

/// An ed25519 private key that hashes with Blake2b (used e.g. by Nano).
class ED25519Blake2bPrivateKey
    extends BaseEd25519PrivateKey<ED25519Blake2bPublicKey> {
  ED25519Blake2bPrivateKey._({required super.sk, required super.publicKey});

  factory ED25519Blake2bPrivateKey.fromExpandedKey(List<int> keyBytes) {
    if (keyBytes.length != Ed25519KeysConst.expandedKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519Blake2bPrivateKey.fromExpandedKey",
        name: "keyBytes",
        reason: "Invalid expanded key bytes length.",
      );
    }
    final privateKey = ED25519Blake2bPrivateKey.fromBytes(
      keyBytes.sublist(0, Ed25519KeysConst.privKeyByteLen),
    );
    final pkPart = keyBytes.sublist(Ed25519KeysConst.privKeyByteLen);
    if (!BytesUtils.bytesEqual(pkPart, privateKey.publicKey.toBytes())) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519Blake2bPrivateKey.fromExpandedKey",
        name: "keyBytes",
        reason: "Mismatch public key.",
      );
    }

    return privateKey;
  }
  factory ED25519Blake2bPrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length == Ed25519KeysConst.expandedKeyByteLen) {
      return ED25519Blake2bPrivateKey.fromExpandedKey(keyBytes);
    }
    if (keyBytes.length != Ed25519KeysConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519Blake2bPrivateKey.fromBytes",
        name: "keyBytes",
        reason: "Invalid secret key bytes length.",
      );
    }
    final publicKey = ED25519KeyUtils.derivePublicKey(
      secretKey: keyBytes,
      type: CryptoKeyType.ed25519Blake2b,
    );
    return ED25519Blake2bPrivateKey._(
      sk: SecretBytes(keyBytes),
      publicKey: ED25519Blake2bPublicKey.fromBytes(publicKey.toBytes()),
    );
  }
  factory ED25519Blake2bPrivateKey.fromDer(List<int> derBytes) {
    final rawBytes = DerCodec.decodeEd25519PrivateKeyPkcs8(derBytes);
    final sk = rawBytes.takeBytes();
    try {
      return ED25519Blake2bPrivateKey.fromBytes(sk);
    } finally {
      sk.forceZero();
    }
  }

  factory ED25519Blake2bPrivateKey.random() {
    final bytes = QuickCrypto.generateRandom(
      length: Ed25519KeysConst.privKeyByteLen,
    );
    try {
      final sc = blockchainUtils.api.ed25519.scReduce(bytes);
      try {
        return ED25519Blake2bPrivateKey.fromBytes(sc);
      } finally {
        sc.forceZero();
      }
    } finally {
      bytes.forceZero();
    }
  }

  @override
  CryptoKeyType get type => CryptoKeyType.ed25519Blake2b;

  static bool isValidBytes(List<int> bytes) {
    try {
      ED25519Blake2bPrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }
}
