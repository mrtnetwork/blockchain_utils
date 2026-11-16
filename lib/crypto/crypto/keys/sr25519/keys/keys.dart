import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/ristretto/point/ristretto.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/keys/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/keys/utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/keys/verify_signing.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/prng/src/rng.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// Schnorrkel (sr25519) public key.
///
/// The key is stored as immutable canonical base-encoding bytes; the live
/// point is parsed once on first use (compute paths), while carry, compare
/// and serialize paths use [keyBytes] directly with no conversions.
class SR25519PublicKey extends ISR25519VerificationKey
    with Equality
    implements IPublicKey<SR25519VerifyingParams> {
  @override
  final BuBytes keyBytes;

  SR25519PublicKey._(this.keyBytes);

  // Live point, parsed on demand from [keyBytes].
  // NOTE: every access re-parses (full validation); compute-heavy
  // call sites will be converted to bytes-APIs next phase.
  // RistrettoPoint get point => RistrettoPoint.fromBytes(keyBytes);

  factory SR25519PublicKey.fromBytes(List<int> keyBytes) {
    keyBytes.exc(
      length: SchnorrkelKeyCost.publickeyLength,
      operation: "SR25519PublicKey.fromBytes",
      reason: "Invalid public key bytes length.",
    );
    // fromBytes historically accepts the identity encoding (only
    // fromPoint rejects it); the backend API is strict, so identity now
    // throws here too. No valid flow parses identity keys off the wire.
    final normalized = normalizePublicKey(keyBytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "SR25519PublicKey.fromBytes",
        reason: "Invalid public key bytes.",
      );
    }
    return SR25519PublicKey._(normalized);
  }


  /// Validates [keyBytes] through the backend signing API and returns its
  /// canonical base encoding, or null when invalid. Single source of truth
  /// for key parsing.
  static BuBytes? normalizePublicKey(List<int> keyBytes) {
    return blockchainUtils.api.signing.sr25519.normalizePublicKey(keyBytes);
  }

  /// backwards-compatible positional constructor
  factory SR25519PublicKey(List<int> keyBytes) =>
      SR25519PublicKey.fromBytes(keyBytes);

  @override
  CryptoKeyType get type => CryptoKeyType.sr25519;

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

  (SR25519PublicKey, BuBytes) derive(
    List<int> chainCode, [
    List<int>? message,
  ]) {
    final (pk, cc) = blockchainUtils.api.signing.sr25519.derivePublic(
      publicKey: keyBytes,
      chainCode32: chainCode,
      message: message,
    );
    return (SR25519PublicKey.fromBytes(pk), cc);
  }

  static bool isValidBytes(List<int> key) {
    return normalizePublicKey(key) != null;
  }

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
          when keyBytes.length == SchnorrkelKeyCost.publickeyLength =>
        true,
      _ => false,
    };
  }

  @override
  List<dynamic> get variables => [keyBytes];
}

/// Schnorrkel (sr25519) secret key.
class SR25519PrivateKey extends ISR25519SigningKey<SR25519PublicKey>
    with Equality
    implements
        IPrivateKey<SR25519Signature, SR25519SigningParams, SR25519PublicKey> {
  SR25519PrivateKey._({required this.sk, required this.publicKey});

  factory SR25519PrivateKey(List<int> key, List<int> nonce) {
    key.exc(
      length: SchnorrkelKeyCost.miniSecretLength,
      operation: "SR25519PrivateKey",
      reason: "Invalid secret key bytes length.",
    );
    nonce.exc(
      length: SchnorrkelKeyCost.nonceLength,
      operation: "SR25519PrivateKey",
      reason: "Invalid secret nonce bytes length.",
    );
    final canonicalKey = SchnorrKeyUtils.toCanonical(key);
    if (canonicalKey == null) {
      throw CoreErrors.cryptoFailed(
        "SR25519PrivateKey",
        reason: "invalid sr25519 private key.",
      );
    }
    final sk = SecretBytes.take([...canonicalKey, ...nonce]);
    try {
      return SR25519PrivateKey._(
        sk: sk,
        publicKey: _derivePublicKey(canonicalKey),
      );
    } finally {
      BinaryOps.tryZero(canonicalKey);
    }
  }

  factory SR25519PrivateKey.fromBytes(List<int> secretKeyBytes) {
    secretKeyBytes.exc(
      length: SchnorrkelKeyCost.secretKeyLength,
      operation: "SR25519PrivateKey.fromBytes",
      reason: "Invalid secret key bytes length.",
    );
    List<int> keyBytes = secretKeyBytes.sublist(
      0,
      SchnorrkelKeyCost.miniSecretLength,
    );
    final nonceBytes = secretKeyBytes.sublist(
      SchnorrkelKeyCost.miniSecretLength,
      SchnorrkelKeyCost.secretKeyLength,
    );
    return SR25519PrivateKey(keyBytes, nonceBytes);
  }

  factory SR25519PrivateKey.fromEd25519(List<int> secretKeyBytes) {
    secretKeyBytes.exc(
      length: SchnorrkelKeyCost.secretKeyLength,
      operation: "SR25519PrivateKey.fromEd25519",
      reason: "Invalid secret key bytes length.",
    );
    final newKey = secretKeyBytes.sublist(
      0,
      SchnorrkelKeyCost.miniSecretLength,
    );
    SchnorrKeyUtils.divideScalarByCofactor(newKey);
    return SR25519PrivateKey(
      newKey,
      secretKeyBytes.sublist(
        SchnorrkelKeyCost.miniSecretLength,
        SchnorrkelKeyCost.secretKeyLength,
      ),
    );
  }

  static SR25519PublicKey _derivePublicKey(List<int> keyBytes) {
    final pubkey = blockchainUtils.api.ed25519.multBase(keyBytes);
    final pubPoint = RistrettoPoint.fromEdwardBytes(pubkey);
    return SR25519PublicKey.fromBytes(pubPoint.toBytes());
  }

  final SecretBytes sk;

  @override
  final SR25519PublicKey publicKey;

  @override
  CryptoKeyType get type => CryptoKeyType.sr25519;

  /// The secret nonce half of the expanded key.
  ///
  BuBytes nonce() => BuBytes(sk.sublist(SchnorrkelKeyCost.miniSecretLength));

  @override
  SR25519PublicKey verificationKey() => publicKey;

  SecretBytes toEd25519Bytes() {
    return takeSecretKey().useValue((sk) {
      return SecretBytes.take(
        blockchainUtils.api.signing.sr25519.toEd25519Bytes(sk),
      );
    });
  }

  (SR25519PrivateKey, BuBytes) hardDerive(
    List<int> chainCode, {
    List<int>? message,
    ExpansionMode mode = ExpansionMode.ed25519,
  }) {
    return takeSecretKey().useValue((k) {
      final (newSk, cc) = blockchainUtils.api.signing.sr25519.hardDerive(
        chainCode32: chainCode,
        message: message,
        seedOrSk: k,
        fromSeed: false,
        uniform: mode == ExpansionMode.uniform,
      );
      try {
        return (SR25519PrivateKey.fromBytes(newSk), cc);
      } finally {
        newSk.forceZero();
      }
    });
  }

  (SR25519PrivateKey, BuBytes) softDerive(
    List<int> chainCode, {
    List<int>? message,
    Rng? nonceGenerator,
  }) {
    return takeSecretKey().useValue((k) {
      final generatedNonce =
          nonceGenerator?.nextBytes(SchnorrkelKeyCost.nonceLength) ??
          QuickCrypto.generateRandom(length: SchnorrkelKeyCost.nonceLength);
      try {
        final (newSk, cc) = blockchainUtils.api.signing.sr25519.softDerive(
          chainCode32: chainCode,
          message: message,
          seedOrSk: k,
          fromSeed: false,
          uniform: false,
          newNonce32: generatedNonce,
        );
        try {
          return (SR25519PrivateKey.fromBytes(newSk), cc);
        } finally {
          newSk.forceZero();
        }
      } finally {
        generatedNonce.forceZero();
      }
    });
  }

  SecretBytes key() => takeSecretKey().useValue(
    (k) => SecretBytes(k.sublist(0, SchnorrkelKeyCost.miniSecretLength)),
  );

  @override
  List<dynamic> get variables => [publicKey];

  void _ensureAlive(String operation) {
    if (sk.isZeroed) {
      throw CoreErrors.badState(
        operation,
        reason: "Private key has been disposed.",
      );
    }
  }

  static bool isValidBytes(List<int> key) {
    try {
      SR25519PrivateKey.fromBytes(key);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    _ensureAlive("SR25519PrivateKey.toBytes");
    return sk.cloneBytes(transform: transform);
  }

  @override
  void dispose() {
    sk.zero();
  }

  @override
  SecretBytes takeSecretKey() {
    _ensureAlive("SR25519PrivateKey.takeSecretKey");
    return sk;
  }
}

/// Schnorrkel (sr25519) key pair.
class SR25519Keypair {
  SR25519Keypair._(this.secretKey, this.publicKey);
  final SR25519PrivateKey secretKey;
  final SR25519PublicKey publicKey;

  factory SR25519Keypair.fromBytes(List<int> bytes) {
    bytes.exc(
      length: SchnorrkelKeyCost.keypairLength,
      name: "bytes",
      operation: "SR25519Keypair.fromBytes",
    );
    final secret = SR25519PrivateKey.fromBytes(
      bytes.sublist(0, SchnorrkelKeyCost.secretKeyLength),
    );
    final public = SR25519PublicKey(
      bytes.sublist(
        SchnorrkelKeyCost.secretKeyLength,
        SchnorrkelKeyCost.keypairLength,
      ),
    );
    if (public != secret.publicKey) {
      throw CoreErrors.cryptoFailed(
        "SR25519Keypair.fromBytes",
        reason: "Mismatch keypair public key.",
      );
    }
    return SR25519Keypair._(secret, public);
  }

  factory SR25519Keypair.fromEd25519(List<int> bytes) {
    bytes.exc(
      length: SchnorrkelKeyCost.keypairLength,
      name: "bytes",
      operation: "SR25519Keypair.fromEd25519",
    );
    final secret = SR25519PrivateKey.fromEd25519(
      bytes.sublist(0, SchnorrkelKeyCost.secretKeyLength),
    );
    final public = SR25519PublicKey(
      bytes.sublist(
        SchnorrkelKeyCost.secretKeyLength,
        SchnorrkelKeyCost.keypairLength,
      ),
    );
    if (public != secret.publicKey) {
      throw CoreErrors.cryptoFailed(
        "SR25519Keypair.fromEd25519",
        reason: "Mismatch keypair public key.",
      );
    }
    return SR25519Keypair._(secret, public);
  }
}
