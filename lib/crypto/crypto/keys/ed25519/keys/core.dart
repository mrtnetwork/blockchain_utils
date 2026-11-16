import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/ed25519_blake2b.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/ed25519_khalow.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/ed25519_monero.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/verify_signing.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/encoding/der/src/codec.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// Constants related to BaseEd25519 keys, including public and private keys.
class Ed25519KeysConst {
  /// Public key prefix: A list of bytes that indicates a public key.
  static const int pubKeyPrefixInt = 0x00;

  /// Public key prefix: A list of bytes that indicates a public key.
  static const List<int> pubKeyPrefix = [pubKeyPrefixInt];

  /// Public key length in bytes: The length of an BaseEd25519 public key.
  static const int pubKeyByteLen = 32;

  /// Private key length in bytes: The length of an BaseEd25519 private key.
  static const int privKeyByteLen = 32;

  /// Private key length in bytes: The length of an BaseEd25519 private key.
  static const int expandedKeyByteLen = privKeyByteLen + pubKeyByteLen;

  static const int kholawPrivKeyLen = 64;

  /// Public key prefix for xrp: A list of bytes that indicates a public key.
  static const List<int> xrpPubKeyPrefix = [0xed];
}

/// Base class for an ed25519-family public key.
///
/// The key is stored as immutable canonical base-encoding bytes; the live
/// point is parsed once on first use (compute paths), while carry, compare
/// and serialize paths use [keyBytes] directly with no conversions.
abstract class BaseEd25519PublicKey extends IEd25519VerificationKey
    with Equality
    implements IPublicKey<Ed25519VerifyingParams> {
  @override
  final BuBytes keyBytes;
  BaseEd25519PublicKey(this.keyBytes);

  // Live point, parsed on demand from [keyBytes].
  // NOTE: every access re-parses (full validation); compute-heavy
  // call sites will be converted to bytes-APIs next phase.
  // EdwardsLimbPoint get point => EdwardsLimbPoint.fromBytes(keyBytes);
  EdwardsLimbPoint toPoint() => EdwardsLimbPoint.fromBytes(keyBytes);
  @override
  CryptoKeyType get type;

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    if (mode == CryptoKeyEncoding.base) return keyBytes;
    return CryptoKeysUtils.ensureSupportPubKeyMode(
      mode: mode,
      type: type,
      onModeBytes:
          (mode) => switch (mode) {
            CryptoKeyEncoding.base => keyBytes,
            CryptoKeyEncoding.uncompressed => null,
          },
    );
  }

  BuBytes toBip32PublicKeyBytes() =>
      BuBytes([...Ed25519KeysConst.pubKeyPrefix, ...toBytes()]);

  /// Validates [bytes] through the backend signing API and returns the
  /// canonical 32-byte base encoding, or null when invalid. Accepts the
  /// 33-byte `0xed`-prefixed form (stripped before the API call, since the
  /// backend takes raw fixed-length bytes). Single source of truth for key
  /// parsing.
  static BuBytes? normalizePublicKey(List<int> bytes) {
    if (bytes.length ==
            Ed25519KeysConst.pubKeyByteLen +
                Ed25519KeysConst.pubKeyPrefix.length &&
        bytes[0] == Ed25519KeysConst.pubKeyPrefixInt) {
      bytes = bytes.sublist(Ed25519KeysConst.pubKeyPrefix.length);
    }
    return blockchainUtils.api.signing.ed25519.normalizePublicKey(bytes);
  }

  static bool isValidBytes(List<int> bytes) {
    return normalizePublicKey(bytes) != null;
  }

  /// Checks whether [keyBytes] has a valid length for the given [encoding].
  ///
  /// This check validates only the key length and does not verify whether
  /// [keyBytes] represents a valid public key.
  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) => false;

  @override
  List<dynamic> get variables => [keyBytes];

  static BaseEd25519PublicKey fromBytes({
    required List<int> bytes,
    required CryptoKeyType type,
  }) {
    return switch (type) {
      CryptoKeyType.ed25519 => ED25519PublicKey.fromBytes(bytes),
      CryptoKeyType.ed25519Blake2b => ED25519Blake2bPublicKey.fromBytes(bytes),
      CryptoKeyType.ed25519Kholaw => ED25519KholawPublicKey.fromBytes(bytes),
      CryptoKeyType.ed25519Monero => ED25519MoneroPublicKey.fromBytes(bytes),
      _ =>
        throw CoreErrors.cryptoFailed(
          "BaseEd25519PublicKey.fromBytes",
          reason: "Invalid key type.",
        ),
    };
  }

  BuBytes toDer() => DerCodec.encodeEd25519PublicKeySpki(keyBytes);
}

/// Base class for an ed25519-family private key.
abstract class BaseEd25519PrivateKey<PK extends BaseEd25519PublicKey>
    extends IEd25519SigningKey<PK>
    with Equality
    implements IPrivateKey<ED25519Signature, Ed25519SigningParams, PK> {
  final SecretBytes sk;
  @override
  final PK publicKey;
  BaseEd25519PrivateKey({required this.sk, required this.publicKey});

  void _ensureAlive(String operation) {
    if (sk.isZeroed) {
      throw CoreErrors.badState(
        operation,
        reason: "Private key has been disposed.",
      );
    }
  }

  @override
  void dispose() {
    sk.zero();
  }

  static BaseEd25519PrivateKey fromBytes({
    required List<int> bytes,
    required CryptoKeyType type,
  }) {
    return switch (type) {
      CryptoKeyType.ed25519 => ED25519PrivateKey.fromBytes(bytes),
      CryptoKeyType.ed25519Blake2b => ED25519Blake2bPrivateKey.fromBytes(bytes),
      CryptoKeyType.ed25519Kholaw => ED25519KholawPrivateKey.fromBytes(bytes),
      CryptoKeyType.ed25519Monero => ED25519MoneroPrivateKey.fromBytes(bytes),
      _ =>
        throw CoreErrors.cryptoFailed(
          "BaseEd25519PrivateKey.fromBytes",
          reason: "Invalid key type.",
        ),
    };
  }

  @override
  CryptoKeyType get type;

  @override
  List<dynamic> get variables => [publicKey];

  @override
  PK verificationKey() {
    return publicKey;
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    _ensureAlive("BaseEd25519PrivateKey.toBytes");
    return sk.cloneBytes(transform: transform);
  }

  @override
  SecretBytes takeSecretKey() {
    _ensureAlive("BaseEd25519PrivateKey.takeSecretKey");
    return sk;
  }
}
