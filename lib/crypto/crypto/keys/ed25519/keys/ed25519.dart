import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/encoding/der/src/codec.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/core.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A plain ed25519 public key.
class ED25519PublicKey extends BaseEd25519PublicKey {
  ED25519PublicKey._(super.keyBytes);
  factory ED25519PublicKey.fromBytes(List<int> bytes) {
    final normalized = BaseEd25519PublicKey.normalizePublicKey(bytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519PublicKey.fromBytes",
        reason: "Invalid ED25519 public key bytes.",
      );
    }
    return ED25519PublicKey._(normalized);
  }

  factory ED25519PublicKey.fromDer(List<int> keyBytes) {
    final rawBytes = DerCodec.decodeEd25519PublicKeySpki(keyBytes);
    return ED25519PublicKey.fromBytes(rawBytes);
  }

  @override
  CryptoKeyType get type => CryptoKeyType.ed25519;

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

/// A plain ed25519 private key.
///
/// [sk] always holds the 32-byte RFC 8032 seed; the public key is
/// `G * clamp(SHA-512(seed)[0:32])`. There is no scalar-backed mode:
/// FROST(Ed25519) shares are seeds too, expanded to scalars at signing
/// time; anyone needing raw scalars works directly with the FROST
/// protocol APIs / engines instead of this key type.
class ED25519PrivateKey extends BaseEd25519PrivateKey<ED25519PublicKey> {
  ED25519PrivateKey._({required super.sk, required super.publicKey});

  factory ED25519PrivateKey.fromExpandedKey(List<int> keyBytes) {
    if (keyBytes.length != Ed25519KeysConst.expandedKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519PrivateKey.fromExpandedKey",
        name: "keyBytes",
        reason: "Invalid expanded key bytes length.",
      );
    }
    final privateKey = ED25519PrivateKey.fromBytes(
      keyBytes.sublist(0, Ed25519KeysConst.privKeyByteLen),
    );
    final pkPart = keyBytes.sublist(Ed25519KeysConst.privKeyByteLen);
    if (!BytesUtils.bytesEqual(pkPart, privateKey.publicKey.toBytes())) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519PrivateKey.fromExpandedKey",
        name: "keyBytes",
        reason: "Mismatch public key.",
      );
    }

    return privateKey;
  }
  factory ED25519PrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length == Ed25519KeysConst.expandedKeyByteLen) {
      return ED25519PrivateKey.fromExpandedKey(keyBytes);
    }
    if (keyBytes.length != Ed25519KeysConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "ED25519PrivateKey",
        name: "keyBytes",
        reason: "Invalid secret key bytes length.",
      );
    }
    final publicKey = ED25519KeyUtils.derivePublicKey(
      secretKey: keyBytes,
      type: CryptoKeyType.ed25519,
    );
    return ED25519PrivateKey._(
      sk: SecretBytes(keyBytes),
      publicKey: ED25519PublicKey.fromBytes(publicKey.toBytes()),
    );
  }
  factory ED25519PrivateKey.fromDer(List<int> derBytes) {
    final rawBytes = DerCodec.decodeEd25519PrivateKeyPkcs8(derBytes);
    final sk = rawBytes.takeBytes();
    try {
      return ED25519PrivateKey.fromBytes(sk);
    } finally {
      sk.forceZero();
    }
  }

  factory ED25519PrivateKey.random() {
    final bytes = QuickCrypto.generateRandom(
      length: Ed25519KeysConst.privKeyByteLen,
    );
    try {
      final sc = blockchainUtils.api.ed25519.scReduce(bytes);
      try {
        return ED25519PrivateKey.fromBytes(sc);
      } finally {
        sc.forceZero();
      }
    } finally {
      bytes.forceZero();
    }
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      ED25519PrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  CryptoKeyType get type => CryptoKeyType.ed25519;

  @override
  List<dynamic> get variables => [publicKey];

  SecretBytes toDer() => DerCodec.encodeEd25519PrivateKeyPkcs8(sk);
  SecretBytes toExpandedBytes() => takeSecretKey().useValue(
    (k) => SecretBytes([...k, ...verificationKey().toBytes()]),
  );
}
