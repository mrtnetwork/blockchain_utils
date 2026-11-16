import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/encoding/der/src/codec.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/src/verify_signing.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Base class for a secp256k1 public key implementing IPublicKey.
///
/// The key is stored as immutable canonical base-encoding bytes; the live
/// point is parsed once on first use (compute paths), while carry, compare
/// and serialize paths use [keyBytes] directly with no conversions.
abstract class BaseSecp256k1PublicKey extends ISecp256k1VerificationKey
    with Equality
    implements IPublicKey<Secp256k1VerifyingParams> {
  @override
  final BuBytes keyBytes;
  BaseSecp256k1PublicKey(this.keyBytes);

  // Live point, parsed on demand from [keyBytes].
  // NOTE: every access re-parses (full validation); compute-heavy
  // call sites will be converted to bytes-APIs next phase.
  // Secp256k1Point get point => Secp256k1Point.fromBytes(keyBytes);

  @override
  CryptoKeyType get type;

  /// Validates [keyBytes] through the backend signing API and returns its
  /// canonical base (compressed) encoding, or null when invalid (bad
  /// length, prefix, range, curve membership, or identity). Single source
  /// of truth for key parsing.
  static BuBytes? normalizePublicKey(List<int> keyBytes) {
    return blockchainUtils.api.signing.secp256k1.normalizePublicKey(keyBytes);
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    return normalizePublicKey(keyBytes) != null;
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
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    if (mode == CryptoKeyEncoding.base) return keyBytes;
    return CryptoKeysUtils.ensureSupportPubKeyMode(
      mode: mode,
      type: type,
      onModeBytes:
          (mode) => switch (mode) {
            CryptoKeyEncoding.base => keyBytes.cloneBytes(),
            CryptoKeyEncoding.uncompressed => Secp256k1Point.fromBytes(
              keyBytes,
            ).toBytes(mode),
          },
    );
  }

  BuBytes toDer({CryptoKeyEncoding pubKeyMode = CryptoKeyEncoding.base}) =>
      DerCodec.encodeSecp256k1PublicKeySpki(toBytes(mode: pubKeyMode));

  @override
  List<dynamic> get variables => [keyBytes];
}

/// Base class for a secp256k1 private key implementing IPrivateKey.
abstract class BaseSecp256k1PrivateKey<P extends BaseSecp256k1PublicKey>
    extends ISecp256k1SigningKey<P>
    with Equality
    implements IPrivateKey<IECDSASignature, Secp256k1SigningParams, P> {
  final SecretBytes sk;
  @override
  final P publicKey;

  BaseSecp256k1PrivateKey(List<int> sk, this.publicKey) : sk = SecretBytes(sk);

  void _ensureAlive(String operation) {
    if (sk.isZeroed) {
      throw CoreErrors.badState(
        operation,
        reason: "Private key has been disposed.",
      );
    }
  }

  /// curve type.
  @override
  CryptoKeyType get type;

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    if (keyBytes.length != EcdsaKeysConst.privKeyByteLen) return false;
    try {
      return !Secp256k1Fr.fromBytes(keyBytes).isZero();
    } catch (_) {
      return false;
    }
  }

  SecretBytes toDer({CryptoKeyEncoding? pubKeyMode}) =>
      DerCodec.encodeSecp256k1PrivateKeyPkcs8(
        sk,
        publicKeyPoint: switch (pubKeyMode) {
          null => null,
          _ => publicKey.toBytes(mode: pubKeyMode),
        },
      );

  @override
  List<dynamic> get variables => [publicKey];

  @override
  P verificationKey() {
    return publicKey;
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    _ensureAlive("BaseSecp256k1PrivateKey.toBytes");
    return sk.cloneBytes(transform: transform);
  }

  @override
  void dispose() {
    sk.zero();
  }

  @override
  SecretBytes takeSecretKey() {
    _ensureAlive("BaseSecp256k1PrivateKey.takeSecretKey");
    return sk;
  }
}
