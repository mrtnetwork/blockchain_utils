import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/verify_signing.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/g1.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// BLS12-381 min-pubkey-size scheme constants (keys in G1, signatures in G2).
class Bls12KeyConst {
  static const int privKeyByteLen = 32;
  static const int compressedPubKeyLength = 48;
  static const int uncompressedPubKeyLength = 96;
}

class Bls12G1PublicKey extends IBlsVerificationKey
    with Equality
    implements IPublicKey<Bls12G1VerifiyingParams> {
  final BuBytes keyBytes;
  Bls12G1PublicKey._(this.keyBytes);

  // Live point, parsed on demand from [keyBytes].
  // NOTE: every access re-parses (full validation); compute-heavy
  // call sites will be converted to bytes-APIs next phase.
  // G1Projective get point => G1Projective.fromBytes(keyBytes);

  /// Decodes a compressed or uncompressed G1 public key.
  ///
  /// Encoding: big-endian, per draft-irtf-cfrg-bls-signature (IETF) /
  /// the ZCash G1 serialization format — big-endian x-coordinate with
  /// 3 reserved flag bits. This is also what the zkcrypto Rust
  /// `bls12_381` crate's `G1Affine::to_compressed()` produces, so no
  /// translation is needed here: unlike the private-key scalar, point
  /// encoding does not differ between ecosystems. BuBytes from Ethereum
  /// validator keys, noble-curves, blst, py_ecc, or this library are
  /// all interchangeable as-is.
  factory Bls12G1PublicKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != Bls12KeyConst.compressedPubKeyLength &&
        keyBytes.length != Bls12KeyConst.uncompressedPubKeyLength) {
      throw CoreErrors.invalidOperationArguments(
        "Bls12G1PublicKey",
        name: "keyBytes",
        reason: "Invalid public key bytes length.",
      );
    }
    final normalized = normalizePublicKey(keyBytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "Bls12G1PublicKey",
        name: "keyBytes",
        reason: "Invalid public key bytes.",
      );
    }
    return Bls12G1PublicKey._(normalized);
  }

  /// Validates 48/96-byte [keyBytes] through the backend signing API and
  /// returns its canonical 48-byte compressed base encoding, or null when
  /// invalid (bad prefix, range, curve membership, or identity). Single
  /// source of truth for key parsing.
  static BuBytes? normalizePublicKey(List<int> keyBytes) {
    return blockchainUtils.api.signing.bls.normalizeG1PublicKey(keyBytes);
  }

  @override
  CryptoKeyType get type => CryptoKeyType.bls12G1;

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
  ) {
    return switch (encoding) {
      CryptoKeyEncoding.base
          when keyBytes.length == Bls12KeyConst.compressedPubKeyLength =>
        true,
      CryptoKeyEncoding.uncompressed
          when keyBytes.length == Bls12KeyConst.uncompressedPubKeyLength =>
        true,
      _ => false,
    };
  }

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    if (mode == CryptoKeyEncoding.base) return keyBytes;
    return CryptoKeysUtils.ensureSupportPubKeyMode(
      mode: mode,
      type: type,
      onModeBytes:
          (mode) => switch (mode) {
            CryptoKeyEncoding.base => keyBytes.cloneBytes(),
            CryptoKeyEncoding.uncompressed => G1Projective.fromBytes(
              keyBytes,
            ).toBytes(mode: mode),
          },
    );
  }

  @override
  List<dynamic> get variables => [keyBytes];
}

class Bls12G1PrivateKey extends IBlsSigningKey<Bls12G1PublicKey>
    with Equality
    implements
        IPrivateKey<Bls12G1Signature, Bls12SigningParams, Bls12G1PublicKey> {
  final SecretBytes sk;
  @override
  final Bls12G1PublicKey publicKey;
  Bls12G1PrivateKey._(this.sk, this.publicKey);

  void _ensureAlive(String operation) {
    if (sk.isZeroed) {
      throw CoreErrors.badState(
        operation,
        reason: "Private key has been disposed.",
      );
    }
  }

  factory Bls12G1PrivateKey.fromSk(JubJubFq sk) {
    final skBytes = sk.toBytes(endian: Endian.big);
    try {
      final publicKey = blockchainUtils.api.g1.multBase(skBytes);
      final point = G1Projective.fromBytes(publicKey);
      return Bls12G1PrivateKey._(
        SecretBytes(skBytes),
        Bls12G1PublicKey.fromBytes(point.toBytes()),
      );
    } finally {
      skBytes.forceZero();
    }
  }

  /// Decodes a 32-byte private key scalar.
  ///
  /// Encoding: big-endian, per draft-irtf-cfrg-bls-signature (IETF) —
  /// scalars built via `OS2IP`/`I2OSP` (RFC 8017). This is the encoding
  /// used by Ethereum validator keys, noble-curves, blst, py_ecc, and
  /// effectively every BLS12-381 library that follows the IETF
  /// signature draft, so [keyBytes] here should be ordinary IETF SK
  /// bytes with no manual byte-reversal needed by the caller.
  ///
  /// Internally, [sk] is a [JubJubFq], whose `fromBytes`/`toBytes` are a
  /// direct port of the zkcrypto Rust `jubjub`/`bls12_381` crates and are
  /// **little-endian** by that ecosystem's own convention (`ff` crate's
  /// `PrimeField::to_repr`/`from_repr`). Reusing `JubJubFq` for the BLS
  /// scalar is intentional and mathematically correct — JubJub's base
  /// field *is* BLS12-381's scalar field `Fr`, that's the entire reason
  /// JubJub is "embedded" in BLS12-381 — but it means this factory must
  /// reverse the byte order before handing bytes to `JubJubFq.fromBytes`,
  /// to bridge the public IETF-facing API to the internal LE field type.
  factory Bls12G1PrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != Bls12KeyConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "Bls12G1PrivateKey",
        name: "keyBytes",
        reason: "Invalid secret key bytes length.",
      );
    }
    return Bls12G1PrivateKey.fromSk(
      JubJubFq.fromBytes(keyBytes, endian: Endian.big),
    );
  }

  factory Bls12G1PrivateKey.random() {
    final seed = QuickCrypto.generateRandom(length: 64);
    try {
      return Bls12G1PrivateKey.fromSk(JubJubFq.fromBytes64(seed));
    } finally {
      seed.forceZero();
    }
  }

  @override
  CryptoKeyType get type => CryptoKeyType.bls12G1;

  static bool isValidBytes(List<int> keyBytes) {
    if (keyBytes.length != Bls12KeyConst.privKeyByteLen) {
      return false;
    }
    try {
      Bls12G1PrivateKey.fromBytes(keyBytes);
      return true;
    } catch (_) {}
    return false;
  }

  @override
  List<dynamic> get variables => [publicKey];

  @override
  Bls12G1PublicKey verificationKey() => publicKey;

  @override
  JubJubFq scalar() {
    _ensureAlive("Bls12G1PrivateKey.scalar");
    final reversed = sk.reversed.toList();
    try {
      return JubJubFq.fromBytes(reversed);
    } finally {
      BinaryOps.zero(reversed);
    }
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    _ensureAlive("Bls12G1PrivateKey.toBytes");
    return sk.cloneBytes(transform: transform);
  }

  @override
  void dispose() {
    sk.zero();
  }

  @override
  SecretBytes takeSecretKey() {
    _ensureAlive("Bls12G1PrivateKey.takeSecretKey");
    return sk;
  }
}
